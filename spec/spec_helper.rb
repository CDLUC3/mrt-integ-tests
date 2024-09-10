# frozen_string_literal: true

require 'English'
require 'colorize'
require 'capybara/dsl'
require 'capybara/rspec'
require 'uc3-ssm'
require 'nokogiri'
require 'selenium/webdriver'

RSpec.configure do |config|
  config.color = true
  config.tty = true
  config.formatter = :documentation
  config.include Capybara::DSL
end

def get_config(key)
  @test_config[key]
end

def sleep_time_ingest
  @test_config.fetch('sleep-times', {}).fetch('ingest', 10).to_i
end

def sleep_time_assemble
  @test_config.fetch('sleep-times', {}).fetch('assemble', 10).to_i
end

def sleep_time_download
  @test_config.fetch('sleep-times', {}).fetch('download', 10).to_i
end

def sleep_time_upload
  @test_config.fetch('sleep-times', {}).fetch('upload', 10).to_i
end

def get_object_count
  @session.all(:xpath, "//table[@class='main']/tbody/tr/th[@class='ark-header']").count
end

def get_first_ark
  @session.find(:xpath, "//table[@class='main']/tbody/tr[1]/th[@class='ark-header']/a").text
end

def get_first_user_file
  @session.find(:xpath, "//table[contains(@class, 'producer_files_properties')]//tr[1]/th[1]//a").text
end

def encoding_usecases
  @test_config.fetch('encfiles', {})
end

def guest_actions
  @test_config.fetch('guest_actions', {})
end

def guest_collections
  list = guest_actions.fetch('collections', [])
  return [] if list.nil?

  list
end

def guest_collections_no_access
  list = guest_actions.fetch('collections-no-access', [])
  return [] if list.nil?

  list
end

def non_guest_actions
  @test_config.fetch('non_guest_actions', {})
end

def non_guest_collections
  non_guest_actions.fetch('collections', [])
end

def all_collections
  guest_collections + non_guest_collections
end

def login_user
  non_guest_actions.fetch('login', {}).fetch('user', '')
end

def login_password
  non_guest_actions.fetch('login', {}).fetch('password', '')
end

def encoding_variations(_fk)
  # return [key]
  [key, "#{key}_z"]
end

def guest_login
  @session.visit '/'
  sleep 1
  @session.within 'header' do
    @session.find_link('Login')
    @session.click_link('Login')
  end
  @session.find_button('Guest')
  @session.click_button('Guest')
end

def authenticated_login
  @session.visit '/'
  sleep 1

  @session.within 'header' do
    @session.find_link('Login')
    @session.click_link('Login')
  end

  @session.fill_in('login', with: login_user)
  @session.fill_in('password', with: login_password)
  @session.find('#submit_login').click

  sleep 1
  @session.find('span.login-message').text
end

def visit_collection(coll)
  collname = coll['coll']
  @session.visit "/m/#{collname}"
end

def visit_first_object
  text = get_first_ark
  @session.click_link(text)
end

def visit_first_version
  # Ensure that the guest collection has download access
  @session.click_link('Version 1')
end

def visit_first_file
  text = get_first_user_file
  # the following does not work if there is a space in the filename
  @session.within('table.properties:nth-of-type(2)') do
    @session.click_link(text)
  end
  expect(@session.body.length).not_to eq(0)
  return unless @session.has_xpath?('h1')

  @session.within('h1') do
    puts(@session.text)
    expect(@session.text).not_to have_content("The page you were looking for doesn't exist.")
  end
end

def visit_text_file(coll)
  @session.click_link('mrt-membership.txt')
  expect(@session.current_url).to match(coll['file_redirect_match'])
end

def create_filename(n)
  "/tmp/uploads/#{n}"
end

def create_file(path)
  File.open(path, 'w') do |f|
    f.write('test')
    f.close
  end
  File.join(path)
end

def upload_regular_file(key)
  fname = TestObjectPrefix.test_files[key]
  prefix = TestObjectPrefix.localid_prefix
  path = create_filename(fname)
  f = create_file(path)
  add_file(f, fname, prefix, key)
  sleep_label(sleep_time_upload, 'to allow upload to complete')
