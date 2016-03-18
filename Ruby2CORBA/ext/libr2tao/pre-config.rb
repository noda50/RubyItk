
require 'rbconfig.rb'

if RUBY_PLATFORM =~ /win32/

mpc_os_block = <<OS_DEP__
  sharedname = libr2tao
  libpaths += "#{Config::CONFIG['libdir']}"
  lit_libs += #{File.basename(Config::CONFIG['LIBRUBY'],'.lib')}
  libout = .
  dllout = .
OS_DEP__

else

mpc_os_block = <<OS_DEP__
  sharedname = r2tao
  libpaths += "#{Config::CONFIG['libdir']}"
  libs += ruby
  libout = ..
  dllout = ..
OS_DEP__

end

File.open('r2tao.mpc', "w") {|f|
  f.puts <<THE_END
project : taolib, portableserver, anytypecode, dynamicany, dynamicinterface, typecodefactory {
  Source_Files {
    required.cpp
    object.cpp
    orb.cpp
    exception.cpp
    typecode.cpp
  }
  dynamicflags = R2TAO_BUILD_DLL
  includes += "#{Config::CONFIG['archdir']}" .
#{mpc_os_block}
}
THE_END
}
