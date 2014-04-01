#! /usr/bin/env ruby
## -*- mode: ruby -*-

require 'rexml/document'
module XML
  include REXML
end

#--============================================================
#++
# Dia file parser
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
  # initialize
  # _srcFile_:: a Dia file path.
  #           If specified, the file is read at the initializatoin.
  def initialize(srcFile = nil)
    @srcFiles = [] ;
    readFile(srcFile) if(srcFile) ;
    @layerTable = HashedArray.new([:id]) ;
    @objectTable = HashedArray.new([:id]) ;
  end

  #----------------------------------------------------
  #++
  # open and read a Dia file into XML document.
  # the document is set to +@doc+.
  # _filename_:: a Dia file
  # *return*:: a XML document.
  def readFile(filename)
    @srcFiles.push(filename) ;
    open(filename,"r"){|strm|
      @doc = XML::Document.new(strm) ;
    }
  end

  #----------------------------------------------------
  #++
  # pick up each layer XML element and execute a given block.
  # the block is passed each layer element.
  def scanEachLayer(&block) # :yields: layer
    XML::XPath.each(@doc.root,"//dia:layer"){|layer|
      block.call(layer) ;
    }
  end

  #----------------------------------------------------
  #++
  # pick up each object XML element and execute a given block.
  # the block is passed each object element.
  def scanEachObject(&block) # :yields: object
    scanEachLayer{|layer|
      XML::XPath.each(layer,"//dia:object"){|object|
        block.call(object) ;
      }
    }
  end

  #----------------------------------------------------
  #++
  # add an Object to the object table.
  # _object_:: an Object to add.
  def addObject(object)
    addToTable(@objectTable, object) ;
  end

  #----------------------------------------------------
  #++
  # pick up each object in the object table and execute a given block
  def eachObject(&block) # :yields: object
    @objectTable.each{|object|
      block.call(object) ;
    }
  end

  #----------------------------------------------------
  #++
  # pink up an object by an given _id_.
  # _id_:: an ID for the object.
  # *return*:: the object, or nil if not find.
  def getObject(id) ;
    @objectTable.get(:id, id) ;
  end

end #class Dia

class Dia
  #--==================================================
  #++
  ## A collection of Utility for Dia processing
  module Utility
    #--------------------------------
    #++
    # get a "dia:attribute" element with a specifiled "name" attribute.
    # _node_:: top node to start scan.
    # _name_:: the value of "name" attribute of searching element.
    # *return*:: the first XML element.

    def getAttributeFromNode(node,name)
      XML::XPath.first(node,"dia:attribute[@name='#{name}']") ;
    end

    #--------------------------------
    #++
    # get a "dia:string" value who has a specifield "name".
    # _node_:: top node to start scan.
    # _name_:: the value of "name" attribute of searching element.
    # *return*:: a String value.
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
    # wrapper for adding an object to a table.
    # _table_:: an object table
    # _object_:: an object to add to the table.
    def addToTable(table, object)
      table.push(object) ;
    end

  end # module Utility
end # class Dia

