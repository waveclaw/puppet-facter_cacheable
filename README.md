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

facter\_cacheable implements a Puppet feature for Facter that caches fact values
for a given time.

## Module Description

As mentioned in many getting started with Puppet guides, including some by
Puppet Labs, caching a fact can be useful.
A well-maintained cache can:
 * reduce frequency of expensive calls
 * store values reachable outside of Puppet agent runs
 * explicitly control schedule of fact refreshing

 There is limited planned support in Facter 2.0 and later for controlling some
 caching of Puppet facts.  Personally this developer has never seen it in the
 wild.

 No, this is not yet-another-varnish module either.

## Setup

### What facter\_cacheable affects

Deploys a feature, facter\_cacheable, which is accessed by a custom fact written
by a developer.

### Setup Requirements

PluginSync must be enabled on at least one Puppet agent run to deploy the module.

### Beginning with facter\_cacheable

## Usage

This module accepts no customization.  The facter\_cache call takes options for
only the value to cache, the time-to-live(ttl) and an optional format to store
the cache in.

If the directories containing the cache files do not exist, the module will _not_
create them.  That is left to the discretion of the end user.

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
consistent. Although with all Ruby programming, sanity is optional. Just like
the documentation.

YAML stored values may appear as arrays or string-indexed hashes depending on
the version of Puppet and Facter involved.  Unpacking those is left as an
exercise for the reader.

## Reference

 * [Facter Part 3: Caching and TTL](https://puppet.com/blog/facter-part-3-caching-and-ttl)
 * [Caching External Facts](https://projects.puppetlabs.com/projects/facter/wiki/CachingExternalFacts)
 * [Puppet Cookbook: Deploying Custom Facts](http://www.puppetcookbook.com/posts/deploying-custom-facts-in-modules.html)
 * [mcollective](https://github.com/breerly/puppet-modules/blob/master/mcollective/files/plugins/facts/facter/facter.rb) in puppet-modules
 * [Only two hard things in Computer Science](http://martinfowler.com/bliki/TwoHardThings.html)

## Limitations

Supports Puppet 3.3.0 - 4.4.2.  Tested on AIX, recent vintage Solaris, SuSE,
RedHat and RedHat-derivatives.

Don't be surprised if is works elsewhere, too.  Or if it sets you house on fire.

The name of this module, facter\_cacheable, was chosen to not conflict with other
existing implementations such as the `Facter::Util::Cacheable` support in early
implementations of `waveclaw/subscription_manager`.

## Development

Please see CONTRIBUTING for advice on contributions.
