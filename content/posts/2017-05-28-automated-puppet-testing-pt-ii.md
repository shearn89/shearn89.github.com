---
categories:
- howto
date: "2017-05-28T00:00:00Z"
description: Second part of a series on automated testing with Puppet, using RSpec.
tags: 
- puppet 
- automation 
- testing
featuredImage: "/images/puppets.jpg"
title: Automated Puppet Testing (Pt. II)
---
How to get started with unit testing Puppet code, part 2 of 3.
<!--more-->

## Introduction

This post follows on from a [previous post](/2017/05/09/automated-puppet-testing-pt1). If you're new to testing your Puppet code, go there to get set up! We'll be using the same [repository](https://github.com/shearn89/puppet-helloworld) and building from there.

This part of the tutorial will focus on **Facts** and **Fixtures**. Briefly:

* *Facts* are information provided by the *Agent* during a puppet run. Generally they're information derived from the box itself, things such as IP addresses, fully qualified domain names, OS versions, etc. Sometimes you want to define some custom facts for your specific module, either to make logic easier in templates/code, or to provide information back to an External Node Classifier such as Foreman or RedHat Satellite.
* *Fixtures* are a testing tool: your module may have dependencies, but when running the RSpec tests not all of these will be available. We tell RSpec how to pull these dependencies so that the tests run correctly.

We'll tackle these in reverse order!

## Fixtures

I'll work with an example from my system hardening module ["toughen"](https://github.com/shearn89/puppet-toughen) and we'll flesh it out in the `helloworld` repo.

There's a section of the system hardening module where I want to add a specific line to a config file for Postfix. I don't want to have to manage the entire file, especially when Postfix may not even be installed! Instead, I just want to make sure that (unless overridden) Postfix is listening to local interfaces only by default. This means if the package gets pulled in as a dependency or is installed as part of a default build, there's not an extra port listening on the network that could expose an attack vector.

Specifically, I want to ensure that this line is present:
```
inet_interfaces = localhost
```
That's it! The Puppetlabs `stdlib` module provides an excellent tool for this. We could probably use augeas to do it (and the excellent providers from the [herculesteam](http://augeasproviders.com/) would be perfect for it), but we'll just use `stdlib`. There's a lot of other good tools in there: go read [the docs](https://forge.puppet.com/puppetlabs/stdlib)!

Lucky for us, the `stdlib` module is a dependency by default in the `metadata.json`, so no need to update that. You would if you were adding additional dependencies. So, similar to Part 1, we'll start by writing the tests.

### Test Case

Create a file call `spec/classes/postfix_spec.rb`:

```ruby
require 'spec_helper'
describe 'helloworld::postfix' do
  context 'with default values for all parameters' do
    it { should contain_file_line('postfix-local-only') }
  end
end
```
Save and quit, and run `bundle exec rake test`. You might want to alias that: `alias bert='bundle exec rake test'`. As expected, failure:

```
Finished in 0.16792 seconds (files took 0.67494 seconds to load)
3 examples, 1 failure

Failed examples:

rspec ./spec/classes/postfix_spec.rb:4 # helloworld::postfix with default values for all parameters should contain File_line[postfix-local-only]
```
So, now we go write some code to back it up. 

### Class Under Test

Create a file `manifests/postfix.pp`:

```puppet
# Class: Helloworld::Postfix
# 
class helloworld::postfix {
  file_line { 'postfix-local-only':
    path  => '/etc/postfix/main.cf',
    line  => 'inet_interfaces = localhost',
    match => '^inet_interface',
  }
}
```

This is pretty bare. Basically all it's saying is that in the file `/etc/postfix/main.cf`, the line specified needs to be present. We can help puppet identify that line by specifying a regex: that's the `match` parameter. It's best to keep those simple if you're using them.

Now, run the tests again:

```
Finished in 0.16711 seconds (files took 0.62496 seconds to load)
3 examples, 1 failure

Failed examples:

rspec ./spec/classes/postfix_spec.rb:4 # helloworld::postfix with default values for all parameters should contain File_line[postfix-local-only]
```

Huh, failed again...

### Adding the Fixture

Scrolling further up:

```
Failures:

  1) helloworld::postfix with default values for all parameters should contain File_line[postfix-local-only]
     Failure/Error: it { should contain_file_line('postfix-local-only') }
     
     Puppet::PreformattedError:
       Evaluation Error: Error while evaluating a Resource Statement, Unknown resource type: 'file_line' at /home/shearna/repos/helloworld/spec/fixtures/modules/helloworld/manifests/postfix.pp:4:3 on node boris-shearna.home
```

Okay, that makes more sense. What it's saying is that the test hasn't passed becase the resource type `file_line` isn't available. That's because we need to tell RSpec there's a dependency! First, create a file in the root of your repository called `.fixtures.yml`. Mine looks like this:

```yaml
fixtures:
  repositories:
    stdlib: "git://github.com/puppetlabs/puppetlabs-stdlib.git"
```

You can also specify a particular version of the repo if you like:

```yaml
fixtures:
  repositories:
    stdlib:
      repo: "git://github.com/puppetlabs/puppetlabs-stdlib.git"
      ref: "4.17.0"
```
Useful if you're worried about compatibility (even more so now Puppet 3 is officially deprecated/end-of-lifed/etc).

Okay, with that done, let's try our tests again:

```
shearna@boris-shearna:~/repos/helloworld$ bert
Warning: Dependency puppetlabs-stdlib has an open ended dependency version requirement >= 1.0.0
---> syntax:manifests
---> syntax:templates
---> syntax:hiera:yaml
puppet parser validate --noop manifests/postfix.pp
puppet parser validate --noop manifests/init.pp
ruby -c spec/spec_helper.rb
Syntax OK
ruby -c spec/classes/init_spec.rb
Syntax OK
ruby -c spec/classes/postfix_spec.rb
Syntax OK
Cloning into 'spec/fixtures/modules/stdlib'...
remote: Counting objects: 563, done.
remote: Compressing objects: 100% (501/501), done.
remote: Total 563 (delta 160), reused 207 (delta 44), pack-reused 0
Receiving objects: 100% (563/563), 277.30 KiB | 0 bytes/s, done.
Resolving deltas: 100% (160/160), done.
Checking connectivity... done.
/usr/bin/ruby2.3 -I/home/shearna/repos/helloworld/vendor/bundle/ruby/2.3.0/gems/rspec-core-3.6.0/lib:/home/shearna/repos/helloworld/vendor/bundle/ruby/2.3.0/gems/rspec-support-3.6.0/lib /home/shearna/repos/helloworld/vendor/bundle/ruby/2.3.0/gems/rspec-core-3.6.0/exe/rspec --pattern spec/\{aliases,classes,defines,unit,functions,hosts,integration,type_aliases,types\}/\*\*/\*_spec.rb --color
...

Finished in 0.1726 seconds (files took 0.64383 seconds to load)
3 examples, 0 failures
```

Excellent! We have working fixtures! You can use this to add any other dependencies to your project, so if you're going the whole way and writing tests for your [roles and profiles](http://garylarizza.com/blog/2014/02/17/puppet-workflow-part-2/), then this would be especially useful.

Let's move on to facts...

## Facts

Now what if we wanted to only add that file line if the file was present? If for some reason the `postfix` package was not installed on the system, this module would fail at runtime, as the file `/etc/postfix/main.cf` wouldn't be present. One way I've approached this in my module is to add some simple facts to indicate whether the package is installed. This lets me guard the resource declaration with a simple `if` statement. 

### Writing a Custom Fact

As before, we'll write our tests first. Create a file called `spec/unit/facter/postfix_installed_spec.rb` - you may need to create some folders here! The file:

```ruby
describe 'postfix_installed', :type => :fact do
  before { Facter.clear }
  after { Facter.clear }

  context "on linux" do
    let (:facts) { {:kernel => 'Linux' } }
    it "should return true if installed" do
      Facter::Util::Resolution.stubs(:which).with('sendmail').returns('/sbin/sendmail')
      expect(Facter.fact(:postfix_installed).value).to eq(true)
    end

    it "should return false if not installed" do
      Facter::Util::Resolution.stubs(:which).with('sendmail').returns(nil)
      expect(Facter.fact(:postfix_installed).value).to eq(false)
    end
  end

end
```
Okay, lets go through this first:

* We're describing the `postfix_installed` object, and it's a `fact`.
* We clear the current set of facts on each test run.
* We specify our default context (in this case, only Linux machines)
* We specify some facts for testing purposes, in case we're developing on another kernel.
* Then we actually test our fact. As you'll see in the next bit, we use the `Facter::Util::Resolution` methods to make it easy to mock our fact, which is what we're doing here. We mock a call to `which` with the argument `sendmail`, and we tell the call what to return. Here we're checking that the `sendmail` command (provided by the `postfix` package) is present, which is nice and simple.
* We then check the fact is set correctly.
* Lastly, we do a similar test for the other logical branch where the package is not installed.

We'll run the tests and see what the failure is:

```
Failures:

  1) postfix_installed on linux should return true if installed
     Failure/Error: expect(Facter.fact(:postfix_installed).value).to eq(true)
     
     NoMethodError:
       undefined method `value' for nil:NilClass
     # ./spec/unit/facter/postfix_installed_spec.rb:9:in `block (3 levels) in <top (required)>'

  2) postfix_installed on linux should return false if not installed
     Failure/Error: expect(Facter.fact(:postfix_installed).value).to eq(false)
     
     NoMethodError:
       undefined method `value' for nil:NilClass
     # ./spec/unit/facter/postfix_installed_spec.rb:14:in `block (3 levels) in <top (required)>'

