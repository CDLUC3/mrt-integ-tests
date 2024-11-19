# frozen_string_literal: true

class TestObjectPrefix
  @@localid_prefix = ENV.fetch('PREFIX', Time.new.strftime('%Y_%m_%d_%H%M')) unless defined? @@localid_prefix
  @@config_file = File.join(Dir.getwd, 'config', 'test_config.yml') unless defined? @@config_file
  @@integenv = ENV.fetch('INTEG_TEST_ENV', 'default') unless defined? @@integenv
  unless defined? @@config
    @@config = Uc3Ssm::ConfigResolver.new(
      def_value: 'N/A'
    ).resolve_file_values(
      file: @@config_file,
      return_key: @@integenv
    )
  end

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
      .fetch('ingest-files', {})
    return {} if files.nil?

    files
  end

  def self.version_files
    key = ENV.fetch('INGEST_FILES', 'default')
    files = @@config.fetch('test-files', {})
      .fetch(key, {})
      .fetch('version-files', {})
    return {} if files.nil?

    files
  end

  def self.manifests
    key = ENV.fetch('INGEST_FILES', 'default')
    manifests = @@config.fetch('test-files', {})
      .fetch(key, {})
      .fetch('manifests', [])
    return [] if manifests.nil?

    manifests
  end

  def self.manifest_repeat
    key = ENV.fetch('INGEST_FILES', 'default')
    @@config.fetch('test-files', {})
      .fetch(key, {})
      .fetch('manifest-repeat', 1)
  end


  def self.do_encoding_test
    !encoding_zip_files.empty?
  end

  def self.run_ingest
    ENV.fetch('PREFIX', '').empty?
  end

  def self.has_ingest
    do_encoding_test || test_files.empty? == false || version_files.empty? == false
  end

  def self.encoding_zip_files
    key = ENV.fetch('INGEST_FILES', 'default')
    files = @@config.fetch('test-files', {})
      .fetch(key, {})
      .fetch('encoding-zip', {})
    return {} if files.nil?

    files
  end

  def self.sleep_time_ingest_global
    @@config.fetch('sleep-times', {}).fetch('ingest', 10).to_i
  end

  def self.encoding_zip
    'encoding.zip'
  end

  def self.encoding_label
    'combo'
  end
end
