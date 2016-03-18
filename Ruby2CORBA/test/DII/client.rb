
require 'optparse'
require '../lib/assert.rb'
include TestUtil::Assertions

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

require 'corba'

orb = CORBA.ORB_init(["-ORBDebugLevel", OPTIONS[:orb_debuglevel]], 'myORB')

begin
    
  obj = orb.string_to_object(OPTIONS[:iorfile])

  puts "***** Synchronous twoway DII"
  req = obj._request("echo")
  req.arguments = [
    ['method', CORBA::ARG_IN, CORBA::_tc_string, "sync twoway"],
    ['message', CORBA::ARG_IN, CORBA::_tc_string, "Hello world!"]
  ]
  req.set_return_type(CORBA::_tc_string)

  the_string = req.invoke()

  puts "string returned <#{the_string}>"
  puts

  puts "***** Deferred twoway DII (using get_response())"
  req = obj._request("echo")
  req.arguments = [
    ['method', CORBA::ARG_IN, CORBA::_tc_string, "deferred twoway (1)"],
    ['message', CORBA::ARG_IN, CORBA::_tc_string, "Hello world!"]
  ]
  req.set_return_type(CORBA::_tc_string)

  req.send_deferred()
  puts 'getting response...'
  req.get_response()

  puts "string returned <#{req.return_value}>"
  puts

  ### DOESN'T WORK WITH TAO <= 1.5.9 BECAUSE OF BUG IN TAO
  if TAO::MAJOR_VERSION>1 ||
    (TAO::MAJOR_VERSION == 1 &&
        (TAO::MINOR_VERSION > 5 ||
          (TAO::MINOR_VERSION == 5 && TAO::BETA_VERSION>9)))
    puts "***** Deferred twoway DII (using poll_response())"
    req = obj._request("echo")
    req.arguments = [
      ['method', CORBA::ARG_IN, CORBA::_tc_string, "deferred twoway (2)"],
      ['message', CORBA::ARG_IN, CORBA::_tc_string, "Hello world!"]
    ]
    req.set_return_type(CORBA::_tc_string)

    req.send_deferred()
    begin
      puts 'sleeping...'
      sleep(0.01)
      puts 'polling for response...'
    end while !req.poll_response()

    puts "string returned <#{req.return_value}>"
    puts
  end

  puts "***** Oneway shutdown"
  req = obj._request("shutdown")
  req.send_oneway()

ensure
    
  orb.destroy()

end
    