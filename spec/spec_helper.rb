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

def sleep_time_ingest
  @test_config.fetch('sleep-times', {}).fetch('ingest', 10)
end

def sleep_time_assemble
  @test_config.fetch('sleep-times', {}).fetch('assemble', 10)
end

def sleep_time_download
  @test_config.fetch('sleep-times', {}).fetch('download', 10)
end

def encoding_usecases
  @test_config.fetch('encfiles', {})
end

def guest_actions
  @test_config.fetch('guest_actions', {})
end

def guest_collections
  guest_actions.fetch('collections', [])
end

def non_guest_actions
  @test_config.fetch('non_guest_actions', {collections: []})
end

def non_guest_collections
  non_guest_actions.fetch('collections', [])
end

def all_collections
  coll = [] 
  guest_collections.each do |c|
    coll.append(c)
  end
  non_guest_collections.each do |c|
    coll.append(c)
  end
  coll
end


def encoding_variations(fk)
    # return [key]
    return [ key, "#{key}_z" ]
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