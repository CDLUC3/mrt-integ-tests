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

def load_config(path)
  raise Exception, "Config file #{path} not found!" unless File.exist?(path)
  raise Exception, "Config file #{path} is empty!" if File.size(path) == 0

  conf     = YAML.load_file(path)
end

def get_config(key)
  @test_config[key]
end

def create_web_session(config_file)
  @test_config = load_config(config_file)['default']

  Capybara.app_host = @test_config['url']
  Capybara.run_server = false # don't start Rack

  if ENV['CHROME_URL']
    Capybara.register_driver :selenium_chrome_headless do |app|
      args = [
        '--no-default-browser-check',
        '--start-maximized',
        '--headless',
        '--disable-dev-shm-usage',
        '--whitelisted-ips'
      ]
      caps = Selenium::WebDriver::Remote::Capabilities.chrome("chromeOptions" => {
        "args" => args,
        "prefs" => {
          'download.default_directory' => '/tmp',
          'download.directory_upgrade' => true,
          'download.prompt_for_download' => false
        }
      })

      Capybara::Selenium::Driver.new(
        app,
        browser: :remote,
        desired_capabilities: caps,
        url: ENV['CHROME_URL']
      )
    end
  end
  @session = Capybara::Session.new(:selenium_chrome_headless)
  #@session = Capybara::Session.new(:selenium_chrome)
end

def end_web_session(session)
  session.reset!
end