
# get Win32 Process support
if RUBY_PLATFORM =~ /win32/
  require 'rubygems'
  gem 'windows-pr', '>= 0.6.5'
  require 'windows/process'
  require 'windows/error'
  require 'windows/library'
  require 'windows/console'
  require 'windows/handle'
  require 'windows/synchronize'
end

module TestUtil

  class ProcessError < RuntimeError; end

if RUBY_PLATFORM =~ /win32/
  class Process
    include Windows::Process
    include Windows::Error
    include Windows::Library
    include Windows::Console
    include Windows::Handle
    include Windows::Synchronize
    extend Windows::Process
    extend Windows::Error
    extend Windows::Library
    extend Windows::Console
    extend Windows::Handle
    extend Windows::Synchronize

  protected
    # Used by Process.create
    ProcessInfo = Struct.new("ProcessInfo",
        :process_handle,
        :thread_handle,
        :process_id,
        :thread_id
    )

    def Process.create(cmd_)
      startinfo = [0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0]
      startinfo = startinfo.pack('LLLLLLLLLLLLSSLLLL')
      procinfo  = [0,0,0,0].pack('LLLL')

      bool = CreateProcess(
         0,                 # App name
         cmd_,              # Command line
         0,                 # Process attributes
         0,                 # Thread attributes
         1,                 # Inherit handles?
         0,                 # Creation flags
         0,                 # Environment
         0,                 # Working directory
         startinfo,         # Startup Info
         procinfo           # Process Info
      )
      
      unless bool
         raise ProcessError, "CreateProcess() failed: ", get_last_error
      end
      
      ProcessInfo.new(
         procinfo[0,4].unpack('L').first, # hProcess
         procinfo[4,4].unpack('L').first, # hThread
         procinfo[8,4].unpack('L').first, # hProcessId
         procinfo[12,4].unpack('L').first # hThreadId
      )
    end

    def Process.waitpi(pi_)
      exit_code = [0].pack('L')
      if GetExitCodeProcess(pi_.process_handle, exit_code)
        exit_code = exit_code.unpack('L').first
        return exit_code == STILL_ACTIVE ? nil : exit_code
      else
        CloseHandle(pi_.process_handle) unless pi_.process_handle == INVALID_HANDLE_VALUE
        pi_.process_handle = INVALID_HANDLE_VALUE
        raise ProcessError, "GetExitCodeProcess failed: ", get_last_error
      end
    end

    def Process.stop(pi_)
      if pi_.process_handle != INVALID_HANDLE_VALUE
        thread_id = [0].pack('L')
        dll       = 'kernel32'
        proc      = 'ExitProcess'

        thread = CreateRemoteThread(
            pi_.process_handle,
            0,
            0,
            GetProcAddress(GetModuleHandle(dll), proc),
            0,
            0,
            thread_id
        )

        if thread
            WaitForSingleObject(thread, 5)
            CloseHandle(pi_.process_handle)
            pi_.process_handle = INVALID_HANDLE_VALUE
        else
            CloseHandle(pi_.process_handle)
            pi_.process_handle = INVALID_HANDLE_VALUE
            raise ProcessError, get_last_error
        end
      end
    end

    def Process.kill(pi_)
      if pi_.process_handle != INVALID_HANDLE_VALUE
        if TerminateProcess(pi_.process_handle, pi_.process_id)
          CloseHandle(pi_.process_handle)
          pi_.process_handle = INVALID_HANDLE_VALUE
        else
          CloseHandle(pi_.process_handle)
          pi_.process_handle = INVALID_HANDLE_VALUE
          raise ProcessError, get_last_error
        end 
      end
    end

    def initialize(pi_)
      @pi = pi_
      @exitstatus = nil
    end
  public
    def Process.run(cmd_, arg_)
      pi = self.create("ruby #{$VERBOSE ? '-v' : ''} #{cmd_} #{arg_}")
      proc = self.new(pi)
      sleep(0.1)
      proc.check_status
      return proc
    end

    def pid; @pi.process_id; end

    def check_status
      @exitstatus ||= self.class.waitpi(@pi)
      return @exitstatus.nil?
    end

    def exitstatus; @exitstatus; end

    def is_running?; @exitstatus.nil?; end
    def has_error?; !@exitstatus.nil? and (@exitstatus != 0); end

    def stop
      self.class.stop(@pi)
      @exitstatus = 0
    end

    def kill
      self.class.kill(@pi)
    end
  end
else
  class Process
  protected
    def initialize(pid_)
      @pid = pid_
      @status = nil
      @exitstatus = nil
    end
  public
    def Process.run(cmd_, arg_)
      pid = ::Process.fork do
        ::Kernel.exec("ruby #{$VERBOSE ? '-v' : ''} #{cmd_} #{arg_}")
      end
      proc = self.new(pid)
      sleep(0.1)
      proc.check_status
      return proc
    end

    attr_reader :pid

    def check_status
      begin
        tmp, @status = ::Process.waitpid2(@pid, ::Process::WNOHANG)
        if tmp==@pid and @status.success? == false
          @exitstatus = @status.exitstatus
          return false
        end
        return true
      rescue Errno::ECHILD
        @exitstatus = 0
        return false
      end
    end

    def exitstatus
      @exitstatus
    end

    def is_running?; @exitstatus.nil?; end
    def has_error?; !@status.nil? and (@status.success? == false); end

    def stop
      ::Process.kill('SIGTERM', @pid)
    end

    def kill
      ::Process.kill('SIGKILL', @pid)
    end
  end
end

  class Test
    def initialize
      @proc = nil
      @cmd = ""
    end

    def run(cmd_, arg_)
      @cmd = cmd_
      begin
        @proc = Process.run(cmd_, arg_)
      rescue ProcessError
        STDERR.puts "ERROR: failed to run <#{@cmd}>"
        return false
      end
      true
    end

    def pid; @proc.pid; end
    def is_running?; @proc.is_running?; end
    def exit_status; @proc.exitstatus; end

    def wait(timeout, check_exit=true)
      t = Time.now
      begin
        if @proc.check_status
          if (Time.now() - t) >= timeout.to_f
            STDERR.puts "ERROR: KILLING #{@cmd}"
            @proc.kill
            return 255
          end
          sleep(0.1)
        end
      end until !@proc.is_running?
      if check_exit && @proc.has_error?
        STDERR.puts "ERROR: #{@cmd} returned: #{@proc.exitstatus}"
        return @proc.exitstatus != 0 ? @proc.exitstatus : 255
      end
      return 0
    end

    def wait_term(timeout)
      @proc.stop
      self.wait(timeout, false)
    end

    def kill(timeout)
      @proc.kill
      self.wait(timeout, false)
    end

  end

  def TestUtil.wait_for_file(filename, timeout)
    t = Time.now
    while !File.readable?(filename) do
      sleep(0.1)
      if (Time.now() - t) >= timeout.to_f
        STDERR.puts "ERROR: could not find file '#{filename}'"
        return false
      end
    end
    true
  end

  def TestUtil.remove_file(filename)
    File.delete(filename) if File.exists?(filename)
  end

end
 
