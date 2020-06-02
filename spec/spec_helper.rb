require 'colorize'
require 'capybara/webmock'

RSpec.configure do |config|
  config.color = true
  config.tty = true
  config.formatter = :documentation
  # config.raise_errors_for_deprecations! # TODO: enable this
  config.mock_with :rspec

  config.before(:each) do |example|
    if example.metadata[:type] == :feature
      Capybara::Webmock.start
      # Allow Capybara to make localhost requests and also contact the
      # google api chromedriver store
      # WebMock.allow_net_connect!(net_http_connect_on_start: true)
      # WebMock.disable_net_connect!(allow: '*')
      # WebMock.disable_net_connect!(
      #   allow_localhost: true,
      #   allow: %w[chromedriver.storage.googleapis.com]
      # )
    end
  end
  config.after(:suite) do
    Capybara::Webmock.stop
  end
end
