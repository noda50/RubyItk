
require 'optparse'

OPTIONS = {
  :use_implement => false,
  :orb_debuglevel => 0,
  :iorfile => 'server.ior'
}

ARGV.options do |opts|
    script_name = File.basename($0)
    opts.banner = "Usage: ruby #{script_name} [options]"

    opts.separator ""

    opts.on("--o IORFILE",
            "Set IOR filename.",
            "Default: 'server.ior'") { |OPTIONS[:iorfile]| }
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
  require 'corba/poa'
  CORBA.implement('Test.idl', OPTIONS, CORBA::IDL::SERVANT_INTF)
else
  require 'TestS.rb'
end

class MyHello < POA::Test::Hello
  def initialize(orb)
    @orb = orb
  end

  def echo(txt)
    txt
  end

  def echo_seq(seq)
    seq
  end

  def shutdown()
    @orb.shutdown
  end
end #of servant MyHello

orb = CORBA.ORB_init(["-ORBDebugLevel", OPTIONS[:orb_debuglevel]], 'myORB')

obj = orb.resolve_initial_references('RootPOA')

root_poa = PortableServer::POA._narrow(obj)

poa_man = root_poa.the_POAManager

poa_man.activate

hello_srv = MyHello.new(orb)

hello_obj = hello_srv._this()

hello_ior = orb.object_to_string(hello_obj)

open(OPTIONS[:iorfile], 'w') { |io|
  io.write hello_ior
}

orb.run
