#! /usr/bin/env ruby
## -*- mode: ruby -*-

##----------------------------------------------------------------------
$LOAD_PATH.push("~/lib/ruby").uniq! ; 

require 'zlib' ;
require 'ItkXml.rb' ;
require 'pp' ;

##======================================================================
class Dia
  
  ##==================================================
  class Object

    ##::::::::::::::::::::::::::::::
    Type = {
      "Standard - Line" 	=> :line,
      "Standard - Box" 		=> :box,
      "Standard - Ellipse" 	=> :ellipse,
      "Standard - Text" 	=> :text,
      "Standard - Image"	=> :image,
      nil => nil } ;

    ##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    attr :xml, true ;
    attr :type, true ;
    attr :typeName, true ;
    attr :id, true ;
    attr :attribute, true ;
    attr :value, true ;
    attr :connection, true ;
    attr :connectedFrom, true ;
    attr :label, true ;

    ##------------------------------
    def initialize(xml = nil)
      @attribute = {} ;
      @connectedFrom = [] ;
      scanXml(xml) ;
    end

    ##------------------------------
    def scanXml(xml)
      @xml = xml ;
      @id = XML::XPath.first(@xml, "@id").to_s ;
      @typeName = XML::XPath.first(@xml, "@type").to_s ;
      @type = getTypeByName(@typeName) ;
      scanAttribute(@xml) ;
      @value = getValueByType() ;
#      p [@id,@type] ;
    end

    ##------------------------------
    def getTypeByName(typeName)
      ty = Type[typeName] ;
      warn("Uknown Dia Object Type:" + typeName) if(ty.nil?) ;

      return (ty || typeName)
    end

    ##------------------------------
    def scanAttribute(xml)
      XML::XPath.each(xml, "dia:attribute"){|attr|
        name = attr.attributes["name"] ;
        @attribute[name] = attr ;
      }
    end

    ##------------------------------
    def getValueByType()
      case @type
      when :line ;
        return getValueByType_Line() ;
      when :box ;
        return getValueByType_Box() ;
      when :ellipse ;
        return getValueByType_Ellipse() ;
      when :text ;
        return getValueByType_Text() ;
      when :image ;
        return getValueByType_Image() ;
      end
    end

    ##------------------------------
    def getValueByType_Line()
      node = @attribute["conn_endpoints"] ;
      if(node)
        pointList = [] ;
        XML::XPath.each(node, "./dia:point/@val") {|str|
          if(str.to_s =~ /^(.*),(.*)$/) then
            (x, y) = [$1.to_f, $2.to_f] ;
            pointList.push([x,y]) ;
          end
        }
        line = Geo2D::LineString.new(pointList) ;
#        p line ;
        return line ;
      end
      return nil ;
    end

    ##------------------------------
    def getValueByType_Box()
      node = @attribute["obj_bb"] ;
      if(node)
        str = XML::XPath.first(node, "./dia:rectangle/@val") ;
        if(str) then
          data = str.to_s ;
          if(data =~ /^(.*),(.*);(.*),(.*)$/) then
            (x0, y0, x1, y1) = [$1,$2,$3,$4].map{|v| v.to_f} ;
            box = Geo2D::Box.new([x0, y0], [x1, y1]) ;
