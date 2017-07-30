#!/usr/bin/ruby -S rspec
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

#
#  The alternative is to rig up some 'approximate' validation and compare
#  methodology inside of rSpec
#
default_data = {
  :single => "--- \n  string_value: tested",
  :list_like   => "--- \n  list_value: \n    - thing1\n    - thing2",
  :hash_like   =>
    "--- \n  hash_value: \n    alpha: one\n    beta: two\n    tres: three",
}

puppet_360 = {
  :single => "---\nstring_value: tested",
  :list_like   => "---\n  list_value:\n    - thing1\n    - thing2\n",
  :hash_like   =>
    "---\n  hash_value:\n    alpha: one\n    beta: two\n    tres: three\n",
}

puppet_442 = {
  :single => "---\nstring_value: tested\n",
  :list_like   => "---\nlist_value:\n- thing1\n- thing2\n",
  :hash_like   =>
    "---\nhash_value:\n  alpha: one\n  beta: two\n  tres: three\n",
}

case Facter.value(:puppetversion)
when '4.4.2', '4.8.0', '4.9.0', '4.10.5'
   data = puppet_442
 when '3.6.0'
   data = puppet_360
 else
   data = default_data
end

# YAML.load* does not return symbols as hash keys!
expected = {
  :single => { "string_value" => 'tested' },
  :list_like   => { "list_value" => [ 'thing1', 'thing2' ] },
  :hash_like   => { "hash_value" => {
    'alpha' => 'one', 'beta'  => 'two', 'tres'  => 'three' } }
}

describe "Facter::Util::Facter_cacheable.cached?", :type => :function do

context "when the cache is hot" do
data.keys.each { |testcase|
    cache = "/tmp/#{testcase.to_s}.yaml"
    rawdata = StringIO.new(data[testcase])
    it "for #{testcase.to_s} values should return the cached value" do
      expect(Puppet.features).to receive(:external_facts?) { true }
      expect(Facter).to receive(:search_external_path) { ['/tmp'] }
      expect(File).to receive(:exist?).with('/tmp') { true } # get_cache
      expect(File).to receive(:exist?).with(cache) { true }
      expect(YAML).to receive(:load_file).with(cache) {
        YAML.load_stream(rawdata)
      }
      expect(File).to receive(:mtime).with(cache) { Time.now }
      expect(Facter::Util::Facter_cacheable.cached?(testcase)).to eq(
        expected[testcase])
    end
  }
  end

  context "when the cache is cold" do
    data.keys.each { |testcase|
        cache = "/tmp/#{testcase.to_s}.yaml"
        rawdata = StringIO.new(data[testcase])
        it "for #{testcase.to_s} values should return nothing" do
          expect(Puppet.features).to receive(:external_facts?) { true }
          expect(Facter).to receive(:search_external_path) { ['/tmp'] }
          expect(File).to receive(:exist?).with('/tmp') { true } # get_cache
          expect(File).to receive(:exist?).with(cache) { true }
          expect(YAML).to receive(:load_file).with(cache) {
            YAML.load_stream(rawdata)
          }
          expect(File).to receive(:mtime).with(cache) { Time.at(0) }
          expect(Facter::Util::Facter_cacheable.cached?(testcase)).to eq(nil)
        end
    }
  end

  context "when the cache is missing" do
    data.keys.each { |testcase|
        cache = "/tmp/#{testcase.to_s}.yaml"
        rawdata = StringIO.new(data[testcase])
        it "for #{testcase.to_s} values should return nothing" do
          expect(Puppet.features).to receive(:external_facts?) { true }
          expect(Facter).to receive(:search_external_path) { ['/tmp'] }
          expect(File).to receive(:exist?).with('/tmp') { true } # get_cache
          expect(File).to receive(:exist?).with(cache) { false }
          expect(YAML).to_not receive(:load_file).with(cache)
          expect(File).to_not receive(:mtime).with(cache)
          expect(Facter::Util::Facter_cacheable.cached?(testcase)).to eq(nil)
        end
    }
  end

  context "for garbage values" do
    cache = "/tmp/garbage.yaml"
    rawdata = StringIO.new('random non-yaml garbage')
    it "should return nothing" do
      expect(Puppet.features).to receive(:external_facts?) { true }
      expect(Facter).to receive(:search_external_path) { ['/tmp'] }
      expect(File).to receive(:exist?).with('/tmp') { true } # get_cache
      expect(File).to receive(:exist?).with(cache) { true }
      expect(YAML).to receive(:load_file).with(cache) {
          YAML.load_stream(rawdata)
      }
      expect(File).to receive(:mtime).with(cache) { Time.now }
      expect(Facter::Util::Facter_cacheable.cached?('garbage')).to eq(nil)
    end
  end
