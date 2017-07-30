source "https://rubygems.org"

group :test do
  gem "rake"
  gem "listen","2.1.0"
  gem "puppet", ENV["PUPPET_VERSION"] || "~> 4.10.0"
  gem "rspec-puppet", :git => "https://github.com/rodjek/rspec-puppet.git"
  gem "rspec-puppet-utils", :git => "https://github.com/Accuity/rspec-puppet-utils.git"
  gem "hiera-puppet-helper", :git => "https://github.com/bobtfish/hiera-puppet-helper.git"
  gem "puppetlabs_spec_helper"
  gem "puppet-syntax"
  gem "puppet-lint"
  gem "metadata-json-lint"
end

group :development do
  gem "travis"
  gem "travis-lint"
  gem "vagrant-wrapper"
  gem "puppet-blacksmith"
  gem "guard-rake"
end

group :system_tests do
  if RUBY_VERSION < "2.2.5"
  # lock beaker version
  gem "beaker", "~> 2.0"
  gem "beaker-rspec", "~> 5.6"
  # lock nokogirii
  gem "nokogiri", "1.6.8"
  else
  gem "beaker"
  gem "beaker-rspec"
  gem "nokogiri"
  end
end

# codeclimate
gem "simplecov", :require => false
gem "codeclimate-test-reporter", :require => false
