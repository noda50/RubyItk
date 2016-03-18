## -*- Mode: ruby -*-

require "rexml/document" ;
require "rexml/parsers/sax2parser" ;
require "rexml/sax2listener" ;

include REXML ;

##======================================================================
## class MonitorListener

class MonitorListener 
  include SAX2Listener ;
  
  ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## instance variables
  attr :record, true ;
  attr :buffer,	true ;

  ##----------------------------------------
  ## constructor

  def initialize()
    @record = false ;
    clearBuffer ;
  end

  ##----------------------------------------
  ## buffer operation

  ##--------------------
  ## clear buffer

  def clearBuffer() 
    @buffer = "" ;
  end

  ##--------------------
  ## fetch buffer

  def fetchBuffer()
    r = buffer ;
    clearBuffer() ;
    return r ;
  end

  ##----------------------------------------
  ## record switch

  ##--------------------
  ## start record

  def recordOn()
    @record = true ;
  end

  ##--------------------
  ## stop record

  def recordOff()
    @record = false ;
  end

  ##----------------------------------------
  ## SAX operations

  ##--------------------
  ## start_element

  def start_element(uri,local,qname,attributes) 
    if(@record)
      @buffer << "<%s" % [qname] ;
      attributes.each{|key,value|
	@buffer << " %s='%s'" % [key,value] ;
      }
      @buffer << ">" ;
    end
  end

  ##--------------------
  ## end_element

  def end_element(uri,local,qname) 
    if(@record)
      @buffer << "</%s" % [qname] ;
      @buffer << ">" ;
    end
  end

  ##--------------------
  ## characters

  def characters(text)
    if(@record)
      @buffer << text ;
    end
  end

end

##======================================================================
## class EndOfParsingException

class EndOfParsingException < Exception
end

##======================================================================
## class SwitcherListener

class BaseSwitcherListener 
  include SAX2Listener ;

  ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## attributes

  attr :tagNames,	true ;
  attr :parser,		true ;
  attr :monitor,	true ;

  ##----------------------------------------
  ## constructor

  def initialize(tagNames,parser,monitor)
    @tagNames = tagNames ;
    @parser = parser ;
    @monitor = monitor ;
    if(@tagNames.nil?())
      @parser.listen(self) ;
    else
      @parser.listen(@tagNames,self) ; 
    end
    @parser.listen(@monitor) ; ## order of listen is important
  end

  ##----------------------------------------
  ## SAX operations

  ##--------------------
  ## start_element

  def start_element(uri,local,qname,attributes) 
    @monitor.recordOn() ;
  end

  ##--------------------
  ## end_element

  def end_element(uri,local,qname) 
    @monitor.end_element(uri,local,qname) ;  ## little bit tricky
    monitor.recordOff() ;
    cycle(uri,local,qname) ;
  end

  ##----------------------------------------
  ## cycle operation 

  def cycle(uri,local,qname)
    ## do nothing
  end

end

##======================================================================
## class SwitcherListener

class SimpleSwitcherListener < BaseSwitcherListener
  
  attr :strm, true ;

  def initialize(tagNames,parser,monitor)
    @strm = $stdout ;
    super
  end
    
  def cycle()
    @strm << @monitor.fetchBuffer() ;
  end

end

##======================================================================
## class MyXMLFilter

class MyXMLFilter < Parsers::SAX2Parser

  attr :switcher ;
  attr :monitor ;

  def setup(tagNames, 
	    switcherClass = SimpleSwitcherListener, 
	    monitorClass = MonitorListener)
    @monitor = monitorClass.new() ;
    @switcher = switcherClass.new(tagNames,self,@monitor) ;
  end

  def run()
    begin 
      parse() ;
    rescue EndOfParsingException 
    end
  end

end

