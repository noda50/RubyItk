
# clean R2TAO build
command("#{get_config('makeprog')} realclean")

if get_config('without-tao') != 'yes'
  # clean ACE+TAO
  cur_dir = Dir.getwd
  Dir.chdir File.expand_path(get_config('aceroot'))
  begin
    command("#{get_config('makeprog')} realclean")
  ensure
    Dir.chdir cur_dir
  end
end
