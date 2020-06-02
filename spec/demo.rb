require 'spec_helper.rb'

RSpec.describe ':demo', type: :feature do

  Capybara.app_host = 'http://en.wikipedia.org'
  Capybara.run_server = false # don't start Rack

  # TODO: why is this a good thing?
  it 'value' do
    foo = 'bar'
    expect(foo).to eq('bar')
  end

  it 'value2' do
    #session = Capybara::Session.new(:selenium_chrome_headless)
    session = Capybara::Session.new(:selenium)
    session.visit 'http://en.wikipedia.org/wiki/Ruby_(programming_language)'
    foo = 'bar2'
    expect(foo).to eq('bar2')
  end
end
