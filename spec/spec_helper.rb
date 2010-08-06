$:.unshift(File.expand_path('../lib', File.dirname(__FILE__)))

require 'rubygems'
require 'rspec'
require 'semantic_form_builder'
require 'rspec_tag_matchers'

RSpec.configure do |config|
  config.include(RspecTagMatchers)
end
