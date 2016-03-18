
require 'optparse'

OPTIONS = {
  :use_implement => false,
  :orb_debuglevel => 0,
  :listenport => 9999,
  :iorfile => 'server.ior'
}

ARGV.options do |opts|
    script_name = File.basename($0)
    opts.banner = "Usage: ruby #{script_name} [options]"

    opts.separator ""

    opts.on("--o IORFILE",
            "Set IOR filename.",
            "Default: 'server.ior'") { |OPTIONS[:iorfile]| }
    opts.on("--p PORT",
            "Set endpoint port.",
            "Default: 3456") { |OPTIONS[:listenport]| }
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
  def initialize(orb, id)
    @orb = orb
    @id = id
  end

  def get_string()
    "#{@id}: Hello there!"
  end

  def shutdown()
    @orb.shutdown
  end
end #of servant MyHello

class MyLocator
  include IORTable::Locator
  
  def initialize(object_key, ior)
    @map = {object_key, ior}
  end
  
  def locate(object_key)
    puts "server: MyLocator.locate('#{object_key}') called"
    return @map[object_key] if @map.has_key?(object_key)
    raise IORTable::NotFound
  end
end

orb = CORBA.ORB_init(["-ORBDebugLevel", OPTIONS[:orb_debuglevel], "-ORBListenEndpoints", "iiop://localhost:#{OPTIONS[:listenport]}"], 'myORB')

obj = orb.resolve_initial_references('RootPOA')

root_poa = PortableServer::POA._narrow(obj)

poa_man = root_poa.the_POAManager

poa_man.activate

obj = orb.resolve_initial_references('IORTable')

iortbl = IORTable::Table._narrow(obj)

hello_srv = MyHello.new(orb, "Hello")

hello_obj = hello_srv._this()

hello_ior = orb.object_to_string(hello_obj)

iortbl.bind("Hello", hello_ior)

hello_srv = MyHello.new(orb, "Hello2")

hello_obj = hello_srv._this()

hello_ior = orb.object_to_string(hello_obj)

iortbl.set_locator(MyLocator.new("Hello2", hello_ior))

open(OPTIONS[:iorfile], 'w') { |io|
  io.write hello_ior
}

orb.run