class Dia
  #--==================================================
  #++
  ## a class to handle generic UML object in Dia.
  class Uml < Dia
    #--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    #++
    ## table for UML classes
    attr :classTable, true ;
    ## table for UML generalization (inherit) relations
    attr :generalizationTable, true ;
    ## table for UML packages
    attr :packageTable, true ;
    ## table for UML association (has-a) relations
    attr :associationTable, true ;
    #------------------------------------------
    #++
    # create an Dia UML file object.
    # _srcFile_:: a Dia UML file.
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
    # open a Dia UML file and scan.
    # _srcFile_:: a file to scan.
    def addFile(srcFile)
      readFile(srcFile) ;
      scan() ;
    end

    #------------------------------------------
    #++
    # scan an XML document of an Dia UML.
    # This analyze Class, Generalization, Large Package and Association.
    # After the first scan, then scan the second round to link internal references.
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
    # establish internal references.
    def linkReferences()
      eachObject(){|object|
        object.linkReferences(self) ;
      }
    end

    #------------------------------------------
    #++
    # scan a UML class and create and register an object for it to the table.
    def addClass(object)
      klass = Klass.new(object) ;
      addObject(klass) ;
      addToTable(@classTable, klass) ;
    end

    #------------------------------------------
    #++
    # scan a UML generalization and create
    # and register an object for it to the table.
    def addGeneralization(object)
      gen = Generalization.new(object) ;
      addObject(gen) ;
      addToTable(@generalizationTable, gen) ;
    end

    #------------------------------------------
    #++
    # scan a UML large package and create
    # and register an object for it to the table.
    def addLargePackage(object)
      package = Package.new(object) ;
      addObject(package) ;
      addToTable(@packageTable,package) ;
    end

    #------------------------------------------
    #++
    # scan a UML association and create
    # and register an object for it to the table.
    def addAssociation(object)
      assoc = Association.new(object) ;
      addObject(assoc) ;
      addToTable(@associationTable,assoc) ;
    end

    #------------------------------------------
    #++
    # execute a given block for each UML class object.
    def eachClass(&block) # :yields: klass
      @classTable.each{|klass|
        block.call(klass) ;
      }
    end

    #------------------------------------------
    #++
    # execute a give block for each UML generalization object.
    def eachGeneralization(&block) # :yields: generalization
      @generalizationTable.each{|gen|
        block.call(gen) ;
      }
    end

    #------------------------------------------
    #++
    # execute a given block for each UML package object.
    def eachPackage(&block) # :yields: package
      @packageTable.each{|package|
        block.call(package) ;
      }
    end

    #------------------------------------------
    #++
    # execute a given block for each UML association object.
    def eachAssociation(&block) # :yields: association
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
      ## link to a source document.
      attr :document, true ;
      ## XML element for this object.
      attr :xml, true ;
      ## ID for this object.
      attr :id, true ;
      ## parent object.
      attr :parent, true ;
      ## name of the object.
      attr :name, true ;

      #--------------------------------
      #++
      # create a Dia UML object.
      # _object_:: an XML element for this object.
      # _doc_:: source document.
      def initialize(object,doc = nil)
        @document = doc ;
        @xml = object ;
        @id = object.attribute('id').value ;
        scan() ;
      end

      #--------------------------------
      #++
      # scan XML element.
      def scan()
        scanParent() ;
        scanName() ;
        scanSub() ;
      end

      #--------------------------------
      #++
      # sub rountine of scan.
      # This is called at the last of +scan+ method.
      # This is used to specify additional operation for each object class.
      def scanSub()
      end

      #--------------------------------
      #++
      # pick up the name of parent object element in XML.
      def scanParent()
        if(parentInfo = XML::XPath.first(@xml,"dia:childnode"))
          @parent = parentInfo.attribute("parent").value ;
        end
      end

      #--------------------------------
      #++
      # pick up the name of the object
      def scanName()
        @name = getAttributeString("name") ;
      end

      #--------------------------------
      #++
      # pick up the attribute element inXML
      # _name_:: the name of the attribute to find.
      # *return*:: attribute element
      def getAttribute(name)
        getAttributeFromNode(@xml,name) ;
      end

      #--------------------------------
      #++
      # pick up the value of the attribute.
      # _name_:: the name of the attribute to find.
      # *return*:: A String value.
      def getAttributeString(name)
        getAttributeStringFromNode(@xml, name) ;
      end

      #--------------------------------
      #++
      # link internal reference by name.
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
    ## UML Class object
    class Klass < ObjectBase
      #--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
      #++
      ## comment text.
      attr :comment, true ;
      ## table of attributes
      attr :umlAttributeTable, true ;
      ## inheritting classes.
      attr :parentClasses, true ;

      #--------------------------------
      #++
      # prepare objects.
      def scanSub()
        @umlAttributeTable = HashedArray.new([:name]) ;
        @comment = getAttributeString("comment") ;
        scanUmlAttributes() ;
        @parentClasses = [] ;
      end

      #--------------------------------
      #++
      # scan attributes defined in UML class diagram
      def scanUmlAttributes()
        scanEachComposite{|comp|
          attr = Attribute.new(comp,self) ;
          @umlAttributeTable.push(attr) ;
        }
