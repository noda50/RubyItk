## -*- Mode: ruby -*-

require "rexml/document" ;
require "rexml/parsers/sax2parser" ;
require "rexml/sax2listener" ;

module ItkXml

  include REXML ;

  ##======================================================================
  ## class MonitorListener
  ##   record all data into string buffer during @record is true ;

  class MonitorListener 

    include REXML ;
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

    include REXML ;
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
  ## class ItkXMLFilter

  class XmlFilter < Parsers::SAX2Parser

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

  ##======================================================================
  ## class ScanListener

  class BaseScanListener
    include REXML ;
    include SAX2Listener ;

    ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ## instance variables
    attr :scanP, 	true ;
    attr :nodeStack,	true ;
    attr :topNode,	true ;
    attr :watcher,	true ;
    attr :cycleProc,	true ;

    ##----------------------------------------
    ## initializer

    def initialize()
      @scanP = false ;
      @nodeStack = [] ;
      @topNode = nil ;
      @watcher = [] ;
      @cycleProc = nil ;
    end

    ##----------------------------------------
    ## watcher operation

    ##--------------------
    ## add watching element

    def addWatchingElement(name)
      if(name.is_a?(Array)) then
	name.each{ |n| 
	  addWatchingElement(n);
	}
      else
	@watcher.push(name) ;
      end
    end

    ##--------------------
    ## check watching element

    def isWatchedElement?(uri, local, qname, attributes)
      @watcher.each{ |w|
	r = false ;
	case w.class.name
	when 'String' ; r = (w == qname) ;
	when 'Regexp' ; r = (w =~ qname) ;
	end
	return true if r ;
      }
      return false ;
    end

    ##----------------------------------------
    ## SAX operations

    ##--------------------
    ## start_element

    def start_element(uri, local, qname, attributes) 
      @scanP = isWatchedElement?(uri, local, qname, attributes) if (!@scanP) ;

      pushElement(uri, local, qname, attributes) if(@scanP) ;
    end

    ##--------------------
    ## pushElement

    def pushElement(uri, local, qname, attributes)
      element = Element::new(qname) ;
      element.add_attributes(attributes) ;

      parent = @nodeStack.last() ;
      if(parent.nil?) then
	@topNode = element if(parent.nil?) ;
      else
	parent.add(element) if (! parent.nil?) ;
      end
      @nodeStack.push(element) ;
    end

    ##--------------------
    ## end_element

    def end_element(uri,local,qname)
      if(@scanP) then
	element = @nodeStack.pop() ;
	
	if(element.nil?) then
	  raise "something is wrong in scanning element: </#{qname}>" ;
	end

	if(@nodeStack.size == 0)
	  cycle(@topNode) ;
	  @scanP = false ;
	  @topNode = nil ;
	end
      end
    end

    ##--------------------
    ## characters

    def characters(text)
      if(@scanP)
	parent = @nodeStack.last() ;
	parent.add(Text::new(text)) ;
      end
    end

    ##----------------------------------------
    ## cycle operation (default operation)

    ##--------------------
    ## cycle

    def cycle(node)
      if(!@cycleProc.nil?)
	@cycleProc.call([node]) ;
      else
	defaultCycle(node) ;
      end
    end

    ##--------------------
    ## default cycle

    def defaultCycle(node)
      $stdout << "Default cycle operation for #{self.class().to_s} :\n" ;
      $stdout << node.to_s << "\n" ;
    end

    ##--------------------
    ## register cycle

    def registerCycleProc(&proc)
      @cycleProc = proc ;
    end

  end

  ##======================================================================
  ## class ScanFilter

  class ScanFilter < Parsers::SAX2Parser

    attr :scanListener, true ;

    def setup(tagNames, 
	      scanListenerClass = BaseScanListener) 
      @scanListener = scanListenerClass.new() ;
      addWatchingElement(tagNames) ;
      listen(@scanListener) ;
    end

    def run()
      begin 
	parse() ;
      rescue EndOfParsingException 
      end
    end

    def addWatchingElement(tagName)
      @scanListener.addWatchingElement(tagName) ;
    end

    def registerCycleProc(&proc)
      registerCycleProc(&proc) 
    end
  end

end