#            p box ;
            return box ;
          end
        end
      end
      return nil ;
    end

    ##------------------------------
    def getValueByType_Ellipse()
      return getValueByType_Box() ;
    end

    ##------------------------------
    def getValueByType_Text()
      node = @attribute["text"] ;
      if(node)
        str = XML::XPath.first(node, 
                               ".//dia:attribute[@name='string']/dia:string");
        if(str) then
          data = str.texts.to_s ;
          if(data =~ /^\#(.*)\#$/) then
            data = $1 ;
          end
          return data ;
        end
      end
      return nil ;
    end

    ##------------------------------
    def getValueByType_Image()
      node = @attribute["file"] ;
      if(node)
        str = XML::XPath.first(node, ".//dia:string") ;
        if(str)
          data = str.texts.to_s ;
          if(data =~ /^\#(.*)\#$/) then
            data = $1 ;
          end
          return data ;
        else
          return nil ;
        end
      else
        return nil ;
      end
    end

    ##------------------------------
    def assignConnection(dia)
      @connection = [] ;
      XML::XPath.each(@xml, "./dia:connections/dia:connection"){|con|
        c = Connection.new(con, self, dia) ;
        @connection.push(c) ;
        c.to.connectedFrom.push(c) ;
      }
    end

    ##------------------------------
    def anotherConnection(connection)
      @connection.each{|con|
        return con if (connection != con) ;
      }
      return nil ;
    end

  end # class Dia::Object

  ##==================================================
  class Connection

    ##::::::::::::::::::::::::::::::

    ##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    attr :xml, true ;
    attr :handle, true ;
    attr :from, true ;
    attr :to, true ;
    attr :port, true ;

    ##------------------------------
    def initialize(xml = nil, from = nil, dia = nil)
      setupByXml(xml, from, dia) ;
    end

    ##------------------------------
    def setupByXml(xml, from, dia)
      @xml = xml ;
      @from = from ;
      if(xml && from && dia) then
        @handle = xml.attributes['handle'].to_s ;
        toId = xml.attributes['to'].to_s ;
        @to = dia.objectTable[toId] ;
        @port = xml.attributes['connection'] ;
      end
    end

    ##------------------------------
    def anotherEnd(object)
      return ((object == @from) ? @to :
              (object == @to) ? @from :
              nil) ;
    end

  end # class Connection

  ##::::::::::::::::::::::::::::::::::::::::::::::::::

  ##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  attr :doc, true ;
  attr :objectList, true ;
  attr :objectTable, true ;
  attr :typedList, true ;
  attr :labeledList, true ; ## text に結び付けられているオブジェクト

  ##--------------------------------------------------
  def initialize()
    @objectList = [] ;
    @objectTable = {} ;
    @typedList = {} ;
    @labeledList = {} ;
  end

  ##--------------------------------------------------
  def scanFile(file)
    Zlib::GzipReader.open(file){|gz|
      scanStream(gz) ;
    }
  end

  ##--------------------------------------------------
  def scanStream(strm)
    scanXml(XML::Document.new(strm)) ;
  end

  ##--------------------------------------------------
  def scanXml(xml)
    @doc = xml ;
    XML::XPath.each(@doc.root, "//dia:object"){|objXml|
      obj = Dia::Object.new(objXml) ;
      addObject(obj) ;
    }
    assignAllConnections() ;
    assignAllLabels() ;
  end

  ##--------------------------------------------------
  def addObject(obj)
    @objectList.push(obj) ;
    @objectTable[obj.id] = obj ;
    getTypedList(obj.type).push(obj) ;
  end

  ##--------------------------------------------------
  def getTypedList(type) 
    list = @typedList[type] ;
    if(list.nil?) 
      list = [] ;
      @typedList[type] = list ;
    end
    return list ;
  end

  ##--------------------------------------------------
  def getLabeledList(label)
    list = @labeledList[label] ;
    if(list.nil?) 
      list = [] ;
      @labeledList[label] = list ;
    end
    return list ;
  end

  ##--------------------------------------------------
  def assignAllConnections()
    @objectList.each{|obj|
      obj.assignConnection(self) ;
    }
  end

  ##--------------------------------------------------
  def assignAllLabels()
    @typedList[:text].each{|text|
      text.connection.each{|con|
        getLabeledList(text.value).push(con.to) ;
        con.to.label = text ;
      }
    }
  end

end # class Dia

##======================================================================
class << Dia

end # class << Dia

########################################################################
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
    SampleFile = "/usr/users/noda/work/iss/ServiceSim/Ganko/Data/Images/map.diagram.b1.dia" ;

    def test_A()
      dia = Dia.new() ;
      dia.scanFile(SampleFile) ;
      pp dia.labeledList ;
    end

    ##--------------------------------------------------
    def test_B()
      dia = Dia.new() ;
      dia.scanFile(SampleFile) ;
      dia.getTypedList(:text).each{|text|
        pp text ;
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
  
end # if($0 == __FILE__) 


