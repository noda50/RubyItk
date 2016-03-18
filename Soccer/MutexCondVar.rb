## -*- Mode: Ruby -*-

require "thread" ;

##======================================================================
## MutexCondVar
##----------------------------------------------------------------------

class MutexCondVar
  attr :mutex		,true ;
  attr :cv		,true ;

  def initialize()
    @mutex = Mutex.new() ;
    @cv = ConditionVariable.new() ;
  end

  def lock()
    @mutex.lock() ;
  end

  def unlock()
    @mutex.unlock() ;
  end

  def wait()
    @cv.wait(@mutex) ;
  end

  def lockedWait()
    lock() ;
    wait() ;
    unlock() ;
  end

  def signal()
    @cv.signal() ;
  end

  def lockedSignal() 
    lock() ;
    signal() ;
    unlock() ;
  end

  def broadcast()
    @cv.broadcast() ;
  end

  def lockedBroadcase() 
    lock();
    broadcast() ;
    unlock() ;
  end

end

