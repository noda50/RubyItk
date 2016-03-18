
require 'rbconfig'

if RUBY_PLATFORM =~ /win32/
  bat_file = <<THE_END__
@bin\\ridlc.bat %*
THE_END__

  File.open('ridlc.bat', 'w') {|f|
    f.puts bat_file
  }
else
  ridlc_rb = <<THE_END__
#!#{Config::CONFIG['bindir']}/ruby
#---------------------------------
# This file is generated
#---------------------------------
require 'ridl/ridl.rb'

if __FILE__ == $0

  IDL.run

end
THE_END__
  File.open('lib/ridl/ridlc.rb', 'w') {|f|
    f.puts ridlc_rb
  }
  File.symlink('lib/ridl/ridlc.rb', 'ridlc') if !File.exists?('ridlc')
  File.chmod(0755, 'ridlc')
end

## setup the right environment for running R2CORBA
if RUBY_PLATFORM =~ /win32/
  incdirs = [
    File.expand_path('lib'),
    File.expand_path(File.join('ext', 'libr2tao')),
    File.expand_path(File.join('ext', 'librpoa')),
    File.expand_path(File.join('ext', 'librpol')),
    ENV['RUBYLIB']
  ].compact
  ENV['RUBYLIB'] = incdirs.join(Config::CONFIG['PATH_SEPARATOR'])
  ENV['PATH'] = "#{File.join(ENV['ACE_ROOT'],'lib')}#{Config::CONFIG['PATH_SEPARATOR']}#{ENV['PATH']}"
else
  incdirs = [
    File.expand_path('lib'),
    File.expand_path('ext'),
    ENV['RUBYLIB']
  ].compact
  ENV['RUBYLIB'] = incdirs.join(Config::CONFIG['PATH_SEPARATOR'])
  ENV['LD_LIBRARY_PATH'] = "#{File.join(ENV['ACE_ROOT'],'lib')}#{Config::CONFIG['PATH_SEPARATOR']}#{ENV['LD_LIBRARY_PATH'] || ""}"
end

r2tao_root = File.join('lib','corba','r2tao')
tao_root = ENV['TAO_ROOT']
if RUBY_PLATFORM =~ /win32/
  idlc = 'ridlc.bat'
else
  idlc = File.join('.','ridlc')
end

## recreate orb PIDL for ridl compiler
command("#{idlc} --preprocess -o #{File.join('lib','ridl','orb.pidl')} --include=#{File.join(tao_root,'tao')} orb.idl")

## compile base IDL
cmd = "#{idlc}"
cmd << " --ignore-pidl -o #{File.join(r2tao_root,'tao_orb.rb')}" <<
       " --namespace=R2CORBA --include=#{File.join(tao_root,'tao')}" <<
       " --stubs-only --expand-includes --search-includepath" <<
       " --no-libinit --interface-as-class=TypeCode orb.idl"
command(cmd)
[ ['POA', File.join('tao','PortableServer','POA.pidl')],
  ['POAManager', File.join('tao','PortableServer','POAManager.pidl')],
  ['Messaging', File.join('tao','Messaging','Messaging.pidl')],
  ['BiDirPolicy', File.join('tao','BiDir_GIOP','BiDirPolicy.pidl')],
  ['TAO_Ext', File.join('tao','Messaging','TAO_Ext.pidl')],
  ['IORTable', File.join('tao','IORTable','IORTable.pidl')]
].each {|stub, pidl|
  cmd = "#{idlc}"
  cmd << " -o #{File.join(r2tao_root,stub+'C.rb')} --namespace=R2CORBA" <<
         " --include=#{tao_root} --stubs-only --expand-includes" <<
         " --search-includepath --no-libinit #{pidl}"
  command(cmd)
}
[ [File.join(tao_root, 'orbsvcs', 'orbsvcs'), 'CosNaming.idl']
].each {|inc, idl|
  cmd = "#{idlc}"
  cmd << " --directory=#{r2tao_root}" <<
         " --include=#{inc} --expand-includes" <<
         " --search-includepath #{idl}"
  command(cmd)
}
