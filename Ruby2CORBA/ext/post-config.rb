
PERL_ERROR = "PERL missing! A working version of PERL in the PATH is required."
SSL_ERROR = "No SSL root directory specified (either with SSL_ROOT env. variable or on commandline)."
PLATFORM_ERROR = "Unsupported platform: #{RUBY_PLATFORM}."

require 'rbconfig'

ACE_CONFIGS = {
  /win32/ => %Q{
#define ACE_DISABLE_WIN32_INCREASE_PRIORITY
#define ACE_DISABLE_WIN32_ERROR_WINDOWS
#define ACE_HAS_INTERCEPTORS 0
#include "ace/config-win32.h"
  },
  /linux/ => %Q{
#define ACE_HAS_GETIFADDRS
#include "ace/config-linux.h"
  },
  /sparc-solaris/ => %Q{
#define ACE_USES_STD_NAMESPACE_FOR_STDCPP_LIB 1
#include "ace/config-sunos5.10.h"
#undef ACE_HAS_NEW_NOTHROW
  }
}

PLATFORM_MACROS = {
  /linux/ => %Q{
versioned_so=1
threads=#{get_config('without-threads')=='yes' ? 0 : 1}
ssl=#{get_config('with-ssl')=='yes' ? 1 : 0}
exceptions=1
optimize=1
debug=0
fl_reactor=0
tk_reactor=0
boost = 0
no_hidden_visibility=1
include $(ACE_ROOT)/include/makeinclude/platform_linux.GNU
CCFLAGS += -Wwrite-strings -Wcast-align
CPPFLAGS += -DACE_USE_RCSID=0
  },
  /sparc-solaris/ => %Q{
threads=#{get_config('without-threads')=='yes' ? 0 : 1}
ssl=#{get_config('with-ssl')=='yes' ? 1 : 0}
#exceptions=1
inline=0
optimize=0
debug=0
fl_reactor=0
tk_reactor=0
no_hidden_visibility=1
#{ /^cc/i =~ Config::CONFIG['CC'] ? 'include $(ACE_ROOT)/include/makeinclude/platform_sunos5_sunc++.GNU' :  'include $(ACE_ROOT)/include/makeinclude/platform_sunos5_g++.GNU' }
CPPFLAGS += -DACE_USE_RCSID=0
LDFLAGS += #{Config::CONFIG['SOLIBS']} #{ /^cc/i =~ Config::CONFIG['CC'] ? '-lCrun -lCstd' : ''}
}
}

# check availability of PERL
raise PERL_ERROR unless system('perl -v')

# Do we handle ACE+TAO here?
if get_config('without-tao')!='yes'

  # get ACE config
  key, value = ACE_CONFIGS.find {|k,v| RUBY_PLATFORM =~ k }

  raise PLATFORM_ERROR if key.nil?

  # write config.h
  File.open(File.join(get_config('aceroot'),'ace','config.h'), "w") {|f|
    f.puts value
  }

  if !(RUBY_PLATFORM =~ /win32/)
    # get GNU make plaform config
    key, value = PLATFORM_MACROS.find {|k,v| RUBY_PLATFORM =~ k }

    raise PLATFORM_ERROR if key.nil?

    # write platform_macros.GNU
    File.open(File.join(get_config('aceroot'),'include','makeinclude','platform_macros.GNU'), "w") {|f|
      f.puts value
    }
  end

  DEFAULT_FEATURES = <<THE_END__
fl_reactor=0
tk_reactor=1
qos=0
ssl=#{get_config('with-ssl')=='yes' ? 1 : 0}
ipv6=#{get_config('with-ipv6')=='yes' ? 1 : 0}
THE_END__
  File.open(File.join(get_config('aceroot'),'bin','MakeProjectCreator','config','default.features'), "w") {|f|
    f.puts DEFAULT_FEATURES
  }

  TAO4RUBY_MWC = <<THE_END__
workspace {
  $(ACE_ROOT)/ace
  $(ACE_ROOT)/apps/gperf/src
  $(TAO_ROOT)/TAO_IDL
  $(TAO_ROOT)/tao
  #{get_config('with-ssl')=='yes' ? '$(TAO_ROOT)/orbsvcs/orbsvcs/Security.mpc' : ''}
  #{get_config('with-ssl')=='yes' ? '$(TAO_ROOT)/orbsvcs/orbsvcs/SSLIOP.mpc' : ''}
  exclude {
    bin
    docs
    etc
    html
    include
    lib
    m4
    man
    contrib
    netsvcs
    websvcs
    protocols
    tests
    performance-tests
    examples
    Kokyu
    ASNMP
    ACEXML
  }
}
THE_END__
  File.open(File.join(get_config('aceroot'),'TAO4Ruby.mwc'), "w") {|f|
    f.puts TAO4RUBY_MWC
  }

  cur_dir = Dir.getwd
  Dir.chdir File.expand_path(get_config('aceroot'))
  begin
    if RUBY_PLATFORM =~ /win32/
      command("perl bin\\mwc.pl -type nmake TAO4Ruby.mwc")
    else
      command("perl bin/mwc.pl -type gnuace TAO4Ruby.mwc")
    end
  ensure
    Dir.chdir cur_dir
  end
end

# configure R2TAO build
MWC = File.join(get_config('aceroot'), 'bin', 'mwc.pl')

if RUBY_PLATFORM =~ /win32/
  command("perl #{MWC} -type nmake ext.mwc")
else
  command("perl #{MWC} -type gnuace ext.mwc")
end

