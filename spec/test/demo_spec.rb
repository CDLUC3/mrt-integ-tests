require 'spec_helper.rb'
require 'webdrivers/chromedriver'

sleep 1

class Prefix
  @@localid_prefix = Time.new.strftime('%Y_%m_%d_%H%M') 
  def self.localid_prefix
    @@localid_prefix
  end
end

puts Prefix.localid_prefix

RSpec.describe 'basic_merrit_ui_tests', type: :feature do

  def all_collections
    coll = [] 
    get_config('guest_collections').each do |c|
      coll.append(c)
    end
    get_config('non_guest_collections').each do |c|
      coll.append(c)
    end
    coll
  end

  before(:each) do
    @session = create_web_session
  end

  it 'Load Merritt UI home page' do
    @session.visit '/'
    @session.within("section.intro h1") do
      expect(@session.text).to have_content("A trusted, cost-effective digital preservation repository")
    end
  end

  it 'Print constants' do
    puts get_config('label')
  end

  describe 'Guest Login' do
    before(:each) do
      @session.visit '/'
      @session.within "header" do
        @session.find_link('Login')
        @session.click_link('Login')
      end
      @session.find_button('Guest')
      @session.click_button('Guest')
    end
  
    it 'Perform Merritt Guest Login' do
    end

    it 'Open guest collections - file presigned download' do

      get_config('guest_collections').each do |coll|
        @session.visit "/m/#{coll['coll']}"
        text = @session.find(:xpath, "//table[@class='main']/tbody/tr[1]/th[@class='ark-header']/a").text
        @session.click_link(text)

        # Ensure that the guest collection has download access
        @session.click_link("Version 1")
        text = @session.find(:xpath, "//table[@class='properties'][2]/tbody/tr[1]/th[1]/a").text
        # the following does not work if there is a space in the filename
        @session.click_link(text)
        # print("#{@session.current_url}\n")
        expect(@session.current_url).to match(coll['file_redirect_match'])
      end
  
    end
  
    it 'Guest collections - no collection access' do
      skip 'no restricted coll (in docker ldap)' 

      get_config('non_guest_collections').each do |coll|
        @session.visit "/m/#{coll['coll']}"
        print(@session.title)
        expect(@session.title).to eq("Unauthorized (401)")
      end
  
    end
  end


  describe 'Authenticated access' do
    before(:each) do
      @session.visit '/'
      @session.within "header" do
        @session.find_link('Login')
        @session.click_link('Login')
      end
  
      @session.fill_in('login', with: get_config('login')[0]['user'])
      @session.fill_in('password', with: get_config('login')[0]['password'])
      @session.find('#submit_login').click
    end

    it 'Authenticated - file presigned download' do
      all_collections.each do |coll|
        @session.visit "/m/#{coll['coll']}"
        text = @session.find(:xpath, "//table[@class='main']/tbody/tr[1]/th[@class='ark-header']/a").text
        @session.click_link(text)

        @session.click_link("Version 1")
        text = @session.find(:xpath, "//table[@class='properties'][2]/tbody/tr[1]/th[1]/a").text

        # the following does not work if there is a space in the filename
        @session.click_link(text)
        # print("#{@session.current_url}\n")
        expect(@session.current_url).to match(coll['file_redirect_match'])
      end
    end

    describe "ingest files" do 
      def create_filename(n)
        "/tmp/#{n}"
      end

      def create_file(path)
        File.open(path, 'w') do |f| 
          f.write("test") 
          f.close
        end
        File.join(path)
      end

      def add_file(fname, prefix, seq)
        path = create_filename(fname)
        f = create_file(path)
        localid = "#{prefix}_#{seq}"
        title = localid

        @session.visit "/m/merritt_demo"
        @session.click_link('Add object')
        @session.find("input#file")
        @session.attach_file('File', f)
        @session.fill_in('title', with: title)
        @session.fill_in('local_id', with: localid)
        @session.find_button('Submit').click
        File.delete(f)
        @session.within("section h1") do
          expect(@session.text).to have_content("Submission Received")
        end
        sleep 5
      end

      @encfiles = {
        md: 'README.md',
        space: 'README 1.md',
        plus: 'README+1.md',
        percent: 'README %AF.md',
        accent: 'README cliché.md',
        pipe: 'README|pipe.md',
        slash: 'README/slash.md',
        backslash: 'README\slash.md',
        backslash_u: 'README\uslash.md',
        japanese_char: 'こんにちは.md',
        hebrew_char: 'שלום'
      }

      @encfiles.each do |file_key, file|
        describe ":ingest_#{file_key}" do
          it "ingest file #{file}" do
            add_file(file, Prefix.localid_prefix, file_key)
          end
        end
      end
  
      def check_file(fname, prefix, seq)
        localid = "#{prefix}_#{seq}"
        title = localid

        @session.visit "/m/merritt_demo"
        @session.fill_in('terms', with: localid)
        @session.find("input[name='commit']").click
        @session.within("section h1") do
          expect(@session.text).to have_content("Search Results")
        end
        text = @session.find(:xpath, "//table[@class='main']/tbody/tr[1]/th[@class='ark-header']/a").text
        @session.click_link(text)
        @session.within("section h2.object-title") do
          expect(@session.text).to have_content(title)
        end

        @session.find_link(fname)
        @session.click_link(fname)
        expect(@session.body.length).not_to eq(0)
      end

      @encfiles.each do |file_key, file|
        describe ":retrieve #{Prefix.localid_prefix}_#{file_key}" do
          it "retrieve file #{file}" do
            check_file(file, Prefix.localid_prefix, file_key)
          end
        end
      end

    end
  end

end
