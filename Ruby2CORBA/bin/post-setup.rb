 
if RUBY_PLATFORM =~ /win32/
  bat_file = <<THE_END__
@echo off
if not "%~f0" == "~f0" goto WinNT
ruby -Sx "%0" %1 %2 %3 %4 %5 %6 %7 %8 %9
goto endofruby
:WinNT
if not exist "%~d0%~p0ruby" goto rubyfrompath
if exist "%~d0%~p0ruby" "%~d0%~p0ruby" -x "%~f0" %*
goto endofruby
:rubyfrompath
ruby -x "%~f0" %*
goto endofruby
#!/bin/ruby
#
require 'ridl/ridl.rb'

IDL.run

__END__
:endofruby
THE_END__

  File.open('ridlc.bat', 'w') {|f|
    f.puts bat_file
  }
end
