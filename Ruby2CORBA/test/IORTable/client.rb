
require 'optparse'

OPTIONS = {
  :use_implement => false,
  :orb_debuglevel => 0,
  :serverport => 9999
}

ARGV.options do |opts|
    script_name = File.basename($0)
    opts.banner = "Usage: ruby #{script_name} [options]"

    opts.separator ""

    opts.on("--p PORT",
            "Set server endpoint port.",
            "Default: 3456") { |OPTIONS[:serverport]| }
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

obj = orb.string_to_object("corbaloc:iiop:1.2@localhost:#{OPTIONS[:serverport]}/Hello")

hello_obj = Test::Hello._narrow(obj)

the_string = hello_obj.get_string()

puts "servant Hello returned <#{the_string}>"

obj = orb.string_to_object("corbaloc:iiop:1.2@localhost:#{OPTIONS[:serverport]}/Hello2")

hello_obj = Test::Hello._narrow(obj)

the_string = hello_obj.get_string()

puts "servant Hello2 returned <#{the_string}>"

hello_obj.shutdown()

orb.destroy()
