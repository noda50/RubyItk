
def do_command(arg)
  puts arg if no_harm?
  command(arg) unless no_harm?
end

def do_symlink(from, to)
  $stderr.puts "symlink #{from} -> #{to}" if verbose?
  return if no_harm?
  if !File.exists?(to)
    File.symlink(from, to)
  else
    if !File.symlink?(to) or File.readlink(to)!=from
      $stderr.puts "WARNING: unable to install symlink #{from} -> #{to}"
    end
  end
end

if RUBY_PLATFORM =~ /win32/
else
  do_symlink(File.join(@config.install_prefix,get_config('rbdir'),'ridl','ridlc.rb'), File.join(@config.install_prefix,get_config('bindir'),'ridlc'))
  File.chmod(0755, File.join(@config.install_prefix,get_config('bindir'),'ridlc')) unless no_harm?
end

if get_config('without-tao') != 'yes'

  File.open('acefiles.rb') do |f|
    eval f.read
  end

  if RUBY_PLATFORM =~ /win32/
    ACE_FILES.each {|dep|
      install(File.join(get_config('aceroot'), 'lib' , dep+'.dll'), File.join(get_config('aceinstdir')), 0555)
    }
  else
    ACE_FILES.each {|dep|
      # full pathname
      dep = File.join(get_config('aceroot'), 'lib' , 'lib'+dep+'.so')
      # look for versioned <lib>.SO.x.x.x
      dep_ver = Dir.glob(dep+'.*').shift
      if dep_ver
        install(dep_ver, File.join(@config.install_prefix,get_config('aceinstdir')), 0555)
        do_symlink(File.join(@config.install_prefix,get_config('aceinstdir'),File.basename(dep_ver)), File.join(@config.install_prefix,get_config('aceinstdir'),File.basename(dep)))
      else
        install(dep, File.join(@config.install_prefix,get_config('aceinstdir')), 0555)
      end
    }
  end

end
