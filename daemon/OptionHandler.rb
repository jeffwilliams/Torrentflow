# Simple option handling class.
# Create a new instance, which automatically reads ARGV, call parse, and then
# access the opts hash to access options, and the args array to access args.
class OptionHandler
	
	class Option
		def initialize(optname)
			@name = optname
			@value = nil
		end

		attr_reader :name
		attr_accessor :value
	end	

	def initialize
		setArgv(ARGV)
	end
	
	def setArgv(argv)
		@raw = argv
	end

	InOptions = 0
	AfterOptions = 1
	def parse
		@opts = {}
		@args = []
		state = InOptions
		lastOpt = nil
		@raw.each{ |arg|
			if arg[0..0] == '-'
				if arg == '--' 	# -- signifies that the rest of the arguments are not options	
					state = AfterOptions
				else
					s = 1
					s = 2 if arg[0..1] == '--'
					opt = arg[s,arg.length]
					opts[opt] = Option.new(opt)
					lastOpt = opts[opt]
				end
			else
				if lastOpt && state == InOptions
					lastOpt.value = arg
					lastOpt = nil
				else
					# Must be into the arguments
					args.push arg
					state = AfterOptions
				end
			end
		}
	end 
	
	def show
		puts "Options: "
		opts.each{ |key, value|
			puts " #{key} => #{value.name} = #{value.value}"
		}
		puts "Arguments: "
		args.each{ |arg|
			puts " '#{arg}'"
		}
	
	end

	attr_reader :opts
	attr_reader :args
end

=begin Testing code:
oh = OptionHandler.new
oh.setArgv(%w{--f --da x --rev thing thang})
oh.parse
oh.show

oh.setArgv(%w{-f --da x -r thing thang})
oh.parse
oh.show
exit 0
=end 