end

def upload_v1_file(key)
  fname = TestObjectPrefix.version_files[key]
  prefix = TestObjectPrefix.localid_prefix
  path = create_filename(fname)
  f = create_file(path)
  add_file(f, fname, prefix, key)
  sleep_label(sleep_time_upload * 3, 'to allow upload to complete')
end

def update_v2_file(key)
  fname = "#{TestObjectPrefix.version_files[key]}.v2"
  prefix = TestObjectPrefix.localid_prefix
  path = create_filename(fname)
  f = create_file(path)
  add_file(f, fname, prefix, key)
  sleep_label(sleep_time_upload, 'to allow upload to complete')
end

def sleep_label(stime, label)
  puts("\tSleep #{stime} (#{label})")
  sleep stime
end

def local_id(prefix, seq)
  "#{prefix}_#{seq}"
end

def make_title(localid, fname)
  "#{localid} #{fname}"
end

def add_file(f, fname, prefix, seq)
  localid = local_id(prefix, seq)
  title = make_title(localid, fname)

  @session.click_link('Add object')
  @session.find('input#file')
  @session.attach_file('File', f)
  @session.fill_in('title', with: title)
  @session.fill_in('local_id', with: localid)
  @session.find_button('Submit').click
  @session.within('section h1') do
    expect(@session.text).to have_content('Submission Received')
  end
  File.delete(f)
end

def check_file_obj_page(fname, prefix, seq)
  localid = local_id(prefix, seq)
  title = make_title(localid, fname)

  @session.fill_in('terms', with: localid)
  @session.find("section.lookup input[name='commit']").click
  @session.within('section h1') do
    expect(@session.text).to have_content('Search Results')
  end
  expect(get_object_count).to eq(1)
  text = get_first_ark
  @session.click_link(text)
  @session.within('section h2.object-title') do
    expect(@session.text).to have_content(title)
  end
  @session.find('h1 span.key').text.gsub(/[^A-Za-z0-9]+/, '_')
end

def find_file_on_version_page(file)
  @session.find_link('Version 1')
  @session.click_link('Version 1')
  @session.find_link(file)
  @session.click_link(file)
  validate_file_page
end

def validate_file_page
  expect(@session.body.length).not_to eq(0)
  expect(@session.title).not_to have_content('Action Controller: Exception caught')
  return unless @session.has_css?('h1')

  @session.within('h1') do
    expect(@session.text).not_to have_content("The page you were looking for doesn't exist.")
    expect(@session.text).not_to have_content('Rack::QueryParser::InvalidParameterError')
    puts('h1 found on file page')
    puts(@session.text)
  end
end

def perform_object_download(zipname)
  Dir.chdir '/tmp/downloads'
  @session.find_button('Download object')
  @session.click_button('Download object')

  sleep 2

  @session.find('div.ui-dialog')
  @session.within('.ui-dialog-title') do
    expect(@session.text).to have_content('Preparing Object for Download')
  end

  sleep_label(sleep_time_assemble, "to allow assembly of #{zipname} to complete")

  @session.within('.ui-dialog-title') do
    expect(@session.text).to have_content('Object is ready for Download')
  end

  sleep_label(5, 'to allow download link to appear')

  @session.find('a.obj_download').click

  sleep_label(sleep_time_download, "to allow download of #{zipname} to complete")

  puts 'List contents of /tmp/downloads'
  puts `ls /tmp/downloads`

  cmd = "bsdtar tf #{zipname}|grep producer"
  listing = `#{cmd}`
  puts 'Zip file listing'
  puts listing
  begin
    File.delete(zipname.to_s)
  rescue Errno::ENOENT
    # allow for cases where the zip cannot be deleted
  end
  listing
end

def test_files
  [
    { txt: 'test_filex2.txt' }
  ]
end

