
ACE_ENV_ERROR = "Cannot find ACE+TAO. Missing ACE_ROOT configuration!"
TAO_ENV_ERROR = "Cannot find ACE+TAO. Missing TAO_ROOT configuration!"

# check availability of ACE/TAO
if get_config('aceroot')=='' && File.directory?(File.join('ACE','ACE_wrappers'))
  set_config('aceroot', File.expand_path(File.join('ACE','ACE_wrappers')))
end
raise ACE_ENV_ERROR if get_config('aceroot').nil?
if get_config('taoroot')=='' && File.directory?(File.join(get_config('aceroot'),'TAO'))
  set_config('taoroot', File.expand_path(File.join(get_config('aceroot'),'TAO')))
end
raise TAO_ENV_ERROR if get_config('taoroot').nil?
if get_config('mpcroot')=='' && File.directory?(File.join(get_config('aceroot'),'MPC'))
  set_config('mpcroot', File.expand_path(File.join(get_config('aceroot'),'MPC')))
end

# check/set environment settings for ACE+TAO
ENV['ACE_ROOT'] ||= get_config('aceroot')
ENV['TAO_ROOT'] ||= get_config('taoroot')
ENV['MPC_ROOT'] ||= get_config('mpcroot')

if RUBY_PLATFORM =~ /win32/
  set_config('makeprog', "nmake CFG=\"Win32 Release\"")
end
