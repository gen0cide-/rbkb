require 'rbkb/cli'

# searches for a binary string in input. string can be provided 'hexified'
class Rbkb::Cli::Bgrep < Rbkb::Cli::Executable
  def initialize(*args)
    super(*args)
    @opts[:start_off] ||= 0
    @opts[:end_off] ||= -1
  end

  def make_parser
    arg = super()
    arg.banner += " <search> <file | blank for stdin>"

    arg.on("-x", "--[no-]hex", "Search for hex (default: false)") do |x|
      @opts[:hex] = x
    end

    arg.on("-r", "--[no-]regex", "Search for regex (default: false)") do |r|
      @opts[:rx] = r
    end

    arg.on("-a", "--align=BYTES", Numeric, 
           "Only match on alignment boundary") do |a|
      @opts[:align] = a
    end

    arg.on("-n", "--[no-]filename", "Suppress prefixing of filenames.") do |n|
      @opts[:suppress_fname] = n
    end
    return arg
  end


  def parse(*args)
    super(*args)

    bail "need search argument" unless @find = @argv.shift

    if @opts[:hex] and @opts[:rx]
      bail "-r and -x are mutually exclusive"
    end

    # ... filenames vs. stdin will be parsed in 'go'
  end

  def go(*args)
    super(*args)

    if @opts[:hex]
      bail "you specified -x for hex and the subject isn't" unless @find.ishex?
      @find = @find.unhexify
    elsif @opts[:rx]
      @find = Regexp.new(@find, Regexp::MULTILINE)
    end

    if fname = @argv.shift
      dat = do_file_read(fname)
      fname = nil unless @argv[0] # only print filenames for multiple files
    else
      dat = @stdin.read
    end

    loop do 
      dat.bgrep(@find, @opts[:align]) do |hit_start, hit_end, match|
        print "#{fname}:" if fname and not @opts[:suppress_fname]

        puts("#{(hit_start).to_hex.rjust(8,"0")}:"+
             "#{(hit_end).to_hex.rjust(8,"0")}:b:"+
             "#{match.inspect}")
      end

      break unless fname=@argv.shift
      dat = do_file_read(fname)
    end
  end
end

