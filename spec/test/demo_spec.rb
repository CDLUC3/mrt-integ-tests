# frozen_string_literal: true

require 'spec_helper'
# require 'webdrivers/chromedriver'
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
    `mkdir -p /tmp/uploads`
    Dir.chdir '/tmp/uploads'
  end

  after(:each) do
    end_web_session(@session)
  end

  it 'Verify that the Merritt UI home page is accessible' do
    @session.visit '/'
    @session.within('section.intro h1') do
      expect(@session.text).to have_content('A trusted, cost-effective digital preservation repository')
    end
  end

  it 'Verify short urls' do
    @session.visit '/docs'
    expect(@session.current_url).to eq('https://github.com/CDLUC3/mrt-doc/blob/main/README.md')
    @session.visit '/wiki'
    expect(@session.current_url).to eq('https://github.com/CDLUC3/mrt-doc/wiki')
    @session.visit '/presentations'
    expect(@session.current_url).to eq('https://github.com/CDLUC3/mrt-doc/blob/main/presentations/README.md')
  end

  describe 'Verify that a semantic version string is accessible in the Merritt UI footer' do
    it 'Print footer' do
      @session.visit '/'
      ver = 'Version undefined'
      ver = @session.find('span.version-number').text if @session.has_css?('span.version-number')
      puts("\tVersion: #{ver}")
    end
  end

  describe 'Enumerate test files' do
    it 'Print the test files to be used for ingest and retrieval tests -- based on -e INGEST_FILES' do
      puts("\tIngest Files:")
      TestObjectPrefix.test_files.each do |fk, file|
        puts("\t\t#{format('%-15s', fk)}\t#{file}")
      end
      puts('  Version Files:')
      TestObjectPrefix.version_files.each do |fk, file|
        puts("\t\t#{format('%-15s', fk)}\t#{file}")
      end
      puts('  Encoding zip:')
      TestObjectPrefix.encoding_zip_files.each do |fk, file|
        puts("\t\t#{format('%-15s', fk)}\t#{file}")
      end
      puts('  Manifests:')
      TestObjectPrefix.manifests.each do |m|
        puts("\t\t#{format('%-15s %5d: %s', m.fetch('coll', ''), m.fetch('count', 0), m.fetch('label', 0))}")
      end
    end
  end

  describe 'Check service states' do
    describe 'View state page - look for audit replic errors' do
      before(:each) do
        skip('The UI state endpoint does not yet provide audit and replic count information') unless @test_config.fetch(
          'ui_audit_replic', true
        )
        @session.visit '/state-audit-replic'
      end

      it 'From the UI state endpoint page, verify that no recent AUDIT errors have occurred' do
        skip('Audit counts are not verified in STAGE') unless @test_config.fetch(
          'check_audits', true
        )
        expect(@session.find('table.state tbody tr.audits td.error').text.to_i).to eq(0)
      end

      it 'From the UI state endpoint page, verify that no recent REPLICATION errors have occurred' do
        expect(@session.find('table.state tbody tr.replics td.error').text.to_i).to eq(0)
      end

      it 'From the UI state endpoint page, verify that AUDIT activity is occurring' do
        expect(@session.find('table.state tbody tr.audits td.total').text.to_i).to be > 0
      end
    end
  end

  describe 'Unauthenticated Access' do
    before(:each) do
      guest_login
    end

    it 'Verify that the Guest Login button succeeds in the Merritt UI' do
      # action defined in before action
    end

    it 'Verify that COLLECTIONS accessible to the Guest Login can be browsed' do
      guest_collections.each do |coll|
        visit_collection(coll)
      end
    end

    it 'Verify that OBJECTS accessible to the Guest Login can be browsed' do
      count = 0
      guest_collections.each do |coll|
        visit_collection(coll)
        next if get_object_count == 0

        count += 1

        visit_first_object
      end
    end

    it 'Verify that the JSON OBJECT_INFO page for an object accessible to the Guest Login can be retrieved' do
      count = 0
      guest_collections.each do |coll|
        visit_collection(coll)
        next if get_object_count == 0

        count += 1
        visit_first_object

        ark = @session.find('h1 span.key').text.gsub(/ -.*$/, '')
        json = json_rel_request(
          "api/object_info/#{ERB::Util.url_encode(ark)}",
          redirect: false,
          guest_credentials: true
        )
        expect(json.fetch('ark', '')).to eq(ark)
        expect(json.fetch('version_number', 0)).to be > 0
        expect(json.fetch('total_files', 0)).to be > 0
      end
    end

    it 'Verify that the JSON OBJECT_INFO page requires Guest Login' do
      count = 0
      guest_collections.each do |coll|
        visit_collection(coll)
        next if get_object_count == 0

        count += 1

        visit_first_object

        ark = @session.find('h1 span.key').text.gsub(/ -.*$/, '')
        expect do
          @session.find_link('JSON version')
        end.to raise_error(Capybara::ElementNotFound, 'Unable to find link "JSON version"')

        json = json_rel_request(
          "api/object_info/#{ERB::Util.url_encode(ark)}",
          redirect: false,
          guest_credentials: false
        )
        expect(json.fetch('ark', '')).to eq('')
      end
    end

    skip it 'Verify that a permalink is traversable for an object' do
      guest_collections.each do |coll|
        visit_collection(coll)
        next if get_object_count == 0

        visit_first_object
        expect(@session.text).to have_content('permanent link')
        @session.find(:xpath, "//th[contains(.,'permanent link:')]/parent::tr/td/a").click
        expect(@session.text).to have_content('ABOUT THE IDENTIFIER')
      end
    end

    it 'Verify that a VERSION PAGE for an object accessible to the Guest Login can be browsed' do
      count = 0
      guest_collections.each do |coll|
        visit_collection(coll)
        next if get_object_count == 0

        count += 1

        visit_first_object
        visit_first_version
      end
    end

    it 'Verify that a FILE for an object accessible to the Guest Login REDIRECTS to a presigned file retrieval' do
      count = 0
      guest_collections.each do |coll|
        visit_collection(coll)
        next if get_object_count == 0

        count += 1

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
        expect(@session).not_to have_selector 'h1 a'
      end
    end

    it 'Verify the CONTENT of a FILE for an object accessible to the Guest Login' do
      count = 0
      guest_collections.each do |coll|
        visit_collection(coll)
        next if get_object_count == 0

        count += 1

        visit_first_object
        visit_first_version
        visit_text_file(coll)
      end
    end

    it 'Verify that the GUEST login user cannot browse collections that are not authorized to the Guest login' do
      guest_collections_no_access.each do |coll|
        # visit_collection(guest_collections.first)
        visit_collection(coll)
        expect(@session.title).to eq('Unauthorized (401)')
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
        atomlink = @session.find('h1 a')
        expect(atomlink).not_to be(nil)
        atom = @session.find('h1 a')[:href]
        expect(atom).not_to be(nil)
        expect(atom).not_to eq('')
        xml = xml_request(atom, redirect: true)
        expect(xml).not_to be(nil)
        expect(xml.root).not_to be(nil)
        next unless @test_config.fetch(
          'expect_atom_content', false
        )

        expect(xml.root.xpath('//atom:entry',
          { atom: 'http://www.w3.org/2005/Atom' }).length).to be > 0
      end
    end

    it 'Verify the CONTENT of a FILE for an object in a collection NOT acessible to the GUEST login' do
      count = 0
      non_guest_collections.each do |coll|
        visit_collection(coll)
        next unless get_object_count > 0

        count += 1

        visit_first_object
        visit_first_version
        visit_text_file(coll)
      end
      expect(count).to be > 0
    end

    it "Verify the 'JSON version' links for authenticated users" do
      count = 0
      non_guest_collections.each do |coll|
        visit_collection(coll)
        next unless get_object_count > 0

        count += 1

        visit_first_object
        ark = @session.find('h1 span.key').text.gsub(/ -.*$/, '')
        @session.click_link('JSON version')
        json = JSON.parse(@session.text)

        expect(json.fetch('ark', '')).to eq(ark)
        expect(json.fetch('version_number', 0)).to be > 0
        expect(json.fetch('total_files', 0)).to be > 0
      end
      expect(count).to be > 0
    end

    describe 'ingest files' do
      before(:each) do
        skip('PREFIX supplied - rather than ingesting new content, objects from a prior ingest batch will be browsed') unless TestObjectPrefix.run_ingest
        skip('No non-guest collections supplied') if non_guest_collections.empty?
        coll = non_guest_collections.first
        visit_collection(coll)
        sleep 2
        @session.find_link('Add object')
      end

      after(:all) do
        if TestObjectPrefix.run_ingest && TestObjectPrefix.has_ingest
          sleep_label(TestObjectPrefix.sleep_time_ingest_global,
            'to allow ingests to complete')
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

          TestObjectPrefix.encoding_zip_files.each_value do |file|
            path = create_filename(file)
            f = create_file(path)
            cmd = "zip -j #{zippath} '#{file}'"
            `#{cmd}`
            File.delete(f)
          end

          # do a zip -l to count the number of files in the input
          sleep 3
          add_file(zippath, TestObjectPrefix.encoding_zip, TestObjectPrefix.localid_prefix,
            TestObjectPrefix.encoding_label)
          sleep 10
        end
      end
    end

    TestObjectPrefix.manifests.each do |m|
      describe "Ingest a manfiest of #{m.fetch('count', 0)} files into #{m.fetch('coll', 'na')}" do
        it 'Run Ingest' do
          (1..TestObjectPrefix.manifest_repeat).each do |rpt|
            @session.visit "/m/#{m.fetch('coll', 'na')}"
            sleep 2
            fname = '/tmp/manifest_gen.txt'
            File.open(fname, 'w') do |f|
              f.write("#%checkm_0.7\n")
              f.write("#%profile | http://uc3.cdlib.org/registry/ingest/manifest/mrt-single-file-batch-manifest\n")
              f.write("#%prefix | mrt: | http://merritt.cdlib.org/terms#\n")
              f.write("#%prefix | nfo: | http://www.semanticdesktop.org/ontologies/2007/03/22/nfo#\n")
              f.write("#%fields | nfo:fileUrl | nfo:hashAlgorithm | nfo:hashValue | nfo:fileSize | nfo:fileLastModified | nfo:fileName | mrt:primaryIdentifier | mrt:localIdentifier | mrt:creator | mrt:title | mrt:date\n")
  
              (1..m.fetch('count', 0)).each do |i|
                p = "#{m.fetch('label', 'label')}_#{format('%03d', i)}#{m.fetch('ext', '')}"
                digest = "#{m.fetch('md5', '')}" || ""
                cs = ""
                cs = "md5" if ! digest.empty?
                lid = "#{m.fetch('localid', '')}" || ""
  
                f.write("#{m.fetch('url',
                  'https://merritt.cdlib.org/robots.txt')} | #{cs} | #{digest} | | | #{p} | | #{lid} | autotest | Merritt Automated Test: #{p} |\n")
              end
              f.write("#%eof\n")
              f.close
            end
            @session.find_link('Add object')
  
            @session.click_link('Add object')
            @session.find('input#file')
            @session.attach_file('File', File.join(fname))
            @session.fill_in('title', with: m.fetch('label', 'na'))
            @session.find_button('Submit').click
            @session.find('section h1')
            @session.within('section h1') do
              expect(@session.text).to have_content('Submission Received')
            end
          end
        end
      end
    end

    describe 'Browse the OBJECT and FILES ingested as a part of ENCODING.ZIP' do
      if TestObjectPrefix.do_encoding_test

        before(:each) do
          skip('No non-guest collections supplied') if non_guest_collections.empty?
          coll = non_guest_collections.first
          visit_collection(coll)
          sleep 2
          @ark = check_file_obj_page_title(TestObjectPrefix.encoding_zip, TestObjectPrefix.localid_prefix,
            TestObjectPrefix.encoding_label)
        end

        TestObjectPrefix.encoding_zip_files.each_value do |file|
          it "Verify that a FILENAME with the following CHARACTERS can be retrieved from the object: #{file}" do
            find_file_on_version_page(file)
          end

          # Skip until the Apache issue is resolved
          it "Verify that a SINGLY/DOUBLY ENCODED FILENAME can be retrieved from the object: #{file}" do
            # skip("Encoding issue in progress") unless @test_config.fetch("experimental_tests", false)
            # Get raw ark, unencoded
            ark = @session.find('h1 span.key').text.gsub(/ -.*$/, '')

            @session.find_link('Version 1')
            @session.click_link('Version 1')
            # Get url used by the Merritt UI
            pageurl = @session.find_link(file)[:href].gsub(%r{^.*/api}, 'api')

            encark  = ERB::Util.url_encode(ark)
            encfile = ERB::Util.url_encode("producer/#{file}")
            single_encoded_url = "api/presign-file/#{encark}/1/#{encfile}"

            # Verify the re-application of the encoding in the Merritt UI
            double_encoded_nurl = "api/presign-file/#{ERB::Util.url_encode(encark)}/1/#{ERB::Util.url_encode(encfile)}"
            expect(double_encoded_nurl).to eq(pageurl)

            # Test the effect of sending a single-encoded URL to the Merritt UI
            @session.visit single_encoded_url
            expect(@session.text).to eq('test')
          end
        end

        it "Verify that the OBJECT CAN BE DOWNLOADED and that it contains ALL the files within ENCODING.ZIP: #{@ark}" do
          listing = perform_object_download("#{@ark}.zip")
          TestObjectPrefix.encoding_zip_files.each_value do |file|
            skip('Listing could not be generated') if listing.unicode_normalize.empty?
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
            skip('No non-guest collections supplied') if non_guest_collections.empty?
            coll = non_guest_collections.first
            visit_collection(coll)
            sleep 2
          end

          it "Verify browsing an OBJECT recently ingested with local id: #{local_id(TestObjectPrefix.localid_prefix,
            fk)}" do
            check_file_obj_page_title(@file, TestObjectPrefix.localid_prefix, @file_key)
          end

          it "Verify that a SPECIFIC FILE can be found on an OBJECT PAGE: #{file}" do
            check_file_obj_page_title(@file, TestObjectPrefix.localid_prefix, @file_key)
            @session.find_link(@file)
            @session.click_link(@file)
            validate_file_page
          end

          it "Verify that a SPECIFIC FILE can be found on a VERSION PAGE: #{file}" do
            check_file_obj_page_title(@file, TestObjectPrefix.localid_prefix, @file_key)
            find_file_on_version_page(@file)
          end

          it "Verify that a SPECIFIC FILE can be retrieved by URL construction: #{file}" do
            check_file_obj_page_title(@file, TestObjectPrefix.localid_prefix, @file_key)
          end

          it "Verify the OBJECT DOWNLOAD for a recently ingested object: #{fk}" do
            ark = check_file_obj_page_title(@file, TestObjectPrefix.localid_prefix, @file_key)
            listing = perform_object_download("#{ark}.zip")
            skip('Listing could not be generated') if listing.unicode_normalize.empty?
            expect(listing.unicode_normalize).to have_text(@file.unicode_normalize)
          end

          it "Verify AUDIT AND REPLIC stats for a recently ingested object: #{fk}" do
            ark = check_file_obj_page_title(@file, TestObjectPrefix.localid_prefix, @file_key).gsub('ark_', 'ark:/').gsub(
              '_', '/'
            )
            encark = ERB::Util.url_encode(ark)
            skip('ui_audit_replic endpoint not supported') unless @test_config.fetch('ui_audit_replic', true)
            @session.visit "/state/#{encark}/audit_replic"

            expect(@session.find('table.state tbody tr.audits td.error').text.to_i).to eq(0) if @test_config.fetch(
              'check_audits', true
            )
            expect(@session.find('table.state tbody tr.replics td.error').text.to_i).to eq(0)
            expect(@session.find('table.state tbody tr.audits td.total').text.to_i).to be > 0
            # if TestObjectPrefix.run_ingest
            #   expect(@session.find("table.state tbody tr.replics td.total").text.to_i).to be > 0
            # end
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
            skip('No non-guest collections supplied') if non_guest_collections.empty?
            coll = non_guest_collections.first
            visit_collection(coll)
            sleep 2
          end

          it "Verify browse of a RECENTLY INGESTED OBJECT with local id: #{local_id(TestObjectPrefix.localid_prefix,
            fk)}" do
            check_file_obj_page_title(@file, TestObjectPrefix.localid_prefix, @file_key)
          end

          it "Verify the presence of a TEST FILE on the OBJECT PAGE: #{file}" do
            check_file_obj_page_title(@file, TestObjectPrefix.localid_prefix, @file_key)
            @session.find_link(@file)
            expect(@session.find_link(@file).text).to eq(@file)
            @session.click_link(@file)
            validate_file_page
          end

          it "Verify the presence of a TEST FILE on the OBJECT PAGE: #{file}.v2" do
            check_file_obj_page_title(@file, TestObjectPrefix.localid_prefix, @file_key)
            @session.find_link("#{@file}.v2")
            expect(@session.find_link("#{@file}.v2").text).to eq("#{@file}.v2")
            @session.click_link("#{@file}.v2")
            validate_file_page
          end

          it "Verify the presence of a TEST FILE on the VERSION 1 PAGE: #{file}" do
            check_file_obj_page_title(@file, TestObjectPrefix.localid_prefix, @file_key)
            find_file_on_version_page(@file)
          end

          it "Verify the presence of both versions of a TEST FILE on the VERSION 2 PAGE: #{file}" do
            check_file_obj_page_title("#{@file}.v2", TestObjectPrefix.localid_prefix, @file_key)
            find_file_on_version_page(@file, version: 2)
          end

          it "Verify the presence of both versions of a TEST FILE on the VERSION 2 PAGE: #{file}.v2" do
            check_file_obj_page_title("#{@file}.v2", TestObjectPrefix.localid_prefix, @file_key)
            find_file_on_version_page("#{@file}.v2", version: 2)
          end

          it "Verify AUDIT AND REPLIC stats for a recently ingested and updated object #{fk}" do
            ark = check_file_obj_page_title(@file, TestObjectPrefix.localid_prefix, @file_key).gsub('ark_', 'ark:/').gsub(
              '_', '/'
            )
            encark = ERB::Util.url_encode(ark)
            skip('ui_audit_replic endpoint not supported') unless @test_config.fetch('ui_audit_replic', true)
            @session.visit "/state/#{encark}/audit_replic"

            expect(@session.find('table.state tbody tr.audits td.error').text.to_i).to eq(0)
            expect(@session.find('table.state tbody tr.replics td.error').text.to_i).to eq(0)
            # if @test_config.fetch("check_audits", true)
            #   expect(@session.find("table.state tbody tr.audits td.total").text.to_i).to be > 0
            # end
            # if TestObjectPrefix.run_ingest
            #   expect(@session.find("table.state tbody tr.replics td.total").text.to_i).to be > 0
            # end
          end
        end
      end
    end
  end
end
