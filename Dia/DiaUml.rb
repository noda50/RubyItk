#! /usr/bin/env ruby
## -*- mode: ruby -*-

require 'rexml/document'
module XML
  include REXML
end

#--============================================================
#++
## Dia file parser
class Dia
  module Utility ; end ;
  include Utility ;

  #--::::::::::::::::::::::::::::::::::::::::::::::::::
  #++
  #--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  #++
  ## source file
  attr :srcFiles, true ;
  ## XML Document
  attr :doc, true ;
  ## Layer Table
  attr :layerTable, true ;
  ## Object Table
  attr :objectTable, true ;
  ##
  #----------------------------------------------------
  #++
  ##
  def initialize(srcFile = nil)
    @srcFiles = [] ;
    readFile(srcFile) if(srcFile) ;
    @layerTable = HashedArray.new([:id]) ;
    @objectTable = HashedArray.new([:id]) ;
  end

  #----------------------------------------------------
  #++
  ##
  def readFile(filename)
    @srcFiles.push(filename) ;
    open(filename,"r"){|strm|
      @doc = XML::Document.new(strm) ;
    }
  end

  #----------------------------------------------------
  #++
  ##
  def scanEachLayer(&block)
    XML::XPath.each(@doc.root,"//dia:layer"){|layer|
      block.call(layer) ;
    }
  end

  #----------------------------------------------------
  #++
  ##
  def scanEachObject(&block)
    scanEachLayer{|layer|
      XML::XPath.each(layer,"//dia:object"){|object|
        block.call(object) ;
      }
    }
  end

  #----------------------------------------------------
  #++
  ##
  def addObject(object)
    addToTable(@objectTable, object) ;
  end

  #----------------------------------------------------
  #++
  ##
  def eachObject(&block)
    @objectTable.each{|object|
      block.call(object) ;
    }
  end

  #----------------------------------------------------
  #++
  ##
  def getObject(id) ;
    @objectTable.get(:id, id) ;
  end

end #class Dia

