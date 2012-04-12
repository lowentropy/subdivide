def get_options
  options = {
    :subdivisions => 3,
    :output => '-',
    :check => false,
    :verbose => false
  }
  
  parse = OptionParser.new do |opts|
    opts.banner = "Usage: loop.rb [options] input.obj"
    
    opts.on '-h', '--help', 'Display this help' do
      puts opts
      exit
    end
    
    opts.on '-s', '--subdivisions num', 'Number of subdivions (default = 3)' do |num|
      options[:subdivisions] = num.to_i
    end
    
    opts.on '-o', '--output out.obj', 'Output location (or - for stdout)' do |out|
      options[:output] = out
    end
    
    opts.on '-c', '--check', 'Check sanity' do
      options[:check] = true
    end
    
    opts.on '-v', '--verbose', 'Print verbose statistics' do
      options[:verbose] = true
    end
  end
  
  parse.parse!
  
  if ARGV.length != 1
    puts parse
    exit
  end
  
  options[:file] = ARGV[0]
  options
end
