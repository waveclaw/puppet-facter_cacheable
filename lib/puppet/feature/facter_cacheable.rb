#!/usr/bin/ruby
#
#  Puppet feature for the facter_cachable utility
#
#  See http://alcy.github.io/2012/11/21/handling-gem-dependencies-in-custom-puppet-providers/
#
#   Copyright 2016 JD Powell <waveclaw@hotmail.com>
#
#   See LICENSE for licensing.
#
require 'puppet/util/feature'
require 'facter'

Puppet.features.add(:facter_cacheable) do
  require 'time'
  require 'yaml'
  if Puppet.features.external_facts?
    # use external location
    for dir in Facter.search_external_path
      Puppet::FileSystem.exist?(dir)
    end
  else
    # use default
    if !Puppet::Util::Platform.windows?
      Puppet::FileSystem.exist?('/var/lib/puppet/facts.d')
    end
  end
end
