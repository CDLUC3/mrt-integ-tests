require 'spec_helper.rb'
require 'webdrivers/chromedriver'
require 'cgi'
require_relative '../lib/test_prefix'

sleep 1

puts "#{TestObjectPrefix.integ_test_environment}: #{TestObjectPrefix.localid_prefix}"

RSpec.describe 'basic_merrit_ui_tests', type: :feature do

  before(:each) do
    @session = create_web_session
    %x[ mkdir -p /tmp/uploads ]
    Dir.chdir "/tmp/uploads"
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

  describe 'Get version from footer' do
    it 'Print footer' do
      @session.visit '/'
      ver = "Version undefined"
      if @session.has_css?("span.version-number")
        ver = @session.find("span.version-number").text
      end
      puts("\tVersion: #{ver}")
    end
  end

  describe 'Enumerate test files' do
    it 'Print test files' do
      puts("\tIngest Files:")
      TestObjectPrefix.test_files.each do |fk, file|
        puts("\t\t#{'%-15s' % fk}\t#{file}")
      end
      puts("  Version Files:")
      TestObjectPrefix.version_files.each do |fk, file|
        puts("\t\t#{'%-15s' % fk}\t#{file}")
      end
      puts("  Encoding zip:")
      TestObjectPrefix.encoding_zip_files.each do |fk, file|
        puts("\t\t#{'%-15s' % fk}\t#{file}")
      end
    end
  end

  describe 'Check storage service state' do
    it 'Check for valid storage nodes' do
      check_storage_state
    end
  end

  describe 'Check service states' do
    TestObjectPrefix.state_urls.split(",").each do |url|
      it "State endpoint returns data: #{url}" do
        check_service_state(url)
      end 

      it "State endpoint is active: #{url}" do
        check_state_active(check_service_state(url))
      end 

      it "Check build info: #{build_info_url(url)}" do
        skip("build.content.txt not yet enabled") if build_info_url(url).match(%r[(mrtstore|mrtaccess|mrtoai|mrtreplic)])
        skip("build.content.txt not yet enabled") if build_info_url(url).match(%r[\/(store|oai|replic)\/])
        tag = check_build_info(build_info_url(url))
        puts "\t\t#{tag}"
      end 
    
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

    it 'Browse to object_info page for first object' do
      guest_collections.each do |coll|
        visit_collection(coll)
        next if get_object_count == 0
        visit_first_object

        ark = @session.find("h1 span.key").text.gsub(/ -.*$/, '')
        json = json_rel_request("api/object_info/#{ERB::Util.url_encode(ark)}", false, true)
        expect(json.fetch("ark", "")).to eq(ark)
        expect(json.fetch("version_number", 0)).to be > 0
        expect(json.fetch("total_files", 0)).to be > 0
      end
    end

    it 'Browse to object_info page without credentials for first object' do
      guest_collections.each do |coll|
        visit_collection(coll)
        next if get_object_count == 0
        visit_first_object

        ark = @session.find("h1 span.key").text.gsub(/ -.*$/, '')
        json = json_rel_request("api/object_info/#{ERB::Util.url_encode(ark)}", false, false)
        expect(json.fetch("ark", "")).to eq("")
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

    it 'Browse to atom feed' do
      guest_collections.each do |coll|
        visit_collection(coll)
        atomlink = @session.find("h1 a")
        expect(atomlink).not_to be(nil) 
        atom = @session.find("h1 a")[:href]
        expect(atom).not_to be(nil) 
        expect(atom).not_to eq("")
        xml = xml_request(atom, true, true) 
        expect(xml).not_to be(nil)
        expect(xml.root).not_to be(nil)
        expect(xml.root.xpath("//atom:entry", {atom:'http://www.w3.org/2005/Atom'}).length).to be > 0
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

    describe 'ingest files' do 
      before(:each) do
        skip("PREFIX supplied - this substitutes for the ingest") unless ENV.fetch('PREFIX', '').empty?
        skip("No non-guest collections supplied") if non_guest_collections.length == 0
        coll = non_guest_collections.first
        visit_collection(coll)
        sleep 2
        @session.find_link("Add object")
      end

      after(:all) do
        if ENV.fetch('PREFIX', '').empty?
          sleep_label(TestObjectPrefix.sleep_time_ingest_global, "to allow ingests to complete") if TestObjectPrefix.has_ingest
        end
      end

      TestObjectPrefix.test_files.each do |fk, file|
        describe "ingest file with key #{fk}" do 
          it "Ingest #{file}" do
            upload_regular_file(fk)
          end
        end
      end

      TestObjectPrefix.version_files.each do |fk, file|
        describe "create versioned object with key #{fk}" do 
          it "Ingest V1 for #{file}" do
            upload_v1_file(fk)
          end
        end
      end

      TestObjectPrefix.version_files.each do |fk, file|
        describe "update versioned object with key #{fk}" do 
          it "Ingest V2 for #{file}" do
            update_v2_file(fk)
          end
        end
      end

      if TestObjectPrefix.do_encoding_test
        it "Ingest zip file with encoding use cases" do
          zippath = "/tmp/uploads/#{TestObjectPrefix.encoding_zip}"
        
          TestObjectPrefix.encoding_zip_files.each do |fk, file|
            path = create_filename(file)
            f = create_file(path)
            cmd = "zip -j #{zippath} '#{file}'"
            %x[ #{cmd} ]
            File.delete(f)
          end
  
          # do a zip -l to count the number of files in the input
          sleep 3
          add_file(zippath, TestObjectPrefix.encoding_zip, TestObjectPrefix.localid_prefix, TestObjectPrefix.encoding_label)
          sleep 10
        end
      end
    end

    describe 'browse objects/files ingested in encoding.zip(combo)' do
      if TestObjectPrefix.do_encoding_test

        before(:each) do
          skip("No non-guest collections supplied") if non_guest_collections.length == 0
          coll = non_guest_collections.first
          visit_collection(coll)
          sleep 2
          @ark = check_file_obj_page(TestObjectPrefix.encoding_zip, TestObjectPrefix.localid_prefix, TestObjectPrefix.encoding_label)
        end

        TestObjectPrefix.encoding_zip_files.each do |fk, file|
          it "Test file link from version page: #{file}" do
            find_file_on_version_page(file)
          end    

          # Skip until the Apache issue is resolved
          it "Test file link single-encoding from version page: #{file}" do
            # skip("Encoding issue in progress") unless @test_config.fetch("experimental_tests", false)
            # Get raw ark, unencoded
            ark = @session.find("h1 span.key").text.gsub(/ -.*$/, '')

            @session.find_link('Version 1')
            @session.click_link('Version 1')
            # Get url used by the Merritt UI
            pageurl = @session.find_link(file)[:href].gsub(/^.*\/api/, 'api')

            encark  = ERB::Util.url_encode(ark)
            encfile = ERB::Util.url_encode("producer/#{file}")
            single_encoded_url = "api/presign-file/#{encark}/1/#{encfile}"

            # Verify the re-application of the encoding in the Merritt UI
            double_encoded_nurl = "api/presign-file/#{ERB::Util.url_encode(encark)}/1/#{ERB::Util.url_encode(encfile)}"
            expect(double_encoded_nurl).to eq(pageurl)

            # Test the effect of sending a single-encoded URL to the Merritt UI
            @session.visit single_encoded_url
            expect(@session.text).to eq("test")
          end
        end

        it "Test object download: #{@ark}" do
          listing = perform_object_download("#{@ark}.zip")
          TestObjectPrefix.encoding_zip_files.each do |fk, file|
            expect(listing.unicode_normalize).to have_text(file.unicode_normalize)
          end
        end    
      end
    end

    describe 'browse objects/files ingested individually' do
      TestObjectPrefix.test_files.each do |fk, file|
        describe "search for object with #{local_id(TestObjectPrefix.localid_prefix, fk)}" do 
  
          before(:each) do
            @file = file
            @file_key = fk
            skip("No non-guest collections supplied") if non_guest_collections.length == 0
            coll = non_guest_collections.first
            visit_collection(coll)
            sleep 2
          end

          it "Search for recently ingested object's local id: #{local_id(TestObjectPrefix.localid_prefix, fk)}" do
            check_file_obj_page(@file, TestObjectPrefix.localid_prefix, @file_key)
          end    
  
          it "Search for test file on object page: #{file}" do
            check_file_obj_page(@file, TestObjectPrefix.localid_prefix, @file_key)
            @session.find_link(@file)
            @session.click_link(@file)
            validate_file_page
          end    
  
          it "Search for test file on object version page: #{file}" do
            check_file_obj_page(@file, TestObjectPrefix.localid_prefix, @file_key)
            find_file_on_version_page(@file)
          end    

          it "Retrieve file #{file} by URL construction" do
            check_file_obj_page(@file, TestObjectPrefix.localid_prefix, @file_key)
          end    

          it "Start download object for recently ingested object: #{fk}" do
            ark = check_file_obj_page(@file, TestObjectPrefix.localid_prefix, @file_key)
            listing = perform_object_download("#{ark}.zip")
            expect(listing.unicode_normalize).to have_text(@file.unicode_normalize)
          end    
        end
      end
    end

    describe 'browse versioned ingested individually' do
      TestObjectPrefix.version_files.each do |fk, file|
        describe "search for object with #{local_id(TestObjectPrefix.localid_prefix, fk)}" do 
  
          before(:each) do
            @file = file
            @file_key = fk
            skip("No non-guest collections supplied") if non_guest_collections.length == 0
            coll = non_guest_collections.first
            visit_collection(coll)
            sleep 2
          end

          it "Search for recently ingested object's local id: #{local_id(TestObjectPrefix.localid_prefix, fk)}" do
            check_file_obj_page(@file, TestObjectPrefix.localid_prefix, @file_key)
          end    
  
          it "Search for test file on object page: #{file}" do
            check_file_obj_page(@file, TestObjectPrefix.localid_prefix, @file_key)
            @session.find_link(@file)
            @session.click_link(@file)
            validate_file_page
          end    
  
          it "Search for test file on object version page: #{file}" do
            check_file_obj_page(@file, TestObjectPrefix.localid_prefix, @file_key)
            find_file_on_version_page(@file)
          end    

          it "Retrieve file #{file} by URL construction" do
            check_file_obj_page(@file, TestObjectPrefix.localid_prefix, @file_key)
          end    

          it "Search for V2 test file on object version page: #{file}.v2" do
            check_file_obj_page("#{@file}.v2", TestObjectPrefix.localid_prefix, @file_key)
            find_file_on_version_page(@file)
          end    

          it "Retrieve V2 file #{file}.v2 by URL construction" do
            check_file_obj_page("#{@file}.v2", TestObjectPrefix.localid_prefix, @file_key)
          end    
        end
      end
    end

  end

  describe 'Manual follow up' do
    it 'Check the "Recent Audit and Replication Issues" report in the Collection Admin Tool to look for audit or replication failures' do
    end
  end
end
