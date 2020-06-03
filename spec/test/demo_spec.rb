require 'spec_helper.rb'
require 'webdrivers/chromedriver'

def load_config(name)
  path = File.join('config', name)
  raise Exception, "Config file #{name} not found!" unless File.exist?(path)
  raise Exception, "Config file #{name} is empty!" if File.size(path) == 0

  conf     = YAML.load_file(path)
end

RSpec.describe 'basic_merrit_ui_tests', type: :feature do

  before(:each) do
    conf = load_config('test_config.yml')
    @test_config = conf['default']

    Capybara.app_host = @test_config['url']
    Capybara.run_server = false # don't start Rack

    # @session = Capybara::Session.new(:selenium)
    @session = Capybara::Session.new(:selenium_chrome_headless)
  end

  # TODO: why is this a good thing?
  it 'Load Merritt UI home page' do
    @session.visit '/'
    @session.within("section.intro h2") do
      expect(@session.text).to have_content("A trusted, cost-effective digital preservation repository")
    end
  end

  it 'Perform Merritt Guest Login' do
    @session.visit '/'
    @session.within "header" do
      @session.find_link('Login')
      @session.click_link('Login')
    end
    @session.find_button('Guest')
    @session.click_button('Guest')
  end
end
