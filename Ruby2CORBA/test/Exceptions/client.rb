
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

if OPTIONS[:use_implement]
  require 'corba'
  CORBA.implement('Test.idl', OPTIONS)
else
  require 'TestC.rb'
end

orb = CORBA.ORB_init(["-ORBDebugLevel", OPTIONS[:orb_debuglevel]], 'myORB')

begin
    
  obj = orb.string_to_object(OPTIONS[:iorfile])
  
  hello_obj = Test::Hello._narrow(obj)
  
  3.times { |i|
    begin
      hello_obj.test_exception
    rescue Test::ExOne => ex1
      assert "ERROR: got exception Test::ExOne when not expected" do 
        (i % 3) == 0 && ex1.code == (i+1)
      end
      puts "Caught expected exception Test::ExOne{why=#{ex1.why},code=#{ex1.code})"
    rescue CORBA::UNKNOWN => exu
      assert "ERROR: got unexpected unknown userexception" do 
        (i % 3) == 1 
      end
      puts "Caught expected unknown userexception"
    rescue Exception => ex
      assert "ERROR: unknown exception caught\n#{ex}", false
    else
      assert_not "ERROR: no exception caught where one was expected" do 
        (i % 3) != 2
      end
    end
  }
  
  hello_obj.shutdown()
  
  assert_not "ERROR: Object is reported nil!", CORBA::is_nil(hello_obj)
  
  hello_obj._free_ref()
  
  assert "ERROR: Object is reported non-nil!", CORBA::is_nil(hello_obj)

ensure
    
  orb.destroy()
    
end