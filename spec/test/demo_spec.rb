require 'spec_helper.rb'
require 'webdrivers/chromedriver'

sleep 1

RSpec.describe 'basic_merrit_ui_tests', type: :feature do

  before(:each) do
    @session = create_web_session
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

  it 'Open ark page' do
    @session.visit '/'
    @session.within "header" do
      @session.find_link('Login')
      @session.click_link('Login')
    end
    @session.find_button('Guest')
    @session.click_button('Guest')

    @session.visit "/m/#{get_config('guest_coll')}"
    text = @session.find(:xpath, '//table/tbody/tr[1]/td[1]/a').text
    @session.click_link(text)
    @session.click_link("Version 1")
    text = @session.find(:xpath, "//table[@class='properties'][2]/tbody/tr[2]/th[1]/a").text
    # the following does not work if there is a space in the filename
    @session.click_link(text)
    expect(@session.current_url).to match(get_config('file_redirect_match'))
  end

end
