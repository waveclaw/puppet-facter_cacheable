#!/usr/bin/ruby
# frozen_string_literal: true

#
#  Provide a caching API for facter facts.
#
#  Uses YAML storage in a single key hash based on
#  the name of the fact.
#
#  Based on https://puppet.com/blog/facter-part-3-caching-and-ttl
#
#   Copyright 2016 Jeremiah Powell <waveclaw@hotmail.com>
#
#   See LICENSE for licensing.
#
#
require 'English'
require 'facter'
require 'time'
require 'yaml'

# Cache fact results with variable TTL or storage location
module Facter::Util::FacterCacheable
  @doc = <<EOF
  Cache a result for a TTL using facter that supports external facts.
  Default Time-to-live is 1 hour (3600 seconds).
EOF
  class << self
    # Get the on disk cached value or hit the callback to find it
    # @param key string The identifier for the data
    # @param ttl integer Time-to-live in seconds which defauls to 1 hr (3600)
    # @param source string Fully-qualified path to altnerative YAML file
    # @return [object] Cached value (hash, string, array, number, etc)
    # @api public
    def cached?(key, ttl = 3600, source = nil)
      cache = nil
      # which cache?
      mycache = find_cache(key, source)
      cache_file = mycache[:file]
      # check cache
      if File.exist?(cache_file)
        begin
          cache = YAML.load_file(cache_file)
          # returns [{}] structures if valid for Cached Facts
          cache = cache[0] if cache.is_a? Array
          cache = nil unless cache.is_a? Hash
          cache_time = File.mtime(cache_file)
        rescue StandardError => e
          Facter.debug("#{e.backtrace[0]}: #{$ERROR_INFO}.")
          cache = nil
          cache_time = Time.at(0)
        end
      end
      if !cache || (Time.now - cache_time) > ttl
        cache = nil
      end
      cache
    end

    # Write out a cache of data
    # @param key string The identifier for the data
    # @param ttl integer Time-to-live in seconds which defauls to 1 hr (3600)
    # @param source string Fully-qualified path to altnerative YAML file
    # @return [object] Cached value (hash, string, array, number, etc)
    # @api public
    def cache(key, value, source = nil)
      if key.nil? || value.nil?
        raise ArgumentError, 'Missing key or value to store'
      end
      mycache = find_cache(key, source)
      make_cache_path(mycache[:dir]) unless mycache[:dir].nil?
      # don't use the Rubyist standard pattern so we can test with rspec
      begin
        out = File.open(mycache[:file], 'w')
        YAML.dump({ key.to_s => value }, out)
        out.close
      rescue StandardError => e
        Facter.debug("Unable to write to cache #{mycache[:file]}: #{e.backtrace[0]}: #{$ERROR_INFO}.")
      end
    end

    # make a cache
    # @param file String The file
    # @param dir  String The location for the file
    # @api private
    def make_cache_path(cache_dir)
      # Changed to recursively create directories for facts.
      if !cache_dir.nil? && !File.exist?(cache_dir)
        recursive = cache_dir.split('/')
        directory = ''
        recursive.each do |sub_directory|
          directory += sub_directory + '/'
          Dir.mkdir(directory) unless File.directory?(directory)
        end
        # Dir.mkdir(cache_dir)
      end
    rescue StandardError => e
      Facter.debug("Unable to create path #{cache_dir} for a cache file #{e.backtrace[0]}: #{$ERROR_INFO}.")
    end

    # find a source
    # @param key [symbol] The identifier to use
    # @return file [string, string] The cachefile location
    # @api private
    def find_cache(key, source)
      unless key
        raise ArgumentError, 'No key was provided to check'
      end
      if !source
        cache_dir = '/etc/facter/facts.d'
        if Puppet.features.external_facts?
          Facter.search_external_path.each do |dir|
            # the plugin facts directory in /var/lib is cleaned each run
            # Exclude default pluginsync directory for PE 2016.2
            next unless File.exist?(dir) && (dir != '/opt/puppetlabs/puppet/cache/facts.d')
            # dir != '/var/lib/puppet/facts.d' and
            cache_dir = dir
            break
          end
        end
        keystring = key.to_s
        cache_file = "#{cache_dir}/#{keystring}.yaml"
      else
        cache_dir = File.dirname(source)
        cache_file = source
      end
      { file: cache_file, dir: cache_dir }
    end
  end
end
