
require 'rbconfig'

# check/set environment settings for ACE+TAO
ENV['ACE_ROOT'] ||= get_config('aceroot')
ENV['TAO_ROOT'] ||= get_config('taoroot')

if RUBY_PLATFORM =~ /win32/
  ENV['PATH'] = "#{File.join(ENV['ACE_ROOT'],'lib')}#{Config::CONFIG['PATH_SEPARATOR']}#{ENV['PATH']}"
  ENV['SSL_ROOT'] = get_config('sslroot') if get_config('with-ssl')=='yes'
else
  ENV['LD_LIBRARY_PATH'] = "#{File.join(ENV['ACE_ROOT'],'lib')}#{Config::CONFIG['PATH_SEPARATOR']}#{ENV['LD_LIBRARY_PATH'] || ""}"
  ENV['SSL_ROOT'] = get_config('sslroot') if get_config('with-ssl')=='yes' && get_config('sslroot')!='/usr'
end

# Do we handle ACE+TAO here?
if get_config('without-tao')!='yes'

  # build ACE+TAO libs
  cur_dir = Dir.getwd
  Dir.chdir File.expand_path(get_config('aceroot'))
  begin
    command("#{get_config('makeprog')}")
  ensure
    Dir.chdir cur_dir
  end
end

# build R2CORBA ext libs
BUILD_ERROR = "Failed to build R2CORBA ext libraries"

command("#{get_config('makeprog')}")

if RUBY_PLATFORM =~ /win32/
  so_ext='.dll'
else
  so_ext='.so'
end

raise BUILD_ERROR unless File.exists?(File.join('libr2tao', 'libr2tao'+so_ext)) &&
                          File.exists?(File.join('librpoa', 'librpoa'+so_ext)) &&
                          File.exists?(File.join('librpol', 'librpol'+so_ext))
