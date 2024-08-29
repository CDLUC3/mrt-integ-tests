# frozen_string_literal: true

dir = '/tmp/datapath'
`mkdir -p #{dir}`
File.write("#{dir}/#{ARGV[0]}", ' ' * ARGV[1].to_i) if ARGV.length >= 2
