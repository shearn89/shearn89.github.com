---
categories:
- howto
date: "2017-05-09T00:00:00Z"
description: First part of a series on automated testing with Puppet, using
  RSpec.
tags: 
- puppet
- automation
- testing
featuredImage: "/images/puppets.jpg"
title: Automated Puppet Testing (Pt. I)
slug: automated-puppet-testing-pt1
---
How to get started with unit testing Puppet code, part 1 of 3.
<!--more-->
*Image by [Succo](https://pixabay.com/users/succo-96729) from
[Pixabay](https://pixabay.com)*

## Introduction

I've recently been working more on a Puppet project of mine:
[toughen](https://github.com/shearn89/puppet-toughen). It's designed to be a
flexible module for system hardening, as I've worked on a few different
projects that need hardening via Puppet and haven't been happy with any of the
modules so far.

I started writing my own last year, but it got a bit sidelined until recently.
However, I'm trying to approach it in a sensible fashion, and have been looking
at various automated tests.

Testing is done at 2 levels: unit tests, and higher-level system tests. The
unit tests test the logic of the Puppet module, including things like whether
resources are correctly avoided based on OS family etc. The system tests test
that the entire module applies with no errors, and that the system is
reasonably compliant after doing so.

This series of posts will cover the work I've been doing testing my modules:
this part covers getting set up and running your first tests. Part II will
cover logic-based tests with varying parameters or guards based on facts. Part
III will cover unit testing custom facts (fun!), and finally Part IV will cover
system testing in Vagrant. If I get to Part V it'll be on using CI, but that's
a ways off yet...

Unit testing is done primarily using `rspec-puppet`.

## First Failure

So, how have I done the unit testing? I find learning by example easiest, so
we'll start with that. *NB: the full code for this is available [on
GitHub](https://github.com/shearn89/puppet-helloworld)*.

Generate a simple 'helloworld' module:

<!-- spellchecker-disable -->
```bash
puppet module generate helloworld
```
<!-- spellchecker-enable -->

That gives us a nice template to start with:

<!-- spellchecker-disable -->
```bash
~/repos/helloworld$ tree
.
├── examples
│   └── init.pp
├── Gemfile
├── manifests
│   └── init.pp
├── metadata.json
├── Rakefile
├── README.md
└── spec
    ├── classes
        │   └── init_spec.rb
            └── spec_helper.rb

            4 directories, 8 files
```
<!-- spellchecker-enable -->

Now, set up the repo for testing:

<!-- spellchecker-disable -->
```bash
bundle install --path vendor/bundle
```
<!-- spellchecker-enable -->
We'll need to edit the Rakefile to exclude the newly-created vendor folder:
<!-- spellchecker-disable -->
```bash
$ vim Rakefile
...
PuppetLint.configuration.ignore_paths = ['spec/**/*.pp', 'pkg/**/*.pp']
```
<!-- spellchecker-enable -->
becomes...
<!-- spellchecker-disable -->
```bash
PuppetLint.configuration.ignore_paths = ['spec/**/*.pp', 'pkg/**/*.pp', 'vendor/**/*']
```
<!-- spellchecker-enable -->
Now, if you execute `bundle exec rake test`, you should see:

<!-- spellchecker-disable -->
```bash
~/repos/helloworld$ bundle exec rake test
Warning: Dependency puppetlabs-stdlib has an open ended dependency version requirement >= 1.0.0
---> syntax:manifests
---> syntax:templates
---> syntax:hiera:yaml
puppet parser validate --noop manifests/init.pp
ruby -c spec/spec_helper.rb
Syntax OK
ruby -c spec/classes/init_spec.rb
Syntax OK
/usr/bin/ruby2.3 -I/home/shearna/repos/helloworld/vendor/bundle/ruby/2.3.0/gems/rspec-core-3.6.0/lib:/home/shearna/repos/helloworld/vendor/bundle/ruby/2.3.0/gems/rspec-support-3.6.0/lib /home/shearna/repos/helloworld/vendor/bundle/ruby/2.3.0/gems/rspec-core-3.6.0/exe/rspec --pattern spec/\{aliases,classes,defines,unit,functions,hosts,integration,type_aliases,types\}/\*\*/\*_spec.rb --color
.

Finished in 0.12021 seconds (files took 0.66718 seconds to load)
1 example, 0 failures
```
<!-- spellchecker-enable -->

We've run our first test! Interesting but not very functional. In true
TDD-style we'll start by adding the tests and then making everything green.

## Adding Classes

We want our simple class to say 'hello' to the user. Open up
`spec/classes/spec_init.rb`:

<!-- spellchecker-disable -->
```ruby
require 'spec_helper'
describe 'helloworld' do
  context 'with default values for all parameters' do
    it { should contain_class('helloworld') }
  end
end
```
<!-- spellchecker-enable -->
This file is describing the 'helloworld' class. The spec file stats when the
default parameters are used, the compiled catalog should contain a class called
'helloworld'. Pretty simple! We also want to define a notify resource that says
hello to the user, so we'll add:

<!-- spellchecker-disable -->
```ruby
require 'spec_helper'
describe 'helloworld' do
  context 'with default values for all parameters' do
    it { should contain_class('helloworld') }
    it { should contain_notify('hello puppet users!') }
  end
end
```
<!-- spellchecker-enable -->
If you save and close the file, and run the `bundle exec rake test` command
again, you'll see the following:

<!-- spellchecker-disable -->
```bash
~/repos/helloworld$ bundle exec rake test
Warning: Dependency puppetlabs-stdlib has an open ended dependency version requirement >= 1.0.0
---> syntax:manifests
---> syntax:templates
---> syntax:hiera:yaml
puppet parser validate --noop manifests/init.pp
ruby -c spec/spec_helper.rb
Syntax OK
ruby -c spec/classes/init_spec.rb
Syntax OK
/usr/bin/ruby2.3 -I/home/shearna/repos/helloworld/vendor/bundle/ruby/2.3.0/gems/rspec-core-3.6.0/lib:/home/shearna/repos/helloworld/vendor/bundle/ruby/2.3.0/gems/rspec-support-3.6.0/lib /home/shearna/repos/helloworld/vendor/bundle/ruby/2.3.0/gems/rspec-core-3.6.0/exe/rspec --pattern spec/\{aliases,classes,defines,unit,functions,hosts,integration,type_aliases,types\}/\*\*/\*_spec.rb --color
.F

Failures:

  1) helloworld with default values for all parameters should contain Notify[hello puppet users!]
     Failure/Error: it { should contain_notify('hello puppet users!') }
       expected that the catalogue would contain Notify[hello puppet users!]
     # ./spec/classes/init_spec.rb:5:in `block (3 levels) in <top (required)>'

Finished in 0.12528 seconds (files took 0.6247 seconds to load)
2 examples, 1 failure

Failed examples:

rspec ./spec/classes/init_spec.rb:5 # helloworld with default values for all parameters should contain Notify[hello puppet users!]

/usr/bin/ruby2.3 -I/home/shearna/repos/helloworld/vendor/bundle/ruby/2.3.0/gems/rspec-core-3.6.0/lib:/home/shearna/repos/helloworld/vendor/bundle/ruby/2.3.0/gems/rspec-support-3.6.0/lib /home/shearna/repos/helloworld/vendor/bundle/ruby/2.3.0/gems/rspec-core-3.6.0/exe/rspec --pattern spec/\{aliases,classes,defines,unit,functions,hosts,integration,type_aliases,types\}/\*\*/\*_spec.rb --color failed
```
<!-- spellchecker-enable -->

Woah! Lets go through this...

## Working through errors

* We ran the command
* The `metadata.json` linter says we have an open-ended version requirement,
  which we should probably pin down. Depends on use case really. I'll ignore it
  for now.
* Some syntax checks are run and complete okay.
* `puppet parser validate` is run against our manifests and comes back okay.
* Ruby syntax is validated for other ruby files in the code base
* The actual tests are run, and 1 failed!
* Details of the failure
* Summary of the failures

So, reading through all that, we can see that in `spec/classes/init_spec.rb`,
at line 5, our test failed. Lets fix it!

Open up `manifests/init.pp` and add:

<!-- spellchecker-disable -->
```puppet
class helloworld {
  notifi { "hello puppet users!": }
}
```
<!-- spellchecker-enable -->
Then run the tests again. Slight difference:

<!-- spellchecker-disable -->
```bash
~/repos/helloworld$ bundle exec rake test
Warning: Dependency puppetlabs-stdlib has an open ended dependency version requirement >= 1.0.0
manifests/init.pp - WARNING: double quoted string containing no variables on line 46
```
<!-- spellchecker-enable -->
The puppet linter found a problem (we used double quotes in a string with no
variables) and stopped execution. We'll fix it and run again:

<!-- spellchecker-disable -->
```puppet
class helloworld {
  notifi { 'hello puppet users!': }
}
```
<!-- spellchecker-enable -->
We now get a lot more error output. Above one of the stack traces, we get:

<!-- spellchecker-disable -->
 ```bash
  1) helloworld with default values for all parameters should contain Class[helloworld]
     Failure/Error: it { should contain_class('helloworld') }
     
     Puppet::PreformattedError:
       Evaluation Error: Error while evaluating a Resource Statement, Unknown resource type: 'notifi' at /home/shearna/repos/helloworld/spec/fixtures/modules/helloworld/manifests/init.pp:46:3 on node boris-shearna
```
<!-- spellchecker-enable -->
This says that (essentially) there's a typo in our manifest: we put 'notifi'
when we should have put 'notify'. Fix it and run again:

<!-- spellchecker-disable -->
```bash
~/repos/helloworld$ bundle exec rake test
Warning: Dependency puppetlabs-stdlib has an open ended dependency version requirement >= 1.0.0
---> syntax:manifests
---> syntax:templates
---> syntax:hiera:yaml
puppet parser validate --noop manifests/init.pp
ruby -c spec/spec_helper.rb
Syntax OK
ruby -c spec/classes/init_spec.rb
Syntax OK
/usr/bin/ruby2.3 -I/home/shearna/repos/helloworld/vendor/bundle/ruby/2.3.0/gems/rspec-core-3.6.0/lib:/home/shearna/repos/helloworld/vendor/bundle/ruby/2.3.0/gems/rspec-support-3.6.0/lib /home/shearna/repos/helloworld/vendor/bundle/ruby/2.3.0/gems/rspec-core-3.6.0/exe/rspec --pattern spec/\{aliases,classes,defines,unit,functions,hosts,integration,type_aliases,types\}/\*\*/\*_spec.rb --color
..

Finished in 0.15678 seconds (files took 0.59812 seconds to load)
2 examples, 0 failures
```
<!-- spellchecker-enable -->
Much better! You can now see that we have tests passing.

## Summary

We created a simple manifest and some simple tests to go with it. In the next
part we'll cover some less trivial cases such as when different parameters are
passed in or resources are guarded by facts.

./A