class Dia
  #--==================================================
  #++
  ##
  module Utility
    #--------------------------------
    #++
    ##
    def getAttributeFromNode(node,name)
      XML::XPath.first(node,"dia:attribute[@name='#{name}']") ;
    end

    #--------------------------------
    #++
    ##
    def getAttributeStringFromNode(node,name)
      attrNode = getAttributeFromNode(node,name) ;
      if(attrNode)
        value = XML::XPath.first(attrNode,"dia:string").texts.to_s ;
        value.gsub!(/^\#(.*)\#$/m,"\\1") ;
        return value ;
      else
        return nil ;
      end
    end

    #--------------------------------
    #++
    ##
    def addToTable(table, object)
      table.push(object) ;
    end

  end # module Utility
end # class Dia

class Dia
  #--==================================================
  #++
  ##
  class Uml < Dia
    #--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    #++
    ##
    attr :classTable, true ;
    attr :generalizationTable, true ;
    attr :packageTable, true ;
    attr :associationTable, true ;
    #------------------------------------------
    #++
    ##
    def initialize(srcFile)
      super
      @classTable = HashedArray.new([:id,:name]) ;
      @generalizationTable = HashedArray.new([:id]) ;
      @packageTable = HashedArray.new([:id,:name]) ;
      @associationTable = HashedArray.new([:id]) ;

      scan() ;
    end

    #------------------------------------------
    #++
    ##
    def addFile(srcFile)
      readFile(srcFile) ;
      scan() ;
    end

    #------------------------------------------
    #++
    ##
    def scan()
      scanEachObject{|object|
        type = object.attribute('type').value
        case(type)
        when("UML - Class") ;
          addClass(object) ;
        when("UML - Generalization") ;
          addGeneralization(object) ;
        when("UML - LargePackage") ;
          addLargePackage(object) ;
        when("UML - Association") ;
          addAssociation(object) ;
        else
          raise("unknown UML type: #{type}") ;
        end
      }
      linkReferences() ;
    end

    #------------------------------------------
    #++
    ##
    def linkReferences()
      eachObject(){|object|
        object.linkReferences(self) ;
      }
    end

    #------------------------------------------
    #++
    ##
    def addClass(object)
      klass = Klass.new(object) ;
      addObject(klass) ;
      addToTable(@classTable, klass) ;
    end

    #------------------------------------------
    #++
    ##
    def addGeneralization(object)
      gen = Generalization.new(object) ;
      addObject(gen) ;
      addToTable(@generalizationTable, gen) ;
    end

    #------------------------------------------
    #++
    ##
    def addLargePackage(object)
      package = Package.new(object) ;
      addObject(package) ;
      addToTable(@packageTable,package) ;
    end

    #------------------------------------------
    #++
    ##
    def addAssociation(object)
      assoc = Association.new(object) ;
      addObject(assoc) ;
      addToTable(@associationTable,assoc) ;
    end

    #------------------------------------------
    #++
    ##
    def eachClass(&block)
      @classTable.each{|klass|
        block.call(klass) ;
      }
    end

    #------------------------------------------
    #++
    ##
    def eachGeneralization(&block)
      @generalizationTable.each{|gen|
        block.call(gen) ;
      }
    end

    #------------------------------------------
    #++
    ##
    def eachPackage(&block)
      @packageTable.each{|package|
        block.call(package) ;
      }
    end

    #------------------------------------------
    #++
    ##
    def eachAssociation(&block)
      @associationTable.each{|assoc|
        block.call(assoc) ;
      }
    end

  end # class Dia::Uml
end #class Dia

class Dia
  class Uml
    #--========================================
    #++
    ##
    class ObjectBase
      include Utility
      #--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
      #++
      ##
      attr :document, true ;
      attr :xml, true ;
      attr :id, true ;
      attr :parent, true ;
      attr :name, true ;

      #--------------------------------
      #++
      ##
      def initialize(object,doc = nil)
        @document = doc ;
        @xml = object ;
        @id = object.attribute('id').value ;
        scan() ;
      end

      #--------------------------------
      #++
      ##
      def scan()
        scanParent() ;
        scanName() ;
        scanSub() ;
      end

      #--------------------------------
      #++
      ##
      def scanSub() 
      end

      #--------------------------------
      #++
      ##
      def scanParent()
        if(parentInfo = XML::XPath.first(@xml,"dia:childnode"))
          @parent = parentInfo.attribute("parent").value ;
        end
      end

      #--------------------------------
      #++
      ##
      def scanName()
        @name = getAttributeString("name") ;
      end

      #--------------------------------
      #++
      ##
      def getAttribute(name)
        getAttributeFromNode(@xml,name) ;
      end

      #--------------------------------
      #++
      ##
      def getAttributeString(name)
        getAttributeStringFromNode(@xml, name) ;
      end

      #--------------------------------
      #++
      ##
      def linkReferences(umlDoc)
        if(@parent.is_a?(String))
          pobj = umlDoc.getObject(@parent) ;
          if(pobj)
#            p [:link, :parent, self.to_s, @parent, pobj.to_s] ;
            @parent = pobj ;
          else
            raise "unknown ID:#{@parent} in object:#{self}" ;
          end
        end
      end

    end # class ObjectBase
  end # class Uml
end # class Dia

class Dia
  class Uml
    #--========================================
    #++
    ##
    class Klass < ObjectBase
      #--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
      #++
      ##
      attr :comment, true ;
      attr :umlAttributeTable, true ;
      attr :parentClasses, true ;

      #--------------------------------
      #++
      ##
      def scanSub()
        @umlAttributeTable = HashedArray.new([:name]) ;
        @comment = getAttributeString("comment") ;
        scanUmlAttributes() ;
        @parentClasses = [] ;
      end

      #--------------------------------
      #++
      ##
      def scanUmlAttributes()
        scanEachComposite{|comp|
          attr = Attribute.new(comp,self) ;
          @umlAttributeTable.push(attr) ;
        }
#        p [:class, @name, @umlAttributeTable] ;
      end

      #--------------------------------
      #++
      ##
      def scanEachComposite(&block)
        attrsNode = getAttribute('attributes') ;
        if(attrsNode) then
          XML::XPath.each(attrsNode,
                          "dia:composite[@type='umlattribute']"){|comp|
            block.call(comp) ;
          }
        end
      end

      #--------------------------------
      #++
      ##
      def inheritClass(parentClass)
        @parentClasses.push(parentClass) ;
      end

      #--------------------------------
      #++
      ##
      def toRubyDef(expandp = false, indent = "")
        tab = "  " ;
        ind0 = "\n" + indent ;
        ind1 = ind0 + tab ;
        defstr = "" ;
        ## comment (in RDoc style)
        defstr << ind0 << '##' ;
        @comment.split("\n").each{|com|
          defstr << ind0 << '#' << com ;
        }
        ## start class definition
        defstr << ind0 << "class #{@name}" ;
        ## inherited classes
        if(!expandp) then
          @parentClasses.each{|pclass| 
            defstr << " < #{pclass.name}" ;
          }
        end
        ## parent attributes
        defstr << toRubyDefAttribute(expandp, ind1) ;
        ## ending
        defstr << ind0 << "end" ;
        defstr << "\n" ;
        defstr ;
      end

      #--------------------------------
      #++
      ##
      def toRubyDefAttribute(expandp, indent, inheritStack = [])
        defstr = "" ;
        attrList = collectAttributesWithOverride(expandp) ;

        preKlassName = nil ;
        attrList.each{|attrGroup|
          klassName = attrGroup.first.klass.name ;
          if(klassName != preKlassName) then
            defstr << indent << "\#\#\# inheried from #{klassName}" ;
          end
          defstr << attrGroup.last.toRubyDef(indent) ;
          preKlassName = klassName ;
        }
        defstr ;
      end

      #--------------------------------
      #++
      ## collect attrubutes with override information.
      # return:: [<attrGroup>, <attrGroup>, ...]
      # <attrGroup> :: [<attr>, <attr>, ...] ; attrs. with the same name.
      #
      def collectAttributesWithOverride(expandp, attrList = [])
        # collect attributes in parent klasses
        if(expandp)
          @parentClasses.each{|klass|
            klass.collectAttributesWithOverride(expandp, attrList) ;
          }
        end
        @umlAttributeTable.each{|attr|
          group = nil ;
          attrList.each{|attrGroup|
            if(attrGroup.first.name == attr.name) then
              group = attrGroup ;
              break ;
            end
          }
          if(group) then
            group.push(attr) ;
          else
            attrList.push([attr]) ;
          end
        }
        attrList ;
      end

      #--------------------------------
      #++
      ##
      def checkAttributeOverride(attribute, inheritStack = [])
        inheritStack.each{|pclass|
          overridingAttr = pclass.umlAttributeTable.get(:name, attribute.name) ;
          if(overridingAttr) then
            overridingAttr.overrideFrom = attribute ;
            return overridingAttr ;
          end
        }
        return nil ;
      end

    end # class Klass
  end # class Uml
end # class Dia

class Dia
  class Uml
    class Klass
      #--==============================
      #++
      ##
      class Attribute
        include Utility
        #--@@@@@@@@@@@@@@@@@@@@
        #++
        attr :name, true ;
        attr :type, true ;
        attr :value, true ;
        attr :comment, true ;

        attr :klass, true ;
        attr :overrideFrom, true ;
        
        #----------------------
        #++
        ##
        def initialize(compNode,klass)
          @name = getAttributeStringFromNode(compNode,"name") ;
          @type = getAttributeStringFromNode(compNode,"type") ;
          @value = getAttributeStringFromNode(compNode,"value") ;
          @comment = getAttributeStringFromNode(compNode,"comment") ;
          @klass = klass ;
        end

        #--------------------------------
        #++
        ##
        def toRubyDef(indent = "")
          defstr = "" ;
          defstr << indent << "\#\# #{@name}:: type: #{@type}" ;
          defstr << "; value=#{@value}" if(@value.length>0) ;
          @comment.to_s.split("\n").each{|com|
              defstr << indent << "\# " << com
          }
          defstr << indent << "attr \:#{@name}, true ;" ;
          defstr
        end
      end # class Attribute

    end # class Klass
  end # class Uml
end # class Dia

class Dia
  class Uml
    #--========================================
    #++
    ##
    class Generalization < ObjectBase
      #--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
      #++
      ##
      attr :from, true ;
      attr :to, true ;

      #--------------------------------
      #++
      ##
      def scanSub()
        XML::XPath.each(@xml,"dia:connections/dia:connection"){|connection|
          handle = connection.attribute('handle').value() ;
          connectTo = connection.attribute('to').value() ;
          case(handle)
          when("0") ; @from = connectTo ;
          when("1") ; @to = connectTo ;
          else
            raise "unknown connection handle:#{handle} in #{self}" ;
          end
        }
#        p [:generalization, @from, @to] ;
      end

      #--------------------------------
      #++
      ##
      def linkReferences(umlDoc)
        super(umlDoc) ;
        fromObj = umlDoc.getObject(@from) ;
        toObj = umlDoc.getObject(@to) ;
        if(fromObj.is_a?(Klass))
          @from = fromObj ;
        else
          raise "generalization (#{@from}->#{@to}) refers non-Class object:#{fromObj} in from-link" ;
        end
        if(toObj.is_a?(Klass))
          @to = toObj ;
        else
          raise "generalization (#{@from}->#{@to}) refers non-Class object:#{fromObj} in from-link" ;
        end
#        p [:link, gen.id, fromObj.name, toObj.name] ;
        toObj.inheritClass(fromObj) ;
      end

    end # class Generalization

  end # class Uml
end # class Dia

class Dia
  class Uml
    #--========================================
    #++
    ##
    class Package < ObjectBase
      #--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
      #++
      ##

      #--------------------------------
      #++
      ##

    end # class Package

  end # class Uml
end # class Dia

class Dia
  class Uml
    #--========================================
    #++
    ##
    class Association < ObjectBase
      #--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
      #++
      ##

      #--------------------------------
      #++
      ##

    end # class Association
  end # class Uml
end # class Dia

#--============================================================
#++
## 配列とハッシュテーブルを同時に管理するもの
class HashedArray < Array
  #--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  #++
  ## Table
  attr :keyList, true ;
  attr :selfTable, true ;
  attr :tables, true ;

  #----------------------------------------------------
  #++
  ## 初期化
  def initialize(keyList = [:id])
    super() ;
    @keyList = keyList ;
    setupTable() ;
  end

  #----------------------------------------------------
  #++
  ## ハッシュテーブルを準備
  def setupTable()
    @selfTable = {} ;
    @tables = {} ;
    @keyList.each{|key|
      @tables[key] = {} ;
    }
  end

  #----------------------------------------------------
  #++
  ## push 置き換え
  def push(entry)
    r = super(entry) ;
    @selfTable[entry] = entry ;
    @keyList.each{|key|
      @tables[key][entry.send(key)] = entry ;
    }
    r
  end

  #----------------------------------------------------
  #++
  ## push 置き換え
  def include?(entry)
    @selfTable.has_key?(entry) ;
  end

  #----------------------------------------------------
  #++
  ## get
  def get(keyType, key)
    @tables[keyType][key]
  end

end # class HashedArray < Array

########################################################################
########################################################################
########################################################################
if($0 == __FILE__) then
  require 'test/unit'
  require 'pp' ;

  #--============================================================
  #++

  class MyTest < Test::Unit::TestCase
    #--::::::::::::::::::::::::::::::::::::::::::::::::::
    #++
    ## サンプルファイル
    SampleDia = "#{ENV['HOME']}/tmp/PassengerApp_Common.dia" ;

    #----------------------------------------------------
    #++
    def setup
      puts ('*' * 5 ) + ' ' + [:run, name].inspect + ' ' + ('*' * 5) ;
      super
    end

    #----------------------------------------------------
    #++
    ##
    def test_a()
      dia = Dia::Uml.new(SampleDia) ;
      dia.eachClass(){|klass|
#        p [:klass, klass.id, klass.name,
#           klass.parentClasses.map{|c| c.name}] ;
        puts klass.toRubyDef() ;
      }
    end

    #----------------------------------------------------
    #++
    ##
    def test_b()
      dia = Dia::Uml.new(SampleDia) ;
      dia.eachClass(){|klass|
        puts klass.toRubyDef(true) ;
      }
    end

  end  # class MyTest
end # if($0 == __FILE__)
