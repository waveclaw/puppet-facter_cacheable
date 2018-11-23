#!/usr/bin/ruby -S rspec
# frozen_string_literal: false

#
#  Test the facter_cachable utility
#
#   Copyright 2016 JD Powell <waveclaw@hotmail.com>
#
#   See LICENSE for licensing.
#

require 'spec_helper'
require 'stringio'
require 'yaml'
require 'time'
require 'facter'
require 'facter/util/facter_cacheable'

data = {
  single: "--- \n  string_value: tested",
  list_like: "--- \n  list_value: \n    - thing1\n    - thing2",
  hash_like:     "--- \n  hash_value: \n    alpha: one\n    beta: two\n    tres: three",
}

# reformat each of the keys using the local YAML format convention
# this is needed do to spacing changes between Ruby 1.9, 2.0 and 2.1.
data.keys.each do |testcase|
  data[testcase] = YAML.dump(YAML.safe_load(data[testcase]))
end

# YAML.load* does not return symbols as hash keys!
expected = {
  single: { 'string_value' => 'tested' },
  list_like: { 'list_value' => ['thing1', 'thing2'] },
  hash_like: { 'hash_value' => {
    'alpha' => 'one', 'beta' => 'two', 'tres' => 'three'
  } },
}
describe 'Facter::Util::FacterCacheable' do
  describe 'Facter::Util::FacterCacheable.cached?', type: :function do
    context 'when the cache is hot' do
      data.keys.each do |testcase|
        cache = "/tmp/#{testcase}.yaml"
        rawdata = StringIO.new(data[testcase])
        it "for #{testcase} values should return the cached value" do
          expect(Puppet.features).to receive(:external_facts?).and_return(true)
          expect(Facter).to receive(:search_external_path).and_return(['/tmp'])
          expect(File).to receive(:exist?).with('/tmp').and_return(true) # find_cache
          expect(File).to receive(:exist?).with(cache).and_return(true)
          expect(YAML).to receive(:load_file).with(cache) {
            YAML.load_stream(rawdata)
          }
          expect(File).to receive(:mtime).with(cache).and_return(Time.now)
          expect(Facter::Util::FacterCacheable.cached?(testcase)).to eq(
            expected[testcase],
          )
        end
      end
    end
    context 'when the cache is cold' do
      data.keys.each do |testcase|
        cache = "/tmp/#{testcase}.yaml"
        rawdata = StringIO.new(data[testcase])
        it "for #{testcase} values should return nothing" do
          expect(Puppet.features).to receive(:external_facts?).and_return(true)
          expect(Facter).to receive(:search_external_path).and_return(['/tmp'])
          expect(File).to receive(:exist?).with('/tmp').and_return(true) # find_cache
          expect(File).to receive(:exist?).with(cache).and_return(true)
          expect(YAML).to receive(:load_file).with(cache) {
            YAML.load_stream(rawdata)
          }
          expect(File).to receive(:mtime).with(cache).and_return(Time.at(0))
          expect(Facter::Util::FacterCacheable.cached?(testcase)).to eq(nil)
        end
      end
    end
    context 'when the cache is missing' do
      data.keys.each do |testcase|
        cache = "/tmp/#{testcase}.yaml"
        it "for #{testcase} values should return nothing" do
          expect(Puppet.features).to receive(:external_facts?).and_return(true)
          expect(Facter).to receive(:search_external_path).and_return(['/tmp'])
          expect(File).to receive(:exist?).with('/tmp').and_return(true) # find_cache
          expect(File).to receive(:exist?).with(cache).and_return(false)
          expect(YAML).not_to receive(:load_file).with(cache)
          expect(File).not_to receive(:mtime).with(cache)
          expect(Facter::Util::FacterCacheable.cached?(testcase)).to eq(nil)
        end
      end
    end
    context 'for garbage values' do
      cache = '/tmp/garbage.yaml'
      rawdata = StringIO.new('random non-yaml garbage')
      it 'returns nothing' do
        expect(Puppet.features).to receive(:external_facts?).and_return(true)
        expect(Facter).to receive(:search_external_path).and_return(['/tmp'])
        expect(File).to receive(:exist?).with('/tmp').and_return(true) # find_cache
        expect(File).to receive(:exist?).with(cache).and_return(true)
        expect(YAML).to receive(:load_file).with(cache) {
          YAML.load_stream(rawdata)
        }
        expect(File).to receive(:mtime).with(cache).and_return(Time.now)
        expect(Facter::Util::FacterCacheable.cached?('garbage')).to eq(nil)
      end
    end
  end
  describe 'Facter::Util::FacterCacheable.cache', type: :fact do
    context 'raises an error' do
      it 'for missing arguments' do
        expect {
          Facter::Util::FacterCacheable.cache(nil, nil)
        }.to raise_error(ArgumentError, %r{Missing key or value to store})
      end
      it 'for failed cache writes' do
        expect(Facter::Util::FacterCacheable).to receive(:find_cache).with(
          'thing', '/dev/null'
        ).and_return(file: 'thing', dir: '/dev/null')
        expect(Facter::Util::FacterCacheable).to receive(:make_cache_path).with('/dev/null')
        expect(File).to receive(:open).with('thing', 'w') { throw IOError }
        expect(Facter).to receive(:debug)
        Facter::Util::FacterCacheable.cache('thing', 'value', '/dev/null')
      end
    end
    context "if getting a cache's location fails" do
      it 'skips trying to make that location' do
        key = ''
        value = ''
        result = StringIO.new('')
        cache = '/tmp/.yaml'
        expect(Facter::Util::FacterCacheable).to receive(:find_cache).and_return(
          dir: nil, file: cache,
        )
        expect(Facter::Util::FacterCacheable).not_to receive(:make_cache_path)
        expect(File).to receive(:open).with(cache, 'w').and_return(result)
        result.rewind
        expect(YAML).to receive(:dump).with({ key => value }, result).and_call_original
        Facter::Util::FacterCacheable.cache(key, value)
        expect(result.string).to eq("---\n'': ''\n")
      end
    end
    data.keys.each do |testcase|
      context "for #{testcase}" do
        result = StringIO.new('')
        key = expected[testcase].keys[0]
        value = expected[testcase][key]
        cache = "/tmp/#{key}.yaml"
        filespec = { dir: '/tmp', file: cache }
        it "stores a #{testcase} value in YAML" do
          expect(Facter::Util::FacterCacheable).to receive(:find_cache).with(key, cache).and_return(filespec)
          expect(Facter::Util::FacterCacheable).to receive(:make_cache_path).with(filespec[:dir])
          expect(File).to receive(:open).with(cache, 'w').and_return(result)
          expect(YAML).to receive(:dump).with({ key => value }, result).and_call_original
          Facter::Util::FacterCacheable.cache(key, value, cache)
          expect(result.string).to eq(data[testcase])
        end
      end
    end
  end
  #
  # this tests an internal helper function instead of overall logic
  #
  describe 'Facter::Util::FacterCacheable.make_cache_path', type: :fact do
    it 'does nothing for empty arguments' do
      expect(File).not_to receive(:exist?).with(nil)
      Facter::Util::FacterCacheable.make_cache_path(nil)
    end
    it 'does nothing if there is an Error' do
      expect(File).to receive(:exist?).with('/tmp/nothing') { throw IOError }
      expect(Facter).to receive(:debug)
      Facter::Util::FacterCacheable.make_cache_path('/tmp/nothing')
    end
    it 'checks for chached directories' do
      expect(File).to receive(:exist?).with('/tmp/nothing').and_return(true)
      expect(Dir).not_to receive(:mkdir)
      Facter::Util::FacterCacheable.make_cache_path('/tmp/nothing')
    end
    it 'recursively makes a deep path' do
      expect(File).to receive(:exist?).with('/this/is/deep/nothing').and_return(false)
      ['/this/', '/this/is/', '/this/is/deep/', '/this/is/deep/nothing/'].each do |dir|
        expect(Dir).to receive(:mkdir).with(dir)
      end
      Facter::Util::FacterCacheable.make_cache_path('/this/is/deep/nothing')
    end
  end

  describe 'Facter::Util::FacterCacheable.find_cache', type: :fact do
    it 'returns a dir for a key and directory' do
      result = Facter::Util::FacterCacheable.find_cache('foo', '/foo/bar')
      expect(result).to eq(file: '/foo/bar', dir: '/foo')
    end
    it 'returns current dir for a key with a directory' do
      result = Facter::Util::FacterCacheable.find_cache('foo', 'bar')
      expect(result).to eq(file: 'bar', dir: '.')
    end
    it 'returns the default path path for no source' do
      default_path = '/etc/facter/facts.d'
      expect(Puppet.features).to receive(:external_facts?).and_return(false)
      result = Facter::Util::FacterCacheable.find_cache('foo', nil)
      expect(result).to eq(
        file: "#{default_path}/foo.yaml", dir: default_path,
      )
    end
    it 'returns a dir for a key and no directory' do
      expect(Puppet.features).to receive(:external_facts?).and_return(true)
      expect(Facter).to receive(:search_external_path).and_return(['/tmp'])
      result = Facter::Util::FacterCacheable.find_cache('foo', nil)
      expect(result).to eq(file: '/tmp/foo.yaml', dir: '/tmp')
    end
    it 'checks all paths when there are many' do
      expect(Puppet.features).to receive(:external_facts?).and_return(true)
      expect(Facter).to receive(:search_external_path).and_return(['/a', 'b', '/tmp'])
      expect(File).to receive(:exist?).with('/a').and_return(false)
      expect(File).to receive(:exist?).with('b').and_return(false)
      expect(File).to receive(:exist?).with('/tmp').and_return(true)
      result = Facter::Util::FacterCacheable.find_cache('foo', nil)
      expect(result).to eq(file: '/tmp/foo.yaml', dir: '/tmp')
    end
    it 'returns an error for no key' do
      expect {
        Facter::Util::FacterCacheable.find_cache(nil, nil)
      }.to raise_error(ArgumentError, %r{No key})
      expect {
        Facter::Util::FacterCacheable.find_cache(nil, 'foo')
      }.to raise_error(ArgumentError, %r{No key})
    end
  end
end
