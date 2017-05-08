---
layout: post
title: Automated Puppet Testing
---
{% include JB/setup %}

# Introduction #

I've recently been working more on a Puppet project of mine: [toughen](https://github.com/shearn89/puppet-toughen). It's designed to be a flexible module for system hardening, as I've worked on a few different projects that need hardening via Puppet and haven't been happy with any of the modules so far.

I started writing my own last year, but it got a bit sidelined until recently. However, I'm trying to approach it in a sensible fashion, and have been looking at various automated tests.

# Testing #

Testing is done at 2 levels: unit tests, and higher-level system tests. The unit tests test the logic of the Puppet module, including things like whether resources are correctly avoided based on OS family etc. The system tests test that the entire module applies with no errors, and that the system is reasonably compliant after doing so.

# Unit Tests #

Unit testing is done using `rspec-puppet` along with the `puppetlabs_spec_helper`. 

More to come.

# System Tests #

System testing is done with [vagrant](https://www.vagrantup.com/intro/index.html). A base box is built (using [packer](https://www.packer.io/), uploaded to Atlas [here](https://atlas.hashicorp.com/shearn89/boxes/centos7)), then a vagrant box pulls that and runs some simple provisioners on top. [R10k](https://github.com/puppetlabs/r10k) is used to pull the `develop` branch of the repository, and apply it to the node.

TODO: not r10k, puppet provisioner?
