# encoding: utf-8

require 'rubygems'
require 'bundler'
begin
  Bundler.setup(:default, :development)
rescue Bundler::BundlerError => e
  $stderr.puts e.message
  $stderr.puts "Run `bundle install` to install missing gems"
  exit e.status_code
end
require 'rake'

require 'jeweler'
Jeweler::Tasks.new do |gem|
  # gem is a Gem::Specification... see http://docs.rubygems.org/read/chapter/20 for more options
  gem.name = "aws-s3-cse"
  gem.homepage = "http://github.com/tcnijmeijer/aws-s3-cse"
  gem.license = "MIT"
  gem.summary = "Provides a ruby implementation of the Client Side Encryption client for AWS-S3"
  gem.description = "Provides a ruby implementation of the Client Side Encryption client for AWS-S3"
  gem.email = "tom@nijmeijer.org"
  gem.authors = ["Tom Nijmeijer"]
  # dependencies defined in Gemfile
end
Jeweler::RubygemsDotOrgTasks.new

require 'rspec/core/rake_task'
RSpec::Core::RakeTask.new(:spec) do |spec|
 spec.pattern      = './spec/**/*_spec.rb'
end

RSpec::Core::RakeTask.new(:rcov) do |rcov|
 rcov.pattern    = "./spec/**/*_spec.rb"
 rcov.rcov       = true
 rcov.rspec_opts = "--format doc --color"
 rcov.rcov_opts  = "-x gem,spec"
end

task :default => :spec
