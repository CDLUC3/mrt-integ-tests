require 'colorize'
require 'capybara/dsl'
require 'capybara/rspec'
require 'byebug'

RSpec.configure do |config|
  config.color = true
  config.tty = true
  config.formatter = :documentation
  config.include Capybara::DSL
end
