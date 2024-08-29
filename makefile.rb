dir = '/tmp/datapath'
%x[mkdir -p #{dir}]
if ARGV.length >= 2
  File.open("#{dir}/#{ARGV[0]}", 'w') do |f|
    f.write(' ' * ARGV[1].to_i)
  end
end
