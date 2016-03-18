
if RUBY_PLATFORM =~ /win32/
  File.delete('ridlc.bat') if File.exists?('ridlc.bat')
end
