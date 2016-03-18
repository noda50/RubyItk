
require 'rbconfig.rb'

if RUBY_PLATFORM =~ /win32/

mpc_os_block = <<OS_DEP__
  sharedname = librpol
  libpaths += "#{Config::CONFIG['libdir']}"
  lit_libs += #{File.basename(Config::CONFIG['LIBRUBY'],'.lib')}
  libs += libr2tao librpoa
  libout = .
  dllout = .
OS_DEP__

else

mpc_os_block = <<OS_DEP__
  sharedname = rpol
  libpaths += "#{Config::CONFIG['libdir']}"
  libs += ruby r2tao rpoa
  libout = ..
  dllout = ..
OS_DEP__

end

File.open('rpolicies.mpc', "w") {|f|
  f.puts <<THE_END
project : taolib, portableserver, anytypecode, dynamicany, dynamicinterface, typecodefactory, bidir_giop {
  after += r2tao rpoa
  Source_Files {
    policies.cpp
  }
  dynamicflags = R2TAO_POL_BUILD_DLL
  libpaths += #{File.join('..', 'libr2tao')} #{File.join('..', 'librpoa')}
  includes += "#{Config::CONFIG['archdir']}" #{File.join('..', 'libr2tao')} #{File.join('..', 'librpoa')}
#{mpc_os_block}
}
THE_END
}