#        p [:class, @name, @umlAttributeTable] ;
      end

      #--------------------------------
      #++
      # pick up each composite in the XML definition and execute a given block.
      def scanEachComposite(&block) # :yields: composition
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
      # add an inheritting class.
      # _parentClass_:: parent class.
      def inheritClass(parentClass)
        @parentClasses.push(parentClass) ;
      end

      #--------------------------------
      #++
      # generate a text of Ruby class definition.
      # _expandp_:: if true, expand definitions of inheritting classes
      # _indent_:: specify indent string for each line.
      # *return*:: definition text string.
      def toRubyDef(expandp = false, indent = "")
        tab = "  " ;
        ind0 = "\n" + indent ;
        ind1 = ind0 + tab ;
        defstr = "" ;
        ## comment (in RDoc style)
        defstr << ind0 << '#--' << '=' * 50 ;
        defstr << ind0 << '#++' ;
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
      # generate attribute declaration in class definition.
      # _expandp_:: if true, expand inheritting classes.
      # _indent_:: indent string for each line.
      # _inheritStack_:: stack recored of inherit-hierarchy.
      # *return*:: definition text string.
      def toRubyDefAttribute(expandp, indent, inheritStack = [])
        defstr = "" ;
        attrList = collectAttributesWithOverride(expandp) ;

        preKlassName = nil ;
        attrList.each{|attrGroup|
          klassName = attrGroup.first.klass.name ;
          if(expandp && (klassName != preKlassName)) then
            defstr << indent << "\#\#=== inheritted from #{klassName}" ;
          end
          defstr << attrGroup.last.toRubyDef(indent) ;
          preKlassName = klassName ;
        }
        defstr ;
      end

      #--------------------------------
      #++
      # collect attrubutes with override information.
      # _expandp_:: if true, expand inheritting classes.
      # _attrList_:: list of grouped attribute by name.
      # *return*:: [<attrGroup>, <attrGroup>, ...]
      # <attrGroup> :: [<attr>, <attr>, ...] ; attrs. with the same name.
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
      # check override of attribute definition.
      # _attribute_:: an Attribute object.
      # _inheritStack_:: stack trace of ihnerit hierarchy.
      # *return*:: return overrided Attribute, or nil.
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
      # attribute definition in UML classes
      class Attribute
        include Utility
        #--@@@@@@@@@@@@@@@@@@@@
        #++
        ## name of the attribute.
        attr :name, true ;
        ## data type of the attribute
        attr :type, true ;
        ## default or fixed value o the attribute
        attr :value, true ;
        ## comments for the attribute
        attr :comment, true ;

        ## class that the attribute belong to.
        attr :klass, true ;
        ## overrided attribute if the attribute override inherited definition.
        attr :overrideFrom, true ;

        #----------------------
        #++
        # create an Attribute.
        # _compNode_:: composition element in Dia XML.
        # _klass_:: class object that includes the attribute.
        def initialize(compNode,klass)
          @name = getAttributeStringFromNode(compNode,"name") ;
          @type = getAttributeStringFromNode(compNode,"type") ;
          @value = getAttributeStringFromNode(compNode,"value") ;
          @comment = getAttributeStringFromNode(compNode,"comment") ;
          @klass = klass ;
        end

        #--------------------------------
        #++
        # generate declaration text of the attribute in Ruby class definition.
        # _indent_:: indent string for each line.
        # *return*:: declaration text string.
        def toRubyDef(indent = "")
          defstr = "" ;
          defstr << indent << "\#\#*type* :: #{@type}." ;
          defstr << indent << "\#\#*value* :: #{@value}" if(@value.length>0) ;
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
    # generalization (inherit) relation between classes.
    class Generalization < ObjectBase
      #--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
      #++
      ## inheriting class
      attr :from, true ;
      ## inherited class
      attr :to, true ;

      #--------------------------------
      #++
      # scan each connection to find +from+ and +to+.
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
      # link actual class object from its name recorded in +from+ and +to+.
      # _umlDoc_:: a UML document that the generalization belongs to.
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
    # package definition in Dia's UML.
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
    # association definition in Dia's UML.
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
  ## a list of keys that are used as indexes of keys.
  attr :keyList, true ;
  ## a table of object indexed by the object itself.
  attr :selfTable, true ;
  ## a list of tables. The key type of each table is specified by +keyList+
  attr :tables, true ;

  #----------------------------------------------------
  #++
  # 初期化
  # _keyList_:: an init. value for @keyList.
  def initialize(keyList = [:id])
    super() ;
    @keyList = keyList ;
    setupTable() ;
  end

  #----------------------------------------------------
  #++
  # ハッシュテーブルを準備
  def setupTable()
    @selfTable = {} ;
    @tables = {} ;
    @keyList.each{|key|
      @tables[key] = {} ;
    }
  end

  #----------------------------------------------------
  #++
  # push 置き換え
  # _entry_:: add entry for each table.
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
  # 存在チェック
  # _entry_:: the object to be checked.
  # *return*:: true if the _entry_ exists in the table. Otherwise, false.
  def include?(entry)
    @selfTable.has_key?(entry) ;
  end

  #----------------------------------------------------
  #++
  # get an object specified by key as keyType
  # _keyType_:: specify which key type is used.
  # _key_:: the key value.
  # *return*:: a specified object.
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
