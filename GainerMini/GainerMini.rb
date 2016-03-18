#! /usr/bin/env ruby
## -*- mode: ruby -*-

$LOAD_PATH.push("~/lib/ruby") ;
$LOAD_PATH.push("/home/noda/lib/ruby") ;

require 'WithConfParam.rb' ;
require 'Stat/Uniform.rb' ;
require 'sexp.rb' ;
require 'thread' ;


##======================================================================
class GainerMini < WithConfParam

  DefaultConf = { 
    :device => '/dev/ttyACM0',
    :mode => nil,
    :log => true,
    nil => nil } ;

  EOL = '*' ;

  ##__________________________________________________

  ##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  attr :device, true ;
  attr :mode, true ;
  attr :strm, true ;
  attr :version, true ;

  attr :recvThread, true ;
  attr :lastResponse, true ;
  attr :recvMutex, true ;
  attr :recvPassiveCV, true ;
  attr :recvActiveCV, true ;
  attr :contEndP, true ;

  attr :ain, true ;
  attr :aout, true ;
  attr :din, true ;
  attr :dout, true ;
  attr :button, true ;
  attr :led, true ;

  attr :logStrm, true ;

  ##--------------------------------------------------
  def initialize(conf = {})
    super(conf) ;
    
    setLogging(getConf(:log)) ;
    setDevice(getConf(:device)) ;
    setMode(getConf(:mode)) ;
  end

  ##--------------------------------------------------
  def setDevice(device)
    @device = device ;
    openStream() ;
  end

  ##--------------------------------------------------
  def openStream()
    if(@device)
      @recvMutex = Mutex.new() ;
      @recvMutex.lock() ;
      @strm = open(@device, "r+") ;
      recvThread = Thread.new() { safetyRun{ recvLoop() } } ;
      Thread.pass() while(@recvMutex.locked?)
    else
      @strm = nil ;
    end
  end

  ##--------------------------------------------------
  def send(com)
    if(@strm)
      logging(:send, com) ;
      @strm.write(com) ;
      @strm.write(EOL) ;
      @strm.flush ;
      return true ;
    else
      return false ;
    end
  end

  ##--------------------------------------------------
  def safetyRun(*args, &block)
    begin
      block.call(*args) ;
    rescue => exp then
      $stderr << exp.message << "\n" ;
      exp.backtrace.each{|trace|
        $stderr << "\t" << trace << "\n" ;
      }
    ensure
      exit() ;
    end
  end

  ##--------------------------------------------------
  def recv()
    if(@strm)
      res = @strm.readline(EOL) ;
      logging(:recv, res) ;
      return res ;
    else
      return nil ;
    end
  end

  ##--------------------------------------------------
  def recvLoop()
    @recvActiveCV = ConditionVariable.new() ;
    @recvPassiveCV = ConditionVariable.new() ;
    @recvMutex.unlock() ;
    while(true)
      res = recv() ;
      @recvMutex.synchronize{
        @lastMessage = res ;
        if(checkActiveResponse(res)) then
          @recvActiveCV.signal() ;
        else
          @recvPassiveCV.signal() ;
        end
      }
      Thread::pass() ;
    end
  end

  ##--------------------------------------------------
  def checkActiveResponse(res) 
    return (checkButton(res) ||
            checkAnalog(res) ||
            checkDigital(res) ||
            false)
  end

  ##--------------------------------------------------
  def sendrecv(com, raiseExpP = false)
    res = nil ;
    @recvMutex.synchronize{
      send(com) ;
      @recvPassiveCV.wait(@recvMutex) ;
      res = @lastMessage ;
    }
    if(raiseExpP && res =~ /^\!/) then
      raise "Illegal response from Gainer Mini: #{com} => #{res}" ;
    end
    return res ;
  end

  ##--------------------------------------------------
  def sendrecvCont(com, &block)
    @contEndP = false ;
    @recvMutex.synchronize{
      send(com) ;
      until(@contEndP)
        @recvActiveCV.wait(@recvMutex) ;
        res = @lastMessage ;
        block.call(res) ;
      end
    }
    sendrecv('E') ;
  end

  ##--------------------------------------------------
  def finishContinuousRecv()
    @contEndP = true ;
  end

  ##--------------------------------------------------
  def reset()
    begin
      res = sendrecv('Q') ;
    end until(res =~ /^Q/) 
    res = sendrecv('?', true) ;
    res.chop! ;
    if(res =~ /^\?(.*)$/)
      @version = $1 ;
    end
  end

  ##--------------------------------------------------
  def setMode(mode)
    if(mode)
      reset() ;
      case(mode)
      when 0 ;
        reset()
        mode
      when 1,2,3,4,5,6,7,8;
        sendrecv("KONFIGURATION_#{mode.to_s}") ;
        prepareMode(mode) ;
      else
        raise "Unknown mode: #{mode}" ;
      end
    end
  end

  ##--------------------------------------------------
  def prepareMode(mode)
    @button = nil ;
    @led = nil ;
    case mode
    when 1;
      @ain = Array.new(4) ;
      @aout = Array.new(4) ;
      @din = Array.new(4) ;
      @dout = Array.new(4) ;
    when 2;
      @ain = Array.new(8) ;
      @aout = Array.new(4) ;
      @din = nil ;
      @dout = Array.new(4) ;
    when 3;
      @ain = Array.new(4) ;
      @aout = Array.new(4) ;
      @din = Array.new(8) ;
      @dout = nil ;
    when 4;
      @ain = Array.new(8) ;
      @aout = Array.new(8) ;
      @din = nil ;
      @dout = nil ;
    when 5;
      @ain = nil ;
      @aout = nil ;
      @din = Array.new(16) ;
      @dout = nil ;
    when 6;
      @ain = nil ;
      @aout = nil ; 
      @din = nil ;
      @dout = Array.new(16) ;
    when 7;
      @ain = nil ;
      @aout = nil ;
      @din = nil ; 
      @dout = nil ;
      @col = Array.new(8) ;
      @row = Array.new(8) ;
    when 8;
      @ain = Array.new(4) ;
      @aout = nil ;
      @din = nil ;
      @dout = Array.new(4) ;
      @rc = Array.new(8) ;
    else
      raise "Unknown mode: #{mode}" ;
    end
  end

  ##--------------------------------------------------
  def setLED(onoff = true)
    if(onoff) then
      sendrecv('h') ;
      @led = true ;
    else
      sendrecv('l') ;
      @led = false ;
    end
  end

  ##--------------------------------------------------
  def getButton()
    return @button ;
  end

  ##--------------------------------------------------
  def getButtonLength()
    if(@button) then
      return Time.new() - @lastButtonPress ;
    else
      return 0 ;
    end
  end

  ##--------------------------------------------------
  def checkButton(res) 
    if(res =~ /^N/)
      @button = true ;
      @lastButtonPress = Time.new() ;
      return true ;
    elsif(res =~ /^F/) 
      @button = false ;
      @lastButtonRelease = Time.new() ;
      return true ;
    else
      return false ;
    end
  end

  ##--------------------------------------------------
  def setDigital(port, val = true)
    @dout[port] = val ;
    if(val)
      sendrecv("H#{port}") ;
    else
      sendrecv("L#{port}") ;
    end
  end

  ##--------------------------------------------------
  def getDigital(port = nil, &block)
    if(block.nil?)
      res = sendrecv('R') ;
      return scanDigital(res,port) ;
    else
      sendrecvCont('r'){|res|
        v = scanDigital(res,port) ;
        block.call(v) ;
      }
    end
  end

  ##--------------------------------------------------
  def scanDigital(res, port = nil) 
    v = res[1,4].hex ;
    (0...@din.length).each{|c|
      @din[c] = (v % 2 == 1) ;
      v = (v / 2).to_i ;
    }
    if(port.nil?)
      return @din ;
    else
      return @din[port] ;
    end
  end

  ##--------------------------------------------------
  def checkDigital(res) 
    if(res =~ /^r/)
      scanDigital(res) ;
      return true ;
    else
      return false ;
    end
  end

  ##--------------------------------------------------
  def setAnalog(port, val)
    val = val.to_i ;
    val = 0xff if(val > 0xff) ;
    val = 0 if(val < 0) ;
    @aout[port] = val ;
    sendrecv("a#{port}#{'%02X' % val}") ;
  end

  ##--------------------------------------------------
  def getAnalog(port = nil, &block)
    if(block.nil?)
      res = sendrecv('I') ;
      return scanAnalog(res,port) ;
    else
      sendrecvCont('i'){|res|
        v = scanAnalog(res,port) ;
        block.call(v) ;
      }
    end
  end

  ##--------------------------------------------------
  def scanAnalog(res, port = nil) 
    l = res.length() ;
    (0...(l-2)/2).each{|c|
      v = res[2*c+1,2].hex ;
      @ain[c] = v ;
    }
    if(port.nil?) then
      return @ain ;
    else
      return @ain[port]
    end
  end

  ##--------------------------------------------------
  def checkAnalog(res)
    if(res =~ /^i/)
      scanAnalog(res) ;
      return true ;
    else
      return false ;
    end
  end

  ##--------------------------------------------------
  def setLogging(logMode) ;
    @logStrm = [] if(@logStrm.nil?) ;
    if(logMode == true)
      @logStrm.push($stdout) ;
    elsif(logMode.is_a?(IO)) ;
      @logStrm.push(logMode) ;
    end
  end

  ##--------------------------------------------------
  def logging(tag, *args)
    timestr = Time.new.strftime('%Y-%m-%dT%H:%M:%S') 
    @logStrm.each{|strm|
      strm << '[' << timestr << '] ' ;
      strm << tag << ': '
      strm << args.join(', ') ;
      strm << "\n" ;
    }
  end

