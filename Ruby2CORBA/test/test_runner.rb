
require 'rbconfig'
include Config
require 'test/unit'

root_path = File.basename(Dir.getwd) == 'test' ? '..' : '.'

if !ENV['ACE_ROOT'].nil?
  ## setup the right environment for running tests
  if RUBY_PLATFORM =~ /win32/
    incdirs = [
      File.expand_path('lib'),
      File.expand_path(File.join(root_path, 'ext', 'libr2tao')),
      File.expand_path(File.join(root_path, 'ext', 'librpoa')),
      File.expand_path(File.join(root_path, 'ext', 'librpol')),
      ENV['RUBYLIB']
    ].compact
    ENV['RUBYLIB'] = incdirs.join(CONFIG['PATH_SEPARATOR'])
    ENV['PATH'] = "#{File.join(ENV['ACE_ROOT'],'lib')}#{CONFIG['PATH_SEPARATOR']}#{ENV['PATH']}"
  else
    incdirs = [
      File.expand_path(root_path, 'lib'),
      File.expand_path(root_path, 'ext'),
      ENV['RUBYLIB']
    ].compact
    ENV['RUBYLIB'] = incdirs.join(CONFIG['PATH_SEPARATOR'])
    ENV['LD_LIBRARY_PATH'] = "#{File.join(ENV['ACE_ROOT'],'lib')}#{CONFIG['PATH_SEPARATOR']}#{ENV['LD_LIBRARY_PATH'] || ""}"
  end
end

## define test class
class TestRunner < Test::Unit::TestCase
end

Dir.glob(File.expand_path(File.join(root_path, 'test','*'))).each {|p|
  if File.directory?(p) && File.exists?(File.join(p, 'run_test.rb'))
    TestRunner.module_eval %Q{
    def test_#{File.basename(p)}
      puts ""
      puts "##### running test #{File.basename(p)}"
      puts ""
      cur_dir = Dir.getwd
      Dir.chdir('#{p}')
      begin
        system("ruby #{ENV['R2CORBA_VERBOSE'].nil? ? '' : '-v'} run_test.rb #{ENV['R2CORBA_DEBUG'].nil?() ? '' : '-d' }")
        raise "Execution of test #{File.basename(p)} failed with exitstatus \#\{$?.exitstatus\}" unless $?.exitstatus == 0
      ensure
        Dir.chdir(cur_dir)
      end
    end
    }
  end
}
