---
layout: post
title: Automated Puppet Testing (Pt. III)
description: "Final part of a series on automated testing with Puppet, using RSpec."
category: technical
tags: puppet automation testing packer vagrant
---
{% include JB/setup %}

* TOC
{:toc}

# Introduction #

This is the final part of my blog posts on Puppet automated testing - at least for now! I'll be covering some higher-level system tests using Vagrant. These could be automated as part of a CI pipeline, but they're much slower to run than the unit tests - 6 minutes on my Dell XPS without downloading the box files - for that reason, they probably want to run on an interval rather than after every commit.

This is quite a long post! If you're familiar with Packer/Vagrant then feel free to jump around - I've tried to pitch this as a guide someone could follow with no previous experience in the tools, so some sections might be a little laboured...

# Getting Started #

We're going to need 3 things to do these tests: a working `box` for Vagrant (bit like a template), a `Vagrantfile` that tells Vagrant what to do, and of course our modules. Lets go through these in turn. I'll also be adding to the [Example Module](https://github.com/shearn89/puppet-helloworld) that we've been working with in this series: mostly working under a `ci` folder.

As a prerequisite, you'll need [VirtualBox](https://www.virtualbox.org/) installed. There's normally packages for it in all major distros, so I'll not cover it here.

# Packing Boxes #

A `box` is a vagrant term for prebuilt images that you can download and run via Vagrant. You can browse the public repo [online](https://atlas.hashicorp.com/boxes/search) where other people have made boxes available. You'll want to find one with Puppet installed (preferable), or at the least one that matches the distribution you intend to test on. If puppet isn't installed, we can install it as part of the provisioning process. You can also build your own box - lets run through that briefly, as the process is pretty simple!

Take a look at the [CI repo](https://github.com/shearn89/toughen-ci/) for my `toughen` module. Not everything in there is relevant - it's kind of a brain dump of various bits and bobs I was testing out! We'll focus on the `packer` and `vagrant` folders.

Essentially, Packer takes a JSON file, parses it, and then runs a series of commands to build and package a Box, ready for distribution either online or locally. It's a good way to get over some initial setup tasks that would otherwise have to always be run by vagrant. If you're going to be setting up this Vagrant environment and sharing it with other users (so everyone can run the same tests on the same configuration), and the boxes available online don't work, I would strongly recommend using Packer to create your own project box. I published my version of the Centos 7 box (available [here](https://atlas.hashicorp.com/shearn89/boxes/centos7)) so that I have one with a CIS-compliant partition layout that I can use on projects. If you're not interested in this bit and want to skip to the actual Vagrant stuff, then go for it.

## Packer ##

First, install [Packer](https://www.packer.io/). When you're done, come back here.

Their documentation is also excellent, so anything that's not covered here should be covered there! You'll want to create 2 things to start with: a folder to serve Kickstart/Preseed files from, and a JSON file with the configuration:

    $> cd puppet-helloworld
    $> mkdir -p ci/packer/http
    $> cd ci/packer
    $> touch centos-7.json

Nice and simple so far. Also make sure Packer is correctly installed:

    $> packer --help
    $> Usage: packer [--version] [--help] <command> [<args>]

    Available commands are:
        ...

## Building ##

Okay! Lets start doing something with it. Firstly, you're going to need a [builder](https://www.packer.io/docs/builders/virtualbox.html) - we'll be using the VirtualBox one to create Vagrant images, but Packer itself can build images for a long list of other providers (OpenStack, Docker, Amazon EC2, Google Cloud, Azure...). Specifically, we're using the `virtualbox-iso` builder, which takes an ISO image and turns it into a provisionable image. There's a minimum set of parameters to this, but that wouldn't actually work. In order to build something that will actually... er, build... we have to put in at a minimum:

{% raw %}
    {
      "builders": [{
        "name": "centos73",
        "type": "virtualbox-iso",
        "guest_os_type": "RedHat_64",
        "headless": true,
        "iso_url": "http://mirrors.ukfast.co.uk/sites/ftp.centos.org/7/isos/x86_64/CentOS-7-x86_64-Minimal-1611.iso",
        "iso_checksum": "d2ec6cfa7cf6d89e484aa2d9f830517c",
        "iso_checksum_type": "md5",
        "ssh_username": "vagrant",
        "ssh_password": "vagrant",
        "shutdown_command": "sudo -S shutdown -P now",
        "boot_command": "<up><tab> ks=http://{{ .HTTPIP }}:{{ .HTTPPort }}/kickstart.cfg<enter>",
        "disk_size": "100000",
        "guest_additions_mode": "attach",
        "guest_additions_url": "",
        "http_directory": "http",
        "output_directory": "builds",
        "vboxmanage": [
          ["modifyvm", "{{.Name}}", "--memory", "1024"],
          ["modifyvm", "{{.Name}}", "--cpus", "1"]
        ]
      }]
    }
{% endraw %}

So, what have we got here?

  * We start with a top level JSON hash.
  * We define a list of `builders`.
  * We give a name to our builder.
  * We specify the type of builder as listed in the documentation.
  * We tell VirtualBox what type of OS it is so it can do it's performance tweaking.
  * We specify that we don't want the GUI to run be connected during provisioning. When getting started, setting this to `false` can be very useful!
  * Then we specify a URL to retrieve the ISO from. This is a proper URI so can be web/file/almost anything I think. If you've got a stack of ISOs on a home server, point it at that.
  * We then have the checksum and checksum type - these are required! Without these Packer has no way to verify that it downloaded the ISO correctly.
  * We tell Packer what SSH username and password it will use to do any further provisioning with. If you're building Vagrant images, these **must** be `vagrant`.
  * We let Packer know how to shutdown the machine once built, so it can compress and package it.
  * Then we specify the `boot_command`, or the sequence of keys that should be used to make the VM load our Kickstart/Preseed file. It's literally a sequence of keystrokes with some special keys in angled brackets (e.g. `<up>`), and some variables.
  * We tell VirtualBox what disk size it should be (thin) provisioned with. Hashicorp recommend setting this larger than needed, as it's thin provisioned and chances are you might be destroying and recreating this machine often enough that you won't fill the disk.
  * We then tell VirtualBox how to load the Guest Additions ISO - this ISO gives us some nice features on the VM, although the one we need most is Shared Folders. More info on the [VirtualBox](https://www.virtualbox.org/manual/ch04.html) website.
  * We then specify where Packer should start it's embedded web server in order to serve the Kickstart/Preseed files from (and anything else we want to load via HTTP).
  * We tell it where to put the built image.
  * Lastly, we tell VirtualBox what to set initial RAM and CPU to.

Phew! Okay, so we've written our iniital config. Lets have a stab at running it and see what happens. Before we do, change that `headless` setting to `false`, so we can see what's up:

    $> sed -i '/headless/ s/true/false/' centos-7.json 
    $> packer validate centos-7.json 
    Template validated successfully.
    $> packer build centos-7.json
    ...

You'll see a reasonable amount of output now. To start with, it will download the image file. It will then start it's HTTP server, and attempt to run the boot command. With that done, Packer then just sits there waiting for SSH to become available, which triggers the next part of the build process.

On the first run with the config listed above, it took 7 minutes and timed out, saying:

    ==> Some builds didn't complete successfully and had errors:
    --> centos73: Timeout waiting for SSH.

    ==> Builds finished but no artifacts were created.

## Kickstart/Preseed ##

Hmmm, not ideal. Lets take another look. You'll notice the second time it doesn't have to download the ISO, so is a good bit quicker! Watch the GUI, and see what the error is. In my case, it was the following:

![Screenshot of Failed Download](/assets/images/failed-download.png)

Of course - we've not created our kickstart file yet! Lets do that now. Since I'm building a CentOS box, I'll create `kickstart.cfg`: if you're using a Debian-family distro, create the relevant preseed file.

You can see a copy of the Kickstart file I've used in the [toughen-ci repo](https://github.com/shearn89/toughen-ci/blob/master/packer/http/kickstart.cfg) - it's the same as in the example repo and will probably be kept up to date. There's a few things in here that aren't required - I strip out a whole load of wireless firmware that's not needed, and install the packages used for setting up the VirtualBox Guest Additions. The file could be smaller! It's important to note that I'm actually installing from a web source rather than a CD - this means packages should be more up to date than relying on the ISO media.

Okay, with that file created under `ci/packer/http`, lets see what happens now:

    $> packer build centos-7.json 
    centos73 output will be in this color.
    
    ==> centos73: Downloading or copying Guest additions
        centos73: Downloading or copying: file:///usr/share/virtualbox/VBoxGuestAdditions.iso
    ==> centos73: Downloading or copying ISO
        centos73: Downloading or copying: http://mirrors.ukfast.co.uk/sites/ftp.centos.org/7/isos/x86_64/CentOS-7-x86_64-Minimal-1611.iso
    ==> centos73: Starting HTTP server on port 8550
    ==> centos73: Creating virtual machine...
    ==> centos73: Creating hard drive...
    ==> centos73: Creating forwarded port mapping for communicator (SSH, WinRM, etc) (host port 4349)
    ==> centos73: Executing custom VBoxManage commands...
        centos73: Executing: modifyvm packer-centos73-1497181208 --memory 1024
        centos73: Executing: modifyvm packer-centos73-1497181208 --cpus 1
    ==> centos73: Starting the virtual machine...
    ==> centos73: Waiting 10s for boot...
    ==> centos73: Typing the boot command...
    ==> centos73: Waiting for SSH to become available...
    ==> centos73: Connected to SSH!
    ==> centos73: Uploading VirtualBox version info (5.1.22)
    ==> centos73: Gracefully halting virtual machine...
        centos73: Removing guest additions drive...
    ==> centos73: Preparing to export machine...
        centos73: Deleting forwarded port mapping for the communicator (SSH, WinRM, etc) (host port 4349)
    ==> centos73: Exporting virtual machine...
        centos73: Executing: export packer-centos73-1497181208 --output builds/packer-centos73-1497181208.ovf
    ==> centos73: Unregistering and deleting virtual machine...
    Build 'centos73' finished.
    
    ==> Builds finished. The artifacts of successful builds are:
    --> centos73: VM files in directory: builds

Awesome! You can see that it's managed to connect to SSH, where in our example it's then done absolutely nothing. That's because we haven't defined any [provisioners]() or [post-processors](). These are the bits that make Packer very useful. We'll take a look in the next section.

**N.B.:** if you still can't download the Kickstart file, check that FirewallD isn't blocking that port/interface. You might need to temporarily turn it off (easiest), move the interface to the `trusted` zone (reasonably simple), or allow connections on TCP 8000-9000 (also quite simple).

## Provisioners ##

Now we know the process is working, we'll start using the built-in provisioners that Packer provides to customise our box. We're simply going to use the `shell` provisioner to run a couple of scripts - the first sets up the box so that Vagrant works properly, the second installs Puppet.

    $> cd ci/packer/
    $> mkdir scripts
    $> cd scripts
    $> curl -O https://raw.githubusercontent.com/shearn89/toughen-ci/master/packer/scripts/00-setup-basebox.sh
    $> curl -O https://raw.githubusercontent.com/shearn89/toughen-ci/master/packer/scripts/01-install-puppet.sh

As you can see, I'm just pulling a couple of scripts from the `toughen-ci` repo. The contents of those:

    #!/bin/bash
    
    curl -L -O https://raw.githubusercontent.com/mitchellh/vagrant/master/keys/vagrant.pub
    mkdir -m 0700 .ssh
    mv vagrant.pub .ssh
    cat .ssh/*.pub > .ssh/authorized_keys
    chmod 600 .ssh/*
    
    sudo sed -i '/UseDNS/ s/yes/no/' /etc/ssh/sshd_config
    sudo sed -i 's/#UseDNS/UseDNS/' /etc/ssh/sshd_config
    
    sudo mkdir -p /media/cdrom
    sudo mount /dev/sr1 /media/cdrom
    sudo sh /media/cdrom/VBoxLinuxAdditions.run
    sudo umount /media/cdrom

This is `00-setup-basebox.sh`. It grabs the insecure vagrant key from the vagrant repo, and installs it. This allows Vagrant to SSH in at first boot. It then disables DNS in the SSH config, so that SSH is faster to connect. Finally, it installs the VirtualBox Guest Additions which allows Vagrant to use shared folders. Pretty simple!

The other script could be inline it's so short:

    #!/bin/bash -e
    
    sudo rpm -ivh https://yum.puppetlabs.com/puppetlabs-release-el-7.noarch.rpm
    sudo yum install -y puppet

So, nice and simple. Lets add those scripts into our JSON file. After the `builders` block, append a comma and insert the following before the final closing brace. With a bit of context:

    {
      "builders": [{
          ...
      }],
      "provisioners": [
        {
          "type": "shell",
          "scripts": [
            "scripts/00-setup-basebox.sh",
            "scripts/01-install-puppet.sh"
          ]
        }
      ]
    }

What this does is start the `provisioners` block and tell Packer that there is a list of shell scripts to run. You don't need to worry about uploading these to the box or anything, Packer handles all that! If we validate the config (important, given we've added new JSON stuff and it's easy to miss commas etc) and run the build, we should now see slightly different output:

    ==> centos73: Downloading or copying Guest additions
        centos73: Downloading or copying: file:///usr/share/virtualbox/VBoxGuestAdditions.iso
    ==> centos73: Downloading or copying ISO
        centos73: Downloading or copying: http://mirrors.ukfast.co.uk/sites/ftp.centos.org/7/isos/x86_64/CentOS-7-x86_64-Minimal-1611.iso
    Build 'centos73' errored: Output directory exists: builds
    
    Use the force flag to delete it prior to building.

Woops - I need to delete the `builds` directory or use the `-force` flag. Lets try again:

    $> packer build -force centos-7.json

This time, you'll see a LOT of output, as Packer builds the box and then runs the scripts we've configured. It should at the end say something like:

    ==> centos73: Gracefully halting virtual machine...
        centos73: Removing guest additions drive...
    ==> centos73: Preparing to export machine...
        centos73: Deleting forwarded port mapping for the communicator (SSH, WinRM, etc) (host port 2374)
    ==> centos73: Exporting virtual machine...
        centos73: Executing: export packer-centos73-1497188242 --output builds/packer-centos73-1497188242.ovf
    ==> centos73: Unregistering and deleting virtual machine...
    Build 'centos73' finished.
    
    ==> Builds finished. The artifacts of successful builds are:
    --> centos73: VM files in directory: builds

Excellent! We're nearly done with Packer - onto post-processors and packaging the box for distribution.

## Post-processors ##

Similarly to when we added the provisioner, we'll add another section to the JSON. With context, as before:

{% raw %}
    {
      "builders": [{
        ...
      }],
      "provisioners": [
        ...
      ],
      "post-processors": [
        [{
          "type": "vagrant",
          "output": "helloworld_{{.BuildName}}_{{.Provider}}.box"
        }]
      ]
    }
{% endraw %}

There's a double array here, and that's so that you can add additional post-processors (e.g. when publishing to Atlas). Otherwise, it's a very simple section that just lists the type of post-processor (in this case [Vagrant](https://www.packer.io/docs/post-processors/vagrant.html)), and the name of the box that it'll create.

Let's run the build again:

    $> packer build -force centos-7.json
        ... much output ...
    ==> centos73: Running post-processor: vagrant
    ==> centos73 (vagrant): Creating Vagrant box for 'virtualbox' provider
        centos73 (vagrant): Copying from artifact: builds/packer-centos73-1497192332-disk001.vmdk
        centos73 (vagrant): Copying from artifact: builds/packer-centos73-1497192332.ovf
        centos73 (vagrant): Renaming the OVF to box.ovf...
        centos73 (vagrant): Compressing: Vagrantfile
        centos73 (vagrant): Compressing: box.ovf
        centos73 (vagrant): Compressing: metadata.json
        centos73 (vagrant): Compressing: packer-centos73-1497192332-disk001.vmdk
    Build 'centos73' finished.
    
    ==> Builds finished. The artifacts of successful builds are:
    --> centos73: 'virtualbox' provider box: helloworld_centos73_virtualbox.box

Perfect - our post-processor has run, and we've created a Vagrant Box! We'll use it in the next section.

# Vagrancy #

So, we've created a box file to use in our Vagrantfile. Lets get started with Vagrant itself - I'll assume you've installed Vagrant as per [the instructions](https://www.vagrantup.com/intro/getting-started/install.html). With that done, create a new folder under our `ci` one and create the initial Vagrantfile:

    $> cd ci/
    $> mkdir vagrant
    $> cd vagrant/
    $> vagrant init
    A `Vagrantfile` has been placed in this directory. You are now
    ready to `vagrant up` your first virtual environment! Please read
    the comments in the Vagrantfile as well as documentation on
    `vagrantup.com` for more information on using Vagrant.