Finished in 0.51381 seconds (files took 0.64751 seconds to load)
5 examples, 2 failures

Failed examples:

rspec ./spec/unit/facter/postfix_installed_spec.rb:7 # postfix_installed on linux should return true if installed
rspec ./spec/unit/facter/postfix_installed_spec.rb:12 # postfix_installed on linux should return false if not installed
```

Okay, no surprises there, we've not written any code. Add the following to `lib/facter/postfix_installed.rb` (again, you may need to create the folder):

```ruby
# Returns true if postfix is installed
Facter.add(:postfix_installed) do
  confine :kernel => 'Linux'

  setcode do
    output = Facter::Util::Resolution.which('sendmail')
    output ? true : false
  end
end
```

Nice and simple! We define a fact called `postfix_installed`, and specify that it's only valid on the Linux kernel. Then we use the `Facter::Util::Resolution` class to provide an easily-testable variable called `output`. If `output` has any value at all, the fact is `true`, otherwise `false`. This works because the `which` command returns nothing except an error code if the command isn't found.

If we run the test again, we'll see:

```
/usr/bin/ruby2.3 -I/home/shearna/repos/helloworld/vendor/bundle/ruby/2.3.0/gems/rspec-core-3.6.0/lib:/home/shearna/repos/helloworld/vendor/bundle/ruby/2.3.0/gems/rspec-support-3.6.0/lib /home/shearna/repos/helloworld/vendor/bundle/ruby/2.3.0/gems/rspec-core-3.6.0/exe/rspec --pattern spec/\{aliases,classes,defines,unit,functions,hosts,integration,type_aliases,types\}/\*\*/\*_spec.rb --color
.....

