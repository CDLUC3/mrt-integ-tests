require 'spec_helper.rb'
require 'webdrivers/chromedriver'
require 'cgi'
require_relative '../lib/test_prefix'

sleep 1

puts "#{TestObjectPrefix.integ_test_environment}: #{TestObjectPrefix.localid_prefix}"

RSpec.describe 'basic_merrit_ui_tests', type: :feature do

  before(:each) do
    @session = create_web_session(TestObjectPrefix.config_file)
    Dir.chdir "/tmp"
  end

  after(:each) do
    end_web_session(@session)
  end

  it 'View home page - Merritt Landing Page' do
    @session.visit '/'
    @session.within("section.intro h1") do
      expect(@session.text).to have_content("A trusted, cost-effective digital preservation repository")
    end
  end

  describe 'Unauthenticated Access' do
    before(:each) do
      guest_login
    end
  
    it 'Perform Merritt Guest Login' do
    end

    it 'Open guest collections' do
      guest_collections.each do |coll|
        visit_collection(coll)
      end
    end

    it 'Browse to first object' do
      guest_collections.each do |coll|
        visit_collection(coll)
        next if get_object_count == 0
        visit_first_object
      end
    end
  
    it 'Browse to first version' do
      guest_collections.each do |coll|
        visit_collection(coll)
        next if get_object_count == 0
        visit_first_object
        visit_first_version
      end
    end

    it 'Browse to first file' do
      guest_collections.each do |coll|
        visit_collection(coll)
        next if get_object_count == 0
        visit_first_object
        visit_first_version
        visit_first_file
        # the following will not succeed if the content type triggers a dowload
        expect(@session.current_url).to match(coll['file_redirect_match'])
      end
    end

    it 'Browse to system text file and validate presigned url' do
      guest_collections.each do |coll|
        visit_collection(coll)
        next if get_object_count == 0
        visit_first_object
        visit_first_version
        visit_text_file(coll)
      end
    end

    it 'Guest collections - no collection access' do
      guest_collections_no_access.each do |coll|
        visit_collection(coll)
        expect(@session.title).to eq("Unauthorized (401)")
      end  
    end
  end


  describe 'Authenticated access' do
    before(:each) do
      authenticated_login
    end

    it 'Authenticated - file presigned download' do
      non_guest_collections.each do |coll|
        visit_collection(coll)
        if get_object_count > 0
          visit_first_object
          visit_first_version
          visit_text_file(coll)
          end
      end
    end

    describe "ingest and download files" do 
      before(:each) do
        @file = "test_file.txt"
        @file_key =  "text"
        skip if non_guest_collections.length == 0
        coll = non_guest_collections.first
        visit_collection(coll)
        sleep 2
      end

      it 'Confirm add object link' do
        @session.find_link("Add object")
      end

      it 'Ingest Text File with unique local id' do
        if @file_key.end_with?('_z')
          upload_zip_file(@file, TestObjectPrefix.localid_prefix, @file_key)
        else
          upload_regular_file(@file, TestObjectPrefix.localid_prefix, @file_key)                
        end
      end

      it "Search for recently ingested object's local id" do
        check_file_obj_page(@file, TestObjectPrefix.localid_prefix, @file_key)
      end    

      it "Search for test file on object page" do
        check_file_obj_page(@file, TestObjectPrefix.localid_prefix, @file_key)
        @session.find_link(@file)
        @session.click_link(@file)
        expect(@session.body.length).not_to eq(0)
      end    

      it "Search for test file on object version page" do
        check_file_obj_page(@file, TestObjectPrefix.localid_prefix, @file_key)
        @session.find_link('Version 1')
        @session.click_link('Version 1')
        @session.find_link(@file)
        @session.click_link(@file)
        expect(@session.body.length).not_to eq(0)
      end    

      it "Start download object for recently ingested object" do
        ark = check_file_obj_page(@file, TestObjectPrefix.localid_prefix, @file_key)
        @session.find_button('Download object')
        @session.click_button('Download object')
      
        sleep 2
      
        @session.find('div.ui-dialog')
        @session.within('.ui-dialog-title') do
          expect(@session.text).to have_content('Preparing Object for Download')
        end
      
        sleep_label(sleep_time_assemble, "to allow assembly to complete")
      
        @session.within('.ui-dialog-title') do
          expect(@session.text).to have_content('Object is ready for Download')
        end
      
        sleep_label(sleep_time_download, "to allow download to complete")
      
        @session.find('a.obj_download').click
        cmd = "bsdtar tf #{ark}.zip|grep producer"
        listing = %x[ #{cmd} ]
        File.delete("#{ark}.zip")
        expect(listing.unicode_normalize).to have_text(@file.unicode_normalize)
      end    
    end
  end

end
