source "https://rubygems.org"

group :test do
  gem "rake"
  gem "listen","2.1.0"
  gem "puppet", ENV['PUPPET_VERSION'] || '~> 3.8.4'
  gem "rspec-puppet", :git => 'https://github.com/rodjek/rspec-puppet.git'
  gem 'rspec-puppet-utils', :git => 'https://github.com/Accuity/rspec-puppet-utils.git'
  gem 'hiera-puppet-helper', :git => 'https://github.com/bobtfish/hiera-puppet-helper.git'
  gem "puppetlabs_spec_helper"
  gem 'puppet-syntax'
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
  gem "beaker"
  gem "beaker-rspec"
end
