
require 'rbconfig.rb'

if RUBY_PLATFORM =~ /win32/

mpc_os_block = <<OS_DEP__
  sharedname = librpoa
  libpaths += "#{Config::CONFIG['libdir']}"
  lit_libs += #{File.basename(Config::CONFIG['LIBRUBY'],'.lib')}
  libs += libr2tao
  libout = .
  dllout = .
OS_DEP__

else

mpc_os_block = <<OS_DEP__
  sharedname = rpoa
  libpaths += "#{Config::CONFIG['libdir']}"
  libs += ruby r2tao
  libout = ..
  dllout = ..
OS_DEP__

end

File.open('rpoa.mpc', "w") {|f|
  f.puts <<THE_END
project : taolib, portableserver, anytypecode, dynamicany, dynamicinterface, typecodefactory, iortable {
  after += r2tao
  Source_Files {
    poa.cpp
  }
  dynamicflags = R2TAO_POA_BUILD_DLL
  libpaths += #{File.join('..','libr2tao')}
  includes += "#{Config::CONFIG['archdir']}" #{File.join('..', 'libr2tao')}
#{mpc_os_block}
}
THE_END
}