def create_web_session
  @test_config = TestObjectPrefix.get_yaml_config

  Capybara.app_host = @test_config['url']
  Capybara.run_server = false # don't start Rack

  if ENV['CHROME_URL']
    Capybara.register_driver :remote do |app|
      Capybara::Selenium::Driver.new(app, browser: :remote, options: Selenium::WebDriver::Options.chrome,
        url: ENV['CHROME_URL'])
    end
    @session = Capybara::Session.new(:remote)
  else
    @session = Capybara::Session.new(:selenium_chrome)
  end
end

def end_web_session(session)
  session.reset!
  session.driver.quit
end

def check_service_state(url, redirect: false)
  return if url.empty?

  state = json_request(url, redirect: redirect)
  expect(state.empty?).to be(false)
  state
end

def build_info_url(url)
  return url if get_service(url) == 'ui'

  m = url.match(%r{(https?://[^\/]+/([^\/]+/)?).*$})
  return '' unless m

  "#{m[1]}static/build.content.txt"
end

def check_build_info(url)
  return if url.empty?

  if get_service(url) == 'ui'
    text = json_request(url).fetch('version', '')
    expect(text.empty?).to be(false)
    text
  else
    text = text_request(url)
    expect(text.empty?).to be(false)
    text.split("\n").first
  end
end

def check_state_active(state)
  top = state.keys.first
  data = state.fetch(top, {})
  case top
  when 'ing:ingestServiceState'
    expect(data.fetch('ing:submissionState', '')).to eq('thawed')
  when 'sto:storageServiceState'
    expect(data.fetch('sto:nodeStates', {}).fetch('sto:nodeState', []).length).to be > 0
  when 'fix:fixityServiceState'
    state = data.fetch('fix:status', '')
    skip('Audit state unknown -- may have no work') if state == 'unknown'
    expect(state).to eq('running')
  when 'invsv:invServiceState'
    expect(data.fetch('invsv:zookeeperStatus', '')).to eq('running')
    expect(data.fetch('invsv:dbStatus', '')).to eq('running')
    expect(data.fetch('invsv:systemStatus', '')).to eq('running')
  when 'repsvc:replicationServiceState'
    expect(data.fetch('repsvc:status', '')).to eq('running')
  end
end

def get_service(url)
  return 'ingest' if url =~ /ingest/
  return 'store' if url =~ /store/
  return 'access' if url =~ /access/
  return 'inventory' if url =~ /mrtinv/
  return 'inventory' if url =~ /inventory/
  return 'replic' if url =~ /replic/
  return 'audit' if url =~ /audit/
  return 'sword' if url =~ /sword/
  return 'ui' if url =~ /state\.json/
  return 'ui' if url =~ /^merritt(-stage)?\.cdlib\.org/

  ''
end

def has_service_state(url)
  service = get_service(url)
  return @test_config.fetch('ui_audit_replic', true) if service == 'ui'

  true
end

def has_build_info(url)
  service = get_service(url)
  return @test_config.fetch('replic_build_info', true) if service == 'replic'
  return @test_config.fetch('ui_audit_replic', true) if service == 'ui'

  true
end

def json_request(url, redirect: true, guest_credentials: false)
  flags = redirect ? '-sL' : '-s'
  creds = guest_credentials ? '-u anonymous:guest' : ''
  json = `curl #{flags} #{creds} #{url}`
  begin
    JSON.parse(json)
  rescue StandardError
    # return empty object to signal unparseable json
    {}
  end
end

def json_rel_request(url, redirect: true, guest_credentials: false)
  json_request("#{Capybara.app_host}/#{url}", redirect: redirect, guest_credentials: guest_credentials)
end

def text_request(url)
  flags = '-s -S -f'
  text = `curl #{flags} #{url}`
  return '' if $CHILD_STATUS.exitstatus != 0

  text
end

def xml_request(url, redirect: true)
  flags = redirect ? '-sL' : '-s'
  creds = "-u #{non_guest_actions.fetch('login', {}).fetch('user',
    '')}:#{non_guest_actions.fetch('login', {}).fetch('password', '')}"
  xml = `curl #{flags} #{creds} #{url}`
  begin
    Nokogiri::XML(xml)
  rescue StandardError
    # return empty object to signal unparseable json
    Nokogiri::XML('')
  end
end