end

describe "Facter::Util::Facter_cacheable.cache", :type => :function do
  data.keys.each { |testcase|
    result = StringIO.new('')
    key = (expected[testcase].keys)[0]
    value = expected[testcase][key]
    cache = "/tmp/#{key}.yaml"
    it "should store a #{testcase.to_s} value in YAML" do
      expect(Facter::Util::Facter_cacheable).to receive(:get_cache) {
        {:dir => '/tmp', :file => cache }
      }
      expect(File).to receive(:open).with(cache, 'w') { result }
      # WTF? called 785 times?
      #expect(YAML).to receive(:dump).with({ key => value }, result) {
      #    YAML.dump({ key => value }, result)
      #}
      Facter::Util::Facter_cacheable.cache(key, value)
      expect(result.string).to eq(data[testcase])
    end
  }
  context "for garbage input values" do
    it "should sliently output nothing" do
      result = StringIO.new('')
      cache = "/tmp/.yaml"
      expect(Facter::Util::Facter_cacheable
       ).to_not receive(:get_cache).and_call_original
      expect(File).to_not receive(:open).with(cache, 'w') { result }
      Facter::Util::Facter_cacheable.cache(nil, nil)
      expect(result.string).to eq('')
    end
  end
  #
  # this tests use of an internal helper function instead of overall logic
  #
  context "if getting a cache's location fails" do
    it "should skip trying to make that location" do
      result = StringIO.new('')
      cache = "/tmp/.yaml"
      expect(Facter::Util::Facter_cacheable).to receive(:get_cache) {
      { :dir => nil, :file => cache } }
      expect(File).to_not receive(:exist?).with(nil)
      expect(Dir).to_not receive(:mkdir)
      expect(File).to receive(:open).with(cache, 'w') { result }
      Facter::Util::Facter_cacheable.cache('', '')
      expect(result.string).to eq("---\n'': ''\n")
    end
  end
end

#
# this tests an internal helper function instead of overall logic
#
describe "Facter::Util::Facter_cacheable.get_cache", :type => :function do
  it "should return a dir for a key and directory" do
    result = Facter::Util::Facter_cacheable.get_cache('foo', '/foo/bar')
    expect(result).to eq({:file => '/foo/bar', :dir => '/foo' })
  end
  it "should return current dir for a key with a directory" do
    result = Facter::Util::Facter_cacheable.get_cache('foo', 'bar')
    expect(result).to eq({:file => 'bar', :dir => '.' })
  end
  it "should return the default path path for no source" do
    default_path = '/etc/facter/facts.d'
    expect(Puppet.features).to receive(:external_facts?) { false }
    result = Facter::Util::Facter_cacheable.get_cache('foo', nil)
    expect(result).to eq(
      {:file => "#{default_path}/foo.yaml", :dir => default_path })
  end
  it "should return a dir for a key and no directory" do
    expect(Puppet.features).to receive(:external_facts?) { true }
    expect(Facter).to receive(:search_external_path) { ['/tmp'] }
    result = Facter::Util::Facter_cacheable.get_cache('foo', nil)
    expect(result).to eq({:file => '/tmp/foo.yaml', :dir => '/tmp'})
  end
  it "should check all paths when there are many" do
    expect(Puppet.features).to receive(:external_facts?) { true }
    expect(Facter).to receive(:search_external_path) { ['/a', 'b', '/tmp' ] }
    expect(File).to receive(:exist?).with('/a') { false }
    expect(File).to receive(:exist?).with('b') { false }
    expect(File).to receive(:exist?).with('/tmp') { true }
    result = Facter::Util::Facter_cacheable.get_cache('foo', nil)
    expect(result).to eq({:file => '/tmp/foo.yaml', :dir => '/tmp'})
  end
  it "should return an error for no key" do
    expect {
      Facter::Util::Facter_cacheable.get_cache(nil, nil)
    }.to raise_error(ArgumentError, /No key/)
    expect {
      Facter::Util::Facter_cacheable.get_cache(nil, 'foo')
    }.to raise_error(ArgumentError, /No key/)
  end
end