end ## class GainerMini


########################################################################
########################################################################
## for test
########################################################################
########################################################################
if($0 == __FILE__) then

  ##----------------------------------------------------------------------
  def methodName(offset = 0)
    if  /`(.*)'/.match(caller[offset]) ;
      return $1
    end
    nil
  end

  ##======================================================================
  class Test

    ##--------------------------------------------------
    def timestamp()
      Time.now.strftime("%Y.%m%d.%H%M%S") ;
    end

    ##--------------------------------------------------
    def listTest()
      list = [] ;
      methods().sort().each{|m|
        list.push(m) if (m =~ /^test_/) ;
      }
      return list ;
    end

    ##--------------------------------------------------
    def test_A()
      gm = GainerMini.new({ :device => '/dev/ttyACM0',
                            :mode => 1}) 
      p gm ;
      gm.reset() ;
    end

    ##--------------------------------------------------
    def test_B()
      gm = GainerMini.new({ :device => '/dev/ttyACM0',
                            :mode => 1}) 
      gm.reset() ;
      gm.setMode(1) ;
      s = 0.1 ;
      (0...30).each{
        gm.setLED(true) ;
        sleep(s) ;
        gm.setLED(false) ;
        sleep(s) ;
        p gm.getButtonLength() ;
      }
    end

    ##--------------------------------------------------
    def test_C()
      gm = GainerMini.new({ :device => '/dev/ttyACM0',
                            :mode => 1}) 
      gm.reset() ;
      gm.setMode(1) ;
      s = 0.1 ;
      (0...100).each{
        r = gm.getDigital() ;
        p r ;
        sleep(s) ;
      }
    end

    ##--------------------------------------------------
    def test_D()
      gm = GainerMini.new({ :device => '/dev/ttyACM0',
                            :mode => 1}) 
      gm.reset() ;
      gm.setMode(1) ;
      s = 0.1 ;
      c = 0
      gm.getDigital(){|res|
        p [c,res] ; c += 1;
        gm.finishContinuousRecv() if(c > 100) ;
      }
    end

    ##--------------------------------------------------
    def test_E()
      gm = GainerMini.new({ :device => '/dev/ttyACM0',
                            :mode => 1}) 
      gm.reset() ;
      gm.setMode(1) ;
      s = 0.1 ;
      (0...100).each{
        r = gm.getAnalog() ;
        p r ;
        sleep(s) ;
      }
    end

    ##--------------------------------------------------
    def test_F()
      gm = GainerMini.new({ :device => '/dev/ttyACM0',
                            :mode => 1}) 
      gm.reset() ;
      gm.setMode(1) ;
      s = 0.1 ;
      c = 0
      gm.getAnalog(){|res|
        p [c,res] ; c += 1;
        gm.finishContinuousRecv() if(c > 100000) ;
      }
    end

    ##--------------------------------------------------
    def test_G()
      gm = GainerMini.new({ :device => '/dev/ttyACM0',
                            :mode => 1}) 
      gm.reset() ;
      gm.setMode(1) ;
      s = 0.1 ;
      (0...100).each{|c|
        p [c] ;
        (0...4).each{|port|
          gm.setDigital(port, (c % 4 != port)) ;
        }
        sleep(1) ;
      }
    end

    ##--------------------------------------------------
    def test_H()
      gm = GainerMini.new({ :device => '/dev/ttyACM0',
                            :mode => 1}) 
      gm.reset() ;
      gm.setMode(1) ;
      s = 0.1 ;
      (0...100).each{|c|
        p [c] ;
        (0...4).each{|port|
          gm.setAnalog(port, (c * 10) % 0xff) ;
        }
        sleep(1) ;
      }
    end

    ##--------------------------------------------------
    def test_I()
      gm = GainerMini.new({ :device => '/dev/ttyACM0',
                            :mode => 1}) 
      gm.reset() ;
      gm.setMode(1) ;
      s = 0.1 ;
      (0...10000).each{|c|
        p [c] ;
        (0...4).each{|port|
          gm.setDigital(port, (c % 4 != port)) ;
        }
        p gm.getAnalog() ;
        sleep(0.1) ;
      }
    end

    ##--------------------------------------------------
    def test_J()
      gm = GainerMini.new({ :device => '/dev/ttyACM0',
                            :mode => 1}) 
      gm.reset() ;
      gm.setMode(1) ;
      gm.sendrecv('G00') ;
      s = 0.1 ;
      (0...10000).each{|c|
        p gm.getAnalog(0) ;
        sleep(0.1) ;
      }
    end


  end

  ##################################################
  ##################################################
  ##################################################

  myTest = Test.new() ;
  if(ARGV.length > 0) then
    ARGV.each{|testMethod|
      if(myTest.listTest.member?(testMethod))
        p [:try, testMethod] ;
        myTest.send(testMethod) ;
      else
        puts("Error: unknown test: #{testMethod}\n" + 
             "\t'Test' should be one of :" +
             myTest.listTest.join(", "))
        raise ("unknown test method.") ;
      end
    }
  else
    myTest.listTest().each{|testMethod|
      puts '-' * 50
      p [:try, testMethod] ;
      myTest.send(testMethod) ;
    }
  end
  
end

