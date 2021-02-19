class TestObjectPrefix
    @@localid_prefix = Time.new.strftime('%Y_%m_%d_%H%M')
    @@config_file = File.join(Dir.getwd, 'config', 'test_config.yml')
    @@integenv = ENV.fetch('INTEG_TEST_ENV', 'default')
    @@config = Uc3Ssm::ConfigResolver.new({
      def_value: 'N/A' 
    }).resolve_file_values({
      file: @@config_file, 
      return_key: @@integenv
    })
  
    def self.localid_prefix
      @@localid_prefix
    end
  
    def self.set_prefix(prefix)
      @@localid_prefix = prefix
    end
  
    def self.integ_test_environment
      @@integenv
    end

    def self.get_yaml_config
      @@config
    end

    def self.test_files
      key = ENV.fetch('INGEST_FILES', 'default')
      files = @@config.fetch('test-files', {})
              .fetch(key, {})
      return {} if files.nil?
      files
    end

    def self.sleep_time_ingest_global
      files = @@config.fetch('sleep-times', {}).fetch('ingest', 10).to_i
    end
  end