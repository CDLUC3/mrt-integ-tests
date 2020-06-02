require 'spec/spec_helper'

RSpec.describe ':demo' do

  Capybara.app_host = 'http://en.wikipedia.org'
  Capybara.run_server = false # don't start Rack

  # TODO: why is this a good thing?
  it 'value' do
    foo = 'bar'
    expect(foo).to eq('bar')
  end

  it 'value2' do
    visit '/wiki/Baltimore_Ravens'
    foo = 'bar2'
    expect(foo).to eq('bar2')
  end
end
