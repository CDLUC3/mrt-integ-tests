require 'spec_helper.rb'
require 'webdrivers/chromedriver'
require 'cgi'
require_relative '../lib/test_prefix'

sleep 1

puts "#{TestObjectPrefix.integ_test_environment}: #{TestObjectPrefix.localid_prefix}"

RSpec.describe 'basic_merrit_ui_tests', type: :feature do

  before(:all) do
    @sem_versions = {}
  end

  before(:each) do
    @session = create_web_session
    %x[ mkdir -p /tmp/uploads ]
    Dir.chdir "/tmp/uploads"
  end

  after(:each) do
    end_web_session(@session)
  end

  it 'Verify that the Merritt UI home page is accessible' do
    @session.visit '/'
    @session.within("section.intro h1") do
      expect(@session.text).to have_content("A trusted, cost-effective digital preservation repository")
    end
  end

  describe 'Verify that a semantic version string is accessible in the Merritt UI footer' do
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
    it 'Print the test files to be used for ingest and retrieval tests -- based on -e INGEST_FILES' do
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
    it 'Invoke the storage state command for each storage node -- this tests the accessibility of each cloud service used by Merritt' do
      check_storage_state
    end
  end

  describe 'Check service states' do
    TestObjectPrefix.state_urls.split(",").each do |url|
      it "Verify that the microservice STATE endpoint returns a successful response: #{url}" do
        skip("STATE endpoint is not yet supported for this microservice") unless has_service_state(url)
        check_service_state(url)
      end 

      it "Using the STATE endpoint response, verify that processing is not frozen for the micorservice: #{url}" do
        skip("STATE endpoint is not yet supported for this microservice") unless has_service_state(url)
        check_state_active(check_service_state(url))
      end 

      it "Extract microservice build info (build.content.txt for java microservices): #{build_info_url(url)}" do
        skip("Microservice build info endpoint is not yet enabled") unless has_build_info(url)
        service = get_service(url)
        tag = check_build_info(build_info_url(url))
        exp_tag = @sem_versions.fetch(service, "")
        puts "\t\t#{tag}"
        expect(exp_tag).to eq(tag) unless exp_tag.empty?
        @sem_versions[service] = tag
      end 
    
    end

    describe 'View state page - look for audit replic errors' do
      before(:each) do
        skip("The UI state endpoint does not yet provide audit and replic count information") unless @test_config.fetch("ui_audit_replic", true)
        @session.visit '/state-audit-replic'
      end
 
      it "From the UI state endpoint page, verify that no recent AUDIT errors have occurred" do
        skip("Audit counts are not verified within this environment -- stage has known checksum errors") unless @test_config.fetch("check_audits", true)
        expect(@session.find("table.state tbody tr.audits td.error").text.to_i).to eq(0)
      end

      it "From the UI state endpoint page, verify that no recent REPLICATION errors have occurred" do
        expect(@session.find("table.state tbody tr.replics td.error").text.to_i).to eq(0)
      end

      it "From the UI state endpoint page, verify that AUDIT activity is occurring" do
        expect(@session.find("table.state tbody tr.audits td.total").text.to_i).to be > 0
      end
    end
  
  end

  describe 'Check service states via load balancers' do
    TestObjectPrefix.state_urls_lb.split(",").each do |url|
      it "Verify that the STATE endpoint is accessible and successful when invoked from a load balancer: #{url}" do
        skip("state unsupported") unless has_service_state(url)
        check_service_state(url, true)
      end 
    
    end
  end

  describe 'Unauthenticated Access' do
    before(:each) do
      guest_login
    end
  
    it 'Verify that the Guest Login button succeeds in the Merritt UI' do
    end

    it 'Verify that COLLECTIONS accessible to the Guest Login can be browsed' do
      guest_collections.each do |coll|
        visit_collection(coll)
      end
    end

    it 'Verify that OBJECTS accessible to the Guest Login can be browsed' do
      guest_collections.each do |coll|
        visit_collection(coll)
        next if get_object_count == 0
        visit_first_object
      end
    end

    it 'Verify that the JSON OBJECT_INFO page for an object accessible to the Guest Login can be retrieved' do
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

    it 'Verify that the JSON OBJECT_INFO page for an object accessible to the Guest Login CANNOT be retrieved IF the user is not logged in' do
      guest_collections.each do |coll|
        visit_collection(coll)
        next if get_object_count == 0
        visit_first_object

        ark = @session.find("h1 span.key").text.gsub(/ -.*$/, '')
        json = json_rel_request("api/object_info/#{ERB::Util.url_encode(ark)}", false, false)
        expect(json.fetch("ark", "")).to eq("")
      end
    end

    it 'Verify that a permalink is traversable for an object' do
      guest_collections.each do |coll|
        visit_collection(coll)
        next if get_object_count == 0
        visit_first_object
        expect(@session.text).to have_content("permanent link")
        @session.find(:xpath, "//th[contains(.,'permanent link:')]/parent::tr/td/a").click
        expect(@session.text).to have_content("ABOUT THE IDENTIFIER")
      end
    end

    it 'Verify that a VERSION PAGE for an object accessible to the Guest Login can be browsed' do
      guest_collections.each do |coll|
        visit_collection(coll)
        next if get_object_count == 0
        visit_first_object
        visit_first_version
      end
    end

    it 'Verify that a FILE for an object accessible to the Guest Login REDIRECTS to a presigned file retrieval' do
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

    it 'Verify that the ATOM FEED for a collection is not accessible to Guest User' do
      guest_collections.each do |coll|
        visit_collection(coll)
        expect(@session).not_to have_selector "h1 a"
      end
    end

    it 'Verify the CONTENT of a FILE for an object accessible to the Guest Login' do
      guest_collections.each do |coll|
        visit_collection(coll)
        next if get_object_count == 0
        visit_first_object
        visit_first_version
        visit_text_file(coll)
      end
    end

    it 'Verify that the GUEST login user cannot browse collections that are not authorized to the Guest login' do
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

    it 'Verify that the ATOM FEED for a collection can be browsed' do
      non_guest_collections.each do |coll|
        visit_collection(coll)
        atomlink = @session.find("h1 a")
        expect(atomlink).not_to be(nil) 
        atom = @session.find("h1 a")[:href]
        expect(atom).not_to be(nil) 
        expect(atom).not_to eq("")
        xml = xml_request(atom, true) 
        expect(xml).not_to be(nil)
        expect(xml.root).not_to be(nil)
        expect(xml.root.xpath("//atom:entry", {atom:'http://www.w3.org/2005/Atom'}).length).to be > 0 if @test_config.fetch("expect_atom_content", false)
      end
    end

    it 'Verify the CONTENT of a FILE for an object in a collection NOT acessible to the GUEST login' do
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
        skip("PREFIX supplied - rather than ingesting new content, objects from a prior ingest batch will be browsed") unless TestObjectPrefix.run_ingest
        skip("No non-guest collections supplied") if non_guest_collections.length == 0
        coll = non_guest_collections.first
        visit_collection(coll)
        sleep 2
        @session.find_link("Add object")
      end

      after(:all) do
        if TestObjectPrefix.run_ingest
          sleep_label(TestObjectPrefix.sleep_time_ingest_global, "to allow ingests to complete") if TestObjectPrefix.has_ingest
        end
      end

      TestObjectPrefix.test_files.each do |fk, file|
        describe "Ingest a SINGLE FILE as a new object using the following PREFIX as part of its local_id: #{fk}" do 
          it "Verify that the following file can be ingested into a collection: #{file}" do
            upload_regular_file(fk)
          end
        end
      end

      TestObjectPrefix.version_files.each do |fk, file|
        describe "Create VERSION 1 of an object using the following PREFIX as part of its local_id:  #{fk}" do 
          it "Verify that VERSION 1 can be ingested for the following file: #{file}" do
            upload_v1_file(fk)
          end
        end
      end

      TestObjectPrefix.version_files.each do |fk, file|
        describe "Create VERSION 2 of an object using the following PREFIX as part of its local_id: #{fk}" do 
          it "Verify that VERSION 2 can be ingested for the following file: #{file}" do
            update_v2_file(fk)
          end
        end
      end

      if TestObjectPrefix.do_encoding_test
        it "Verify that a ZIP FILE named 'encoding.zip' containing multiple files can be ingested into an object" do
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

    describe 'Browse the OBJECT and FILES ingested as a part of ENCODING.ZIP' do
      if TestObjectPrefix.do_encoding_test

        before(:each) do
          skip("No non-guest collections supplied") if non_guest_collections.length == 0
          coll = non_guest_collections.first
          visit_collection(coll)
          sleep 2
          @ark = check_file_obj_page(TestObjectPrefix.encoding_zip, TestObjectPrefix.localid_prefix, TestObjectPrefix.encoding_label)
        end

        TestObjectPrefix.encoding_zip_files.each do |fk, file|
          it "Verify that a FILENAME with the following CHARACTERS can be retrieved from the object: #{file}" do
            find_file_on_version_page(file)
          end    

          # Skip until the Apache issue is resolved
          it "Verify that a SINGLY ENCODED or DOUBLY ENCODED FILENAME with the following CHARACTERS can be retrieved from the object: #{file}" do
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

        it "Verify that the OBJECT CAN BE DOWNLOADED and that it contains ALL the files within ENCODING.ZIP: #{@ark}" do
          listing = perform_object_download("#{@ark}.zip")
          TestObjectPrefix.encoding_zip_files.each do |fk, file|
            skip("Listing could not be generated") if listing.unicode_normalize.empty?
            expect(listing.unicode_normalize).to have_text(file.unicode_normalize)
          end
        end    
      end
    end

    describe 'Browse Objects ingested from a SINGLE FILE' do
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

          it "Verify browsing an OBJECT recently ingested with local id: #{local_id(TestObjectPrefix.localid_prefix, fk)}" do
            check_file_obj_page(@file, TestObjectPrefix.localid_prefix, @file_key)
          end    
  
          it "Verify that a SPECIFIC FILE can be found on an OBJECT PAGE: #{file}" do
            check_file_obj_page(@file, TestObjectPrefix.localid_prefix, @file_key)
            @session.find_link(@file)
            @session.click_link(@file)
            validate_file_page
          end    
  
          it "Verify that a SPECIFIC FILE can be found on a VERSION PAGE: #{file}" do
            check_file_obj_page(@file, TestObjectPrefix.localid_prefix, @file_key)
            find_file_on_version_page(@file)
          end    

          it "Verify that a SPECIFIC FILE can be retrieved by URL construction: #{file}" do
            check_file_obj_page(@file, TestObjectPrefix.localid_prefix, @file_key)
          end    

          it "Verify the OBJECT DOWNLOAD for a recently ingested object: #{fk}" do
            ark = check_file_obj_page(@file, TestObjectPrefix.localid_prefix, @file_key)
            listing = perform_object_download("#{ark}.zip")
            skip("Listing could not be generated") if listing.unicode_normalize.empty?
            expect(listing.unicode_normalize).to have_text(@file.unicode_normalize)
          end

          it "Verify AUDIT AND REPLIC stats for a recently ingested object: #{fk}" do
            ark = check_file_obj_page(@file, TestObjectPrefix.localid_prefix, @file_key).gsub(%r[ark_], 'ark:/').gsub(%r[_], '/')
            encark  = ERB::Util.url_encode(ark)
            skip("ui_audit_replic endpoint not supported") unless @test_config.fetch("ui_audit_replic", true)
            @session.visit "/state/#{encark}/audit_replic"

            expect(@session.find("table.state tbody tr.audits td.error").text.to_i).to eq(0) if @test_config.fetch("check_audits", true)
            expect(@session.find("table.state tbody tr.replics td.error").text.to_i).to eq(0)
            expect(@session.find("table.state tbody tr.audits td.total").text.to_i).to be > 0 
            # expect(@session.find("table.state tbody tr.replics td.total").text.to_i).to be > 0 if TestObjectPrefix.run_ingest
          end
        end
      end
    end

    describe 'Browse Objects recently INGESTED and UPDATED (VERSIONED)' do
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

          it "Verify browse of a RECENTLY INGESTED OBJECT with local id: #{local_id(TestObjectPrefix.localid_prefix, fk)}" do
            check_file_obj_page(@file, TestObjectPrefix.localid_prefix, @file_key)
          end    
  
          it "Verify the presence of a TEST FILE on the OBJECT PAGE: #{file}" do
            check_file_obj_page(@file, TestObjectPrefix.localid_prefix, @file_key)
            @session.find_link(@file)
            @session.click_link(@file)
            validate_file_page
          end    
  
          it "Verify the presence of a TEST FILE on the VERSION 1 PAGE: #{file}" do
            check_file_obj_page(@file, TestObjectPrefix.localid_prefix, @file_key)
            find_file_on_version_page(@file)
          end    

          it "Verify the RETRIEVAL OF VERSION 1 of A TEST FILE #{file} by URL construction" do
            check_file_obj_page(@file, TestObjectPrefix.localid_prefix, @file_key)
          end    

          it "Verify the presence of a TEST FILE on the VERSION 2 PAGE: #{file}.v2" do
            check_file_obj_page("#{@file}.v2", TestObjectPrefix.localid_prefix, @file_key)
            find_file_on_version_page(@file)
          end    

          it "Verify the RETRIEVAL OF VERSION 2 of A TEST FILE #{file}.v2 by URL construction" do
            check_file_obj_page("#{@file}.v2", TestObjectPrefix.localid_prefix, @file_key)
          end    

          it "Verify AUDIT AND REPLIC stats for a recently ingested and updated object #{fk}" do
            ark = check_file_obj_page(@file, TestObjectPrefix.localid_prefix, @file_key).gsub(%r[ark_], 'ark:/').gsub(%r[_], '/')
            encark  = ERB::Util.url_encode(ark)
            skip("ui_audit_replic endpoint not supported") unless @test_config.fetch("ui_audit_replic", true)
            @session.visit "/state/#{encark}/audit_replic"

            expect(@session.find("table.state tbody tr.audits td.error").text.to_i).to eq(0)
            expect(@session.find("table.state tbody tr.replics td.error").text.to_i).to eq(0)
            # expect(@session.find("table.state tbody tr.audits td.total").text.to_i).to be > 0 if @test_config.fetch("check_audits", true)
            # expect(@session.find("table.state tbody tr.replics td.total").text.to_i).to be > 0 if TestObjectPrefix.run_ingest
          end
        end
      end
    end

  end

end
