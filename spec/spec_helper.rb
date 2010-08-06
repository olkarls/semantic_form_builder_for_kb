$:.unshift(File.expand_path('../lib', File.dirname(__FILE__)))

require 'rubygems'
require 'rspec'
require 'semantic_form_builder'
require 'rspec_tag_matchers'
require 'active_record'
require 'action_controller'
require 'mocha'

RSpec.configure do |config|
  config.include(RspecTagMatchers)
end

ActiveRecord::Base.establish_connection(:adapter => "sqlite3", :database => ":memory:")
load(File.dirname(__FILE__) + "/schema.rb")
require File.dirname(__FILE__) + '/../rails/init.rb'
