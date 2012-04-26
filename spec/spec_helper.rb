$: << File.join(File.dirname(File.dirname(__FILE__)), "lib")

require 'rspec'
require 'rspec/mocks'
require 'rspec-spies'
require 'aws-s3-cse'

AWS.eager_autoload!