Finished in 0.20792 seconds (files took 0.63526 seconds to load)
5 examples, 0 failures
```

Et voila! Working custom fact. We can now use this in our class.

### Using the Fact and Updating Tests

Modify the `helloworld::postfix` class to look like this:

```puppet
# Class: Helloworld::Postfix
# 
class helloworld::postfix {
  if $::postfix_installed {
    file_line { 'postfix-local-only':
      path  => '/etc/postfix/main.cf',
      line  => 'inet_interfaces = localhost',
      match => '^inet_interface',
    }
  }
}
```

Note the `if` statement wrapping the declaration. If we run the tests now, it may well fail as the value of the fact while under test probably isn't defined:

```
Finished in 0.18349 seconds (files took 0.6455 seconds to load)
5 examples, 1 failure

Failed examples:

rspec ./spec/classes/postfix_spec.rb:4 # helloworld::postfix with default values for all parameters should contain File_line[postfix-local-only]
```

In order to test the class, we'll need to add some logic around the tests. We'll update the test class `postfix_spec.rb`, removing the simple test that was there previously and adding 2 to replace it:

```ruby
require 'spec_helper'
describe 'helloworld::postfix' do

  context 'with postfix installed' do
    let (:facts) do { :postfix_installed => true } end
    it { should { contain_file_line('postfix-local-only') } }
  end

  context 'without postfix installed' do
    let (:facts) do { :postfix_installed => false } end
    it { should_not { contain_file_line('postfix-local-only') } }
  end
end
```

We've added some additional tests to confirm that it compiles with no changes, and 2 tests to check each value of the fact. If we run the tests now:

```
/usr/bin/ruby2.3 -I/home/shearna/repos/helloworld/vendor/bundle/ruby/2.3.0/gems/rspec-core-3.6.0/lib:/home/shearna/repos/helloworld/vendor/bundle/ruby/2.3.0/gems/rspec-support-3.6.0/lib /home/shearna/repos/helloworld/vendor/bundle/ruby/2.3.0/gems/rspec-core-3.6.0/exe/rspec --pattern spec/\{aliases,classes,defines,unit,functions,hosts,integration,type_aliases,types\}/\*\*/\*_spec.rb --color
......

Finished in 0.15009 seconds (files took 0.64442 seconds to load)
6 examples, 0 failures
```

Cool - all working!

## Summary

So, we've now got a module that has basic tests wrapping up the logic of the classes, as well as a custom fact that gets tested, and some dependencies that get pulled in. The ideas here can be taken much further. Something to bear in mind is what you're trying to test with these unit tests: you should be testing the logic of your class, making sure that the resources and parameters you've defined and guarded with certain bits of logic are correctly applied. There's no need to test that every single resource is present, as that's just testing that Puppet itself works as intended: something you should be able to assume works fine! Ideally, anywhere you have a variable that affects a resource or even a template, you should have a test for each branch of the logic tree.

If you plan to support multiple operating systems, then you'd want to expand your test contexts to cover the various OS's that you support. In this way you can ensure that changes don't break the module, a bit more easily than spinning up a whole load of vagrant boxes. We'll cover that (system testing on VMs) in Part III!

./A
