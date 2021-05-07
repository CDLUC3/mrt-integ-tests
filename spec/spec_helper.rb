require 'colorize'
require 'capybara/dsl'
require 'capybara/rspec'
require 'uc3-ssm'

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

def get_object_count
  @session.all(:xpath, "//table[@class='main']/tbody/tr/th[@class='ark-header']").count
end

def get_first_ark
  @session.find(:xpath, "//table[@class='main']/tbody/tr[1]/th[@class='ark-header']/a").text
end

def get_first_user_file
  @session.find(:xpath, "//table[@class='properties'][2]/tbody/tr[1]/th[1]/a").text
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

def guest_collections_no_access
  guest_actions.fetch('collections-no-access', [])
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

def encoding_variations(fk)
    # return [key]
    return [ key, "#{key}_z" ]
end

def guest_login
  @session.visit '/'
  @session.within "header" do
    @session.find_link('Login')
    @session.click_link('Login')
  end
  @session.find_button('Guest')
  @session.click_button('Guest')
end

def authenticated_login
  @session.visit '/'
  
  @session.within "header" do
    @session.find_link('Login')
    @session.click_link('Login')
  end

  @session.fill_in('login', with: login_user)
  @session.fill_in('password', with: login_password)
  @session.find('#submit_login').click

  sleep 1
  msg = @session.find("span.login-message").text
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
  @session.click_link("Version 1")
end

def visit_first_file
  text = get_first_user_file
  # the following does not work if there is a space in the filename
  @session.within("table.properties:nth-of-type(2)") do
    @session.click_link(text)
  end
  expect(@session.body.length).not_to eq(0)
  if @session.has_xpath?('h1')
    @session.within('h1') do
      puts(@session.text)
      expect(@session.text).not_to have_content("The page you were looking for doesn't exist.")
    end
  end
end

def visit_text_file(coll)
  @session.click_link("mrt-membership.txt")
  expect(@session.current_url).to match(coll['file_redirect_match'])
end

def create_filename(n)
  "/tmp/uploads/#{n}"
end

def create_file(path)
  File.open(path, 'w') do |f| 
    f.write("test") 
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
end

def sleep_label(stime, label)
  puts( "\tSleep #{stime} (#{label})")
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
  @session.find("input#file")
  @session.attach_file('File', f)
  @session.fill_in('title', with: title)
  @session.fill_in('local_id', with: localid)
  @session.find_button('Submit').click
  @session.within("section h1") do
    expect(@session.text).to have_content("Submission Received")
  end
  File.delete(f)
end

def check_file_obj_page(fname, prefix, seq)
  localid = local_id(prefix, seq)
  title = make_title(localid, fname)

  @session.fill_in('terms', with: localid)
  @session.find("section.lookup input[name='commit']").click
  @session.within("section h1") do
    expect(@session.text).to have_content("Search Results")
  end
  expect(get_object_count).to eq(1)
  text = get_first_ark
  @session.click_link(text)
  @session.within("section h2.object-title") do
    expect(@session.text).to have_content(title)
  end
  @session.find("h1 span.key").text.gsub(/[^A-Za-z0-9]+/, '_')
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
  if @session.has_css?('h1')
    @session.within('h1') do
      puts(@session.text)
      expect(@session.text).not_to have_content("The page you were looking for doesn't exist.")
    end
  end
end

def perform_object_download(zipname)
  Dir.chdir "/tmp/downloads"
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

  sleep_label(sleep_time_download, "to allow download of #{zipname} to complete")

  @session.find('a.obj_download').click
  cmd = "bsdtar tf #{zipname}|grep producer"
  listing = %x[ #{cmd} ]
  File.delete("#{zipname}")
  listing
end

def test_files
  [
    {txt: 'test_filex2.txt'}
  ]
end

def create_web_session
  @test_config = TestObjectPrefix.get_yaml_config

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

def check_storage_state
  url = @test_config['storage-state']
  return if url.empty?
  @session.visit(url)
  t = @session.find("body pre").text
  j = JSON.parse(t)
  node = j.fetch("sto:storageServiceState", {})
    .fetch("sto:nodeStates", {})
    .fetch("sto:nodeState", [])
  puts(node)
  expect(node.length).to be > 0
end