
require 'optparse'

OPTIONS = {
  :use_implement => false,
  :orb_debuglevel => 0,
  :iorfile => 'file://server.ior'
}

ARGV.options do |opts|
    script_name = File.basename($0)
    opts.banner = "Usage: ruby #{script_name} [options]"

    opts.separator ""

    opts.on("--k IORFILE",
            "Set IOR.",
            "Default: 'file://server.ior'") { |OPTIONS[:iorfile]| }
    opts.on("--d LVL",
            "Set ORBDebugLevel value.",
            "Default: 0") { |OPTIONS[:orb_debuglevel]| }
    opts.on("--use-implement",
            "Load IDL through CORBA.implement() instead of precompiled code.",
            "Default: off") { |OPTIONS[:use_implement]| }

    opts.separator ""

    opts.on("-h", "--help",
            "Show this help message.") { puts opts; exit }

    opts.parse!
end

if OPTIONS[:use_implement]
  require 'corba'
  CORBA.implement('Test.idl', OPTIONS)
else
  require 'TestC.rb'
end

orb = CORBA.ORB_init(["-ORBDebugLevel", OPTIONS[:orb_debuglevel]], 'myORB')

##s = open(OPTIONS[:iorfile], 'r').read

obj = orb.string_to_object(OPTIONS[:iorfile])

hello_obj = Test::Hello._narrow(obj)

the_string, the_length = hello_obj.echo("Hello world!")

puts "string returned <#{the_string}>; length = #{the_length}"

hello_obj.shutdown()

orb.destroy()
