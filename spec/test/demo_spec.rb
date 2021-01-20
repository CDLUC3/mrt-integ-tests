require 'spec_helper.rb'
require 'webdrivers/chromedriver'
require 'cgi'
require_relative '../lib/test_prefix'

sleep 1

puts TestObjectPrefix.localid_prefix

RSpec.describe 'basic_merrit_ui_tests', type: :feature do
  def get_object_count
    @session.all(:xpath, "//table[@class='main']/tbody/tr/th[@class='ark-header']").count
  end

  def get_first_ark
    @session.find(:xpath, "//table[@class='main']/tbody/tr[1]/th[@class='ark-header']/a").text
  end

  def get_first_user_file
    @session.find(:xpath, "//table[@class='properties'][2]/tbody/tr[1]/th[1]/a").text
  end

  before(:each) do
    @session = create_web_session(TestObjectPrefix.config_file)
    Dir.chdir "/tmp"
  end

  after(:each) do
    end_web_session(@session)
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
        if get_object_count > 0
          text = get_first_ark
          @session.click_link(text)
  
          # Ensure that the guest collection has download access
          @session.click_link("Version 1")
          text = get_first_user_file
          # the following does not work if there is a space in the filename
          @session.click_link(text)
          # print("#{@session.current_url}\n")
          expect(@session.current_url).to match(coll['file_redirect_match'])
        end
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
        if get_object_count > 0
          text = get_first_ark
          @session.click_link(text)
  
          @session.click_link("Version 1")
          text = get_first_user_file
  
          # the following does not work if there is a space in the filename
          @session.click_link(text)
          # print("#{@session.current_url}\n")
          expect(@session.current_url).to match(coll['file_redirect_match'])
        end
      end
    end

    describe "ingest and download files" do 
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

      def upload_regular_file(fname, prefix, seq)
        path = create_filename(fname)
        f = create_file(path)
        add_file(f, fname, prefix, seq)
      end

      def upload_zip_file(fname, prefix, seq)
        path = create_filename(fname)
        zippath = '/tmp/upload.zip'
        f = create_file(path)
        cmd = "zip #{zippath} '#{path}'"
        %x[ #{cmd} ]
        File.delete(f)
        add_file(zippath, fname, prefix, seq)
      end

      def add_file(f, fname, prefix, seq)
        localid = "#{prefix}_#{seq}"
        title = "#{localid} #{fname}"

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
        stime = sleep_time_ingest
        puts "\t -- sleep #{stime} (to allow ingests to complete)"
        sleep stime
      end

  
      def check_file_obj_page(fname, prefix, seq)
        localid = "#{prefix}_#{seq}"
        title = "#{localid} #{fname}"

        @session.visit "/m/merritt_demo"
        @session.fill_in('terms', with: localid)
        @session.find("input[name='commit']").click
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

      encoding_usecases.each do |fk, file|
        encoding_variations(fk).each do |file_key| 
          describe "#{TestObjectPrefix.localid_prefix}_#{file_key}: #{file}" do
            it "ingest file #{file}" do
              if file_key.end_with?('_z')
                upload_zip_file(file, TestObjectPrefix.localid_prefix, file_key)
              else
                upload_regular_file(file, TestObjectPrefix.localid_prefix, file_key)                
              end
            end

            it "retrieve file from obj page: #{file}" do
              check_file_obj_page(file, TestObjectPrefix.localid_prefix, file_key)
              @session.find_link(file)
              @session.click_link(file)
              expect(@session.body.length).not_to eq(0)
            end
  
            it "retrieve file from ver page: #{file}" do
              check_file_obj_page(file, TestObjectPrefix.localid_prefix, file_key)
              @session.find_link('Version 1')
              @session.click_link('Version 1')
              @session.find_link(file)
              @session.click_link(file)
              expect(@session.body.length).not_to eq(0)
            end
   
            it "download object" do
              ark = check_file_obj_page(file, TestObjectPrefix.localid_prefix, file_key)
              @session.find_button('Download object')
              @session.click_button('Download object')
  
              sleep 2

              @session.find('div.ui-dialog')
              @session.within('.ui-dialog-title') do
                expect(@session.text).to have_content('Preparing Object for Download')
              end

              stime = sleep_time_assemble
              puts "\t -- sleep #{stime} (to allow assembly to complete)"
              sleep stime

              @session.within('.ui-dialog-title') do
                expect(@session.text).to have_content('Object is ready for Download')
              end

              sleep sleep_time_download

              @session.find('a.obj_download').click
              cmd = "bsdtar tf #{ark}.zip|grep producer"
              listing = %x[ #{cmd} ]
              File.delete("#{ark}.zip")
              expect(listing.unicode_normalize).to have_text(file.unicode_normalize)
            end
          end
        end
      end
    end
  end

end
