#! /usr/bin/env ruby
## -*- mode: ruby -*-
## = Itk's Socket Info utility
## Author:: Itsuki Noda
## Version:: 0.0 2015/02/23 I.Noda
##
## === History
## * [2015/02/23]: Create This File.
## * [YYYY/MM/DD]: add more
## == Usage
## * ...

$LOAD_PATH.push("~/lib/ruby");

require 'pp' ;

module Itk
  #--======================================================================
  #++
  ## SocketInfo
  class SocketInfo
    #--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    #++
    ## description of DefaultValues.
    TcpSocketInfoPath = "/proc/net/tcp"

    #--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    #++
    ## label list taken from the first line
    attr :tcpSockLabelList, true ;
    ## list of Hash of socket information
    attr :tcpSockInfoTable, true ;

    #--------------------------------------------------------------
    #++
    ## 初期化
    ## _scanP_:: scanを実行するかどうか
    def initialize(scanP = true)
      if(scanP)
        scanTcpSockInfo() ;
      end
    end

    #--------------------------------------------------------------
    #++
    ## scan
    ## *return*:: about return value
    def scanTcpSockInfo()
      @tcpSockInfoTable = {} ;
      open(TcpSocketInfoPath,"r") {|strm|
        while(line = strm.gets)
          if(@tcpSockLabelList.nil?) then
            @tcpSockLabelList = line.split() ;
          else
            line.gsub!(/^\s*/,'');
            data = line.split(/[\s:]+/) ;
            table = {} ;
            @tcpSockLabelList.each{|col|
              table[col] = data.shift ;
              if(col =~ /address$/) then
                port = data.shift ;
                portName = col.gsub(/address$/,'') + "port" ;
                table[portName] = port.hex ;
              end
            }
            table[@tcpSockLabelList.last] += " " + data.join(" ") ;
            @tcpSockInfoTable[table["local_port"]] = table ;
          end
        end
      }
      return @tcpSockInfoList ;
    end

    #--------------------------------------------------------------
    #++
    ## find socket
    ## *return*:: about return value
    def findTcpSockInfo(port)
      return @tcpSockInfoTable[port] ;
    end

    #--------------------------------------------------------------
    #++
    ## find socket
    ## *return*:: about return value
    def findFreeTcpPort(startPort, repeatCheckP = false)
      scanTcpSockInfo() if(repeatCheckP) ;
      if(findTcpSockInfo(startPort))
        return findFreeTcpPort(startPort + 1, repeatCheckP) ;
      else
        return startPort ;
      end
    end
  end # class SocketInfo
end # module Itk

########################################################################
########################################################################
########################################################################
if($0 == __FILE__) then

  require 'test/unit'

  #--============================================================
  #++
  ## unit test for this file.
  class TC_Foo < Test::Unit::TestCase
    #--::::::::::::::::::::::::::::::::::::::::::::::::::
    #++
    ## desc. for TestData
    TestData = nil ;

    #----------------------------------------------------
    #++
    ## show separator and title of the test.
    def setup
#      puts ('*' * 5) + ' ' + [:run, name].inspect + ' ' + ('*' * 5) ;
      name = "#{(@method_name||@__name__)}(#{self.class.name})" ;
      puts ('*' * 5) + ' ' + [:run, name].inspect + ' ' + ('*' * 5) ;
      super
    end

    #----------------------------------------------------
    #++
    ## about test_a
    def test_a
      pp [:test_a] ;
    end

  end # class TC_Foo < Test::Unit::TestCase
end # if($0 == __FILE__)
