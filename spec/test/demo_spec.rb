require 'spec_helper.rb'
require 'webdrivers/chromedriver'

RSpec.describe ':demo', type: :feature do

  Capybara.app_host = 'https://merritt-stage.cdlib.org'
  Capybara.run_server = false # don't start Rack

  # TODO: why is this a good thing?
  it 'value' do
    foo = 'bar'
    expect(foo).to eq('bar')
  end

  it 'value2' do
    # session = Capybara::Session.new(:selenium)
    session = Capybara::Session.new(:selenium_chrome_headless)
    session.visit 'https://merritt-stage.cdlib.org'
    session.within "header" do
      session.find_link('Login')
      session.click_link('Login')
    end
  end
end
