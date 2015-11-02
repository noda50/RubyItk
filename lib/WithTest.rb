##  -*- Mode: ruby -*-

require 'thread' ;
require 'TimeDuration.rb' ;
require 'Itk/ItkThreadPool.rb' ;

##----------------------------------------------------------------------
def methodName(offset = 0)
  if  /`(.*)'/.match(caller[offset]) ;
    return $1
  end
  nil
end

##======================================================================
module Itk

  ##============================================================
  class WithTest
    ##::::::::::::::::::::::::::::::::::::::::
    TimestampFormat = "%Y.%m%d.%H%M%S" ;
    TestMethodPrefix = "test_" ;

    ##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    ##----------------------------------------
    def timestamp()
      Time.now.strftime(self.class::TimestampFormat)
    end

    ##----------------------------------------
    def listTestMethods()
      list = [] ;
      pattern = /^#{self.class::TestMethodPrefix}/ ;
      methods().sort().each{|m|
        list.push(m) if (m =~ pattern) ;
      }
      return list ;
    end

    ##----------------------------------------
    def listTestMethodSuffixes()
      list = listTestMethods() ;
      list.map{|name|
        name.to_s.gsub(/^#{self.class::TestMethodPrefix}/,'') ;
      }
    end

    ##----------------------------------------
    def isMember?(testName)
      listTestMethods.member?(testName)
    end

    ##----------------------------------------
    def runTest(testName,*opts)
      if(isMember?(testName)) then
        t = TimeDuration.new() {
          self.send(testName,*opts) ;
        }
        r = [:exp, testName, t.sec, t.endTime] ;
        return r ;
      else
        return nil ;
      end
    end

    ##----------------------------------------
    def joinTestMethod(suffix)
      self.class::TestMethodPrefix + suffix.to_s ;
    end

    ##----------------------------------------
    def isMemberSuffix?(suffix)
      isMember?(joinTestMethod(suffix)) ;
    end

    ##----------------------------------------
    def runBySuffix(suffix, *opts)
      runTest(joinTestMethod(suffix), *opts) ;
    end

    ##----------------------------------------
    def run(nameOrSuffix, *opts)
      if(nameOrSuffix.to_s =~ /^#{joinTestMethod('')}/) then
        return runTest(nameOrSuffix, *opts) ;
      else
        return runBySuffix(nameOrSuffix, *opts) ;
      end
    end

  end # class WithTest

  ##============================================================
  class ThreadPool_obsoleted

    ##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    attr :max, true ;
    attr :count, true ;
    attr :mutexList, true ;
    attr :queue, true ;
    attr :threadTable, true ;

    ##----------------------------------------
    def initialize(max)
      @max = max ;
      @count = 0 ;
      @mutexList = (0...@max).map{ Mutex.new() } ;
      @threadTable = {} ;
      @queue = Queue.new() ;
      @mutexList.each{|mx| @queue.push(mx)} ;
    end

    ##----------------------------------------
    def nextMutex()
      @count += 1 ;
      return @queue.pop() ;
    end

    ##----------------------------------------
    def releaseMutex(mx)
      return @queue.push(mx) ;
    end

    ##----------------------------------------
    def fork(*args,&block)
      mx = nextMutex() ;
      th = Thread.new() {
        mx.synchronize(*args){|*iargs|
          block.call(*iargs) ;
        }
        self.releaseMutex(mx) ;
      }
      @threadTable[mx] = th ;
      return mx ;
    end

  end




end # module Itk
