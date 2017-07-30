# facter\_cacheable

| [![Build Status](https://travis-ci.org/waveclaw/puppet-facter_cacheable.svg?branch=master)](https://travis-ci.org/waveclaw/puppet-facter_cacheable) | [![Code Climate](https://codeclimate.com/github/waveclaw/puppet-facter_cacheable/badges/gpa.svg)](https://codeclimate.com/github/waveclaw/puppet-facter_cacheable) | [![Test Coverage](https://codeclimate.com/github/waveclaw/puppet-facter_cacheable/badges/coverage.svg)](https://codeclimate.com/github/waveclaw/puppet-facter_cacheable/coverage) |

#### Table of Contents

1. [Overview](#overview)
2. [Module Description - What the module does and why it is useful](#module-description)
3. [Setup - The basics of getting started with facter\_cacheable](#setup)
    * [What facter\_cacheable affects](#what-facter\_cacheable-affects)
    * [Setup requirements](#setup-requirements)
    * [Beginning with facter\_cacheable](#beginning-with-facter\_cacheable)
4. [Usage - Configuration options and additional functionality](#usage)
5. [Reference - An under-the-hood peek at what the module is doing and how](#reference)
5. [Limitations - OS compatibility, etc.](#limitations)
6. [Development - Guide for contributing to the module](#development)

## Overview

facter\_cacheable implements a Puppet feature for Facter that caches fact values for a given time.

The features are inspired by the [Puppet Blog on Facter](https://puppet.com/blog/facter-part-3-caching-and-ttl) from 2010.

> This does not always work correctly with Puppet Enterprise 2016.
> PE purges pugin-synced facts directories on each run.
> This removes fact files Puppet's agent thinks came from custom facts.

## Module Description

As mentioned in many getting started with Puppet guides, including some by
Puppet Labs, caching a fact can be useful.
A well-maintained cache can:
 * reduce frequency of expensive calls
 * store values reachable outside of Puppet agent runs
 * explicitly control schedule of fact refreshing


There is limited planned support in Facter 2.0 and later for controlling some
caching of Puppet facts.  Personally this developer has never seen issues with it in the wild.

No, this is not yet-another-varnish module either.

## Setup

### What facter\_cacheable affects

Deploys a feature, facter\_cacheable, which is usable for custom facts written
by Puppet developers.

### Setup Requirements

PluginSync must be enabled on at least one Puppet agent run to deploy the module.

### Beginning with facter\_cacheable

## Usage

This module accepts no customization.  The `facter\_cache()` call takes options for:
 * the value to cache
 * a time-to-live(ttl) 
 * an optional location to store the cache in.

If the directories containing the cache files do not exist, the module will attempt to
create them. 

To cache a value use `cache`:
```
require 'facter/util/facter_cacheable'
Facter::Util::Facter_cacheable.cache(
  :fact_name_symbol,
  some_value,
  optional_cache_file
  )
```

To return a cached value use `cached?`:
```
require 'facter/util/facter_cacheable'
Facter::Util::Facter_cacheable.cached?(
  :fact_name_symbol,
  ttl_in_seconds,
  optional_cache_file)
```

*Complete Example*

```
#
# my_module/lib/facter/my_custom_fact.rb
#
require 'facter'
require 'puppet/util/facter_cachable'

Facter.add(:my_custom_fact) do
  confine do
    Puppet.features.facter_cacheable?
  end
  setcode do
    # 24 * 3600 = 1 day of seconds
    cache = Facter::Util::Facter_cacheable.cached?(:my_custom_fact, 24 * 3600)
    if ! cache
      my_value = some_expensive_operation()
      # store the value for later
      Facter::Util::Facter_cacheable.cache(:my_custom_fact, my_value)
      # return the expensive value
      my_value
    else
      # return the cached value (this may need processing)
      cache
    end
  end
end
```

It is not required but encouraged to keep the name of the cache and fact
the same. Although with all Ruby programming sanity is optional as it 
having documentation.

YAML stored values may appear as arrays or string-indexed hashes depending on
the version of Puppet and Facter involved.  Unpacking those is left as an
exercise for the reader.

### Testing Code

To test code that uses Facter\_cacheable you will have to resort to a little
used [method for stubbing objects](https://github.com/rspec/rspec-mocks).

In your Facter fact guard against import of the module.  Import will fail if you
do not have it deployed to the Puppet environment on which the tests are running.

Note: even the rSpec setup will not properly install this utility for testing.

```ruby
begin
    require 'facter/util/facter_cacheable'
  rescue LoadError => e
    Facter.debug("#{e.backtrace[0]}: #{$!}.")
end
# regular fact like the complete example above
```

In the rSpec Facter tests, normally some kind of function test on
`Facter.value()`, setup a harness which can check for invocation of the cache
functions.

```ruby
context 'test caching' do
  let(:fake_class) { Class.new }
  before :each do
    allow(File).to receive(:exist?).and_call_original
    allow(Puppet.features).to receive(:facter_cacheable?) { true }
    Facter.clear
  end
  it 'should return and save a computed value with an empty cache' do
    stub_const("Facter::Util::Facter_cacheable", fake_class)
    expect(Facter::Util::Facter_cacheable).to receive(:cached?).with(
    :my_fact, 24 * 3600) { nil }
    expect(Facter::Util::Resolution).to receive(:exec).with(
    'some special comand') { mydata }
    expect(Facter::Util::Facter_cacheable).to receive(:cache).with(
      :my_fact, mydata)
    expect(Facter.value(:my_fact).to eq(mydata)
  end
  it 'should return a cached value with a full cache' do
    stub_const("Facter::Util::Facter_cacheable", fake_class)
    expect(Facter::Util::Facter_cacheable).to receive(:cached?).with(
    :my_fact, 24 * 3600) { mydata }
    expect(mod).to_not receive(:my_fact)
    expect(Facter.value(:my_fact)).to eq(mydata)
  end
end
```

The key parts are the `:fake_class` and the `stub_const()` calls.  These setup
a kind of double that can be used by rSpec to hook into the Facter context.

## Reference

 * [Facter Part 3: Caching and TTL](https://puppet.com/blog/facter-part-3-caching-and-ttl)
 * [Caching External Facts](https://projects.puppetlabs.com/projects/facter/wiki/CachingExternalFacts)
 * [Puppet Cookbook: Deploying Custom Facts](http://www.puppetcookbook.com/posts/deploying-custom-facts-in-modules.html)
 * [mcollective](https://github.com/breerly/puppet-modules/blob/master/mcollective/files/plugins/facts/facter/facter.rb) in puppet-modules
 * [Only two hard things in Computer Science](http://martinfowler.com/bliki/TwoHardThings.html)

## Limitations

Supports F/OSS Puppet 3.3.0 - 4.0.0.  Tested on AIX, recent vintage Solaris, SuSE,
RedHat and RedHat-derivatives.

Does not support Puppet Enterprise due to the cached value wipe on each run.

Don't be surprised if is works elsewhere, too.  Or if it sets your house on fire.

The name of this module, facter\_cacheable, was chosen to not conflict with other
existing implementations such as the `Facter::Util::Cacheable` support in early
implementations of `waveclaw/subscription_manager`.

## Development

Please see CONTRIBUTING for advice on contributions.
