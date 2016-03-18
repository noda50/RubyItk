#! /usr/bin/ruby
## -*- Mode: ruby -*-

require "XmlFilter" ;
require 'OpenGIS' ;
require 'ItkSql' ;

include OpenGIS ;

##======================================================================
##======================================================================
##======================================================================
=begin

{Schema} >>> #[Schema]
	::= <schema> ({Element} | {DataType} | {GroupDef})* </schema>
            --> #[Schema {Element}[] {DataType}[] {GroupDef}[]]

{Element} >>> #[Element]
	::= <element name="{name}" type="{typename}" {OccurOpt} />
          | <element name="{name}" {OccurOpt}> {DataType} </element>
          | <element ref="{name}" />
            --> #[Element {name} {DataType} {OccurOpt}]

{DataType} >>> #[DataType]
	::= <simpleType [name="{name}"]> {Extent} </simpleType>
            --> #[DataType {name} builtIn?=yes]
          | <complexType [name="{name}"]> {Content} </complexType>
            --> #[DataType {name} {Content}]

{GroupDef} >>> #[Group]
	::= <group name="{name}"> {Container} </group>
            --> #[Group {name} {Container}]

{GroupRef} >>> #[Group]
	::= <group ref="{name}" {OccurOpt} />
            --> #[Group {name} {Container} {OccurOpt}]

{Extent} >>> #[Container]
	::= <extention base="{name}"> ({Container} | {Any})* </extention>
            --> #[Container[base=(DataType {name})]]
          | <restriction base="{name}"> {Any}* </restriction>
            --> #[Container[null,base=(DataType {name})]]

{Content} >>> #[Container]
	::= <simpleContent> {Extent} </simpleContent>
            --> {Extent}
          | <complexContent> {Extent} </complexContent>
            --> {Extent}
          | {Container}
            --> {Container}

{Container} >>> #[Container]
	::= <sequence {OccurOpt}> {Particle}* </sequence>
            --> #[Container type=sequence {Particle}[] {OccurOpt}]
          | <choice {OccurOpt}> {Particle}* </choice>
            --> #[Container type=choice {Particle}[] {OccurOpt}]

{Particle} >>> #[Element|Container|Group]
	::= {Element} 
            --> {Element}
          | {Container} 
            --> {Container}
          | {GroupRef}
            --> {GroupRef}

{OccurOpt} >>> #[AttributeList]
	::= (minOccurs="{number}")? (maxOccurs="{number}")?
            --> (minOccur={number} maxOccur={maxOccur})

=end
##======================================================================
##======================================================================
##======================================================================

def warning(msg,line = __LINE__, file = __FILE__)
  $stderr << "Warning in " << file << ":" << line << ": " << msg << "\n" ;
end

module OpenGIS
##//////////////////////////////////////////////////////////////////////

  $prefix = nil ;

  JointStrXPath = '/' ;
  JointStrSqlName = '_' ;
  NsSepStrXPath = ':' ;
  NsSepStrSqlName = '$' ;

  def xpath2sqlname(xpath)
    return xpath.gsub(JointStrXPath, 
		      JointStrSqlName).gsub(NsSepStrXPath,NsSepStrSqlName) ;
  end

  ##======================================================================
  ##======================================================================
  class XsdSqlTable < ItkSqlTableDef
    
    ##==============================
    ## class ColumnEntry

    class ColumnEntry
      attr :table,		true ;
      attr :column,		true ;
      attr :fullXPath,		true ;
      attr :relXPath,		true ;

      def initialize(table,column,fullXPath,relXPath)
	@table = table ;
	@column = column ;
	@fullXPath = fullXPath ;
	@relXPath = relXPath ;
      end
    end

    ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ## instance variables

    attr :colEntryList, 	true ;
    attr :colEntryTableFull,  	true ;
    attr :colEntryTableRel,	true ;

    ##----------------------------------------
    ## initialize

    def initialize(name, colDefs = [])
      @colEntryList = Array::new ;
      @colEntryFullXPathTable = Hash::new ;
      @colEntryRelXPathTable = Hash::new ;

      super(name,colDefs) ;
    end

    ##----------------------------------------
    ## add ColumnEntry

    def addColumnEntry(column,fullXPath,relXPath)
      colEntry = ColumnEntry::new(self,column,fullXPath,relXPath) ;
      @colEntryList.push(colEntry) ;
      @colEntryFullXPathTable[fullXPath] = colEntry ;
      @colEntryRelXPathTable[relXPath] = colEntry ;
      return colEntry ;
    end

    ##----------------------------------------
    ## describe

    def describe(strm = $stdout)
      super(strm) ;

      strm << "\t" << "XPathTable : " ;
      @colEntryList.each{|entry|
	strm << "\n\t\t" << entry.column.name << " : " ;
	strm << entry.relXPath << " | " << entry.fullXPath ;
      }
      strm << "\n" ;
    end

  end

  ##======================================================================
  ##======================================================================
  class XsdExpandedStructure

    ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ## instance variables

    attr :original,	true ; # should be XsdElement
    attr :name,		true ;
    attr :columnEntry,	true ; # nil or ColumnEntry
    attr :children,	true ; # nil or an Array of XsdExpandedStructure

    ##----------------------------------------
    ## initialize

    def initialize(original)
      @original = original ;
      @name = original.name() ;
      @children = Array::new ;
    end

    ##----------------------------------------
    ## check multipleness

    def multi?()
      return (@original.maxOccurs.to_i != 1) ;
    end

    def option?()
      return (@original.minOccurs.to_i != 1) ;
    end

    ##----------------------------------------
    ## scanData

    def xml2sqlRow(xmlNode,slotValueList = [])
      xml2sqlRowBody(xmlNode,".",slotValueList) ;
      return slotValueList ;
    end

    def xml2sqlRowBody(xmlNode,xpath,slotValueList)
      return if multi?() ;

      if(@columnEntry.nil?) then
	@children.each{ |child|
	  subxpath = xpath + JointStrXPath + child.name ;
	  XML::XPath::each(xmlNode,child.name){ |subNode|
	    child.xml2sqlRowBody(subNode, subxpath, slotValueList) ;
	  }
	}
      else
	type = @original.baseDataType() ;
	slot = @columnEntry.column() ;

	case type.genericType
	when 'int'
	  val = xmlNode.text().to_i ;
	when 'flt' 
	  val = xmlNode.text().to_f ;
	when 'str'
	  val = "'" + xmlNode.text() + "'" ;
	when 'geo'
	  node = XML::XPath::first(xmlNode,"*") ;
	  geo = Geometry::scanGml(node) ;
	  val = geo.to_SQL() ;
	else 
	  $stderr << "!!! Error" << "\n" ;
	end
	slotValueList.push([slot,val]) ;
      end
    end

    ##----------------------------------------
    ## describe

    def describe(strm = $stdout)
      strm << '#' << self.class.name << '[name="' << @name << '"]' << "\n" ;
      strm << "  " << "Skelton : " << "\n" ;
      describeBody(strm, "    ") ;
    end

    def describeBody(strm, indentstr) 
      strm << indentstr << '<' << @name ;

      if    (multi?() && option?()) then
	strm << ' occ="*"' ;
      elsif (multi?() && !option?()) then
	strm << ' occ="+"' ;
      elsif (!multi?() && option?()) then
	strm << ' occ="?"' ;
      end

      if(!@columnEntry.nil?) then
	strm << ' table="' << @columnEntry.table.name << '"' ;
	strm << ' col="' << @columnEntry.column.name << '"' ;

	strm << ' type="' << @columnEntry.column.type ;
	if(!@columnEntry.column.length.nil? ) then
	  strm << '(' << @columnEntry.column.length << ')' ;
	end
	strm << '"' ;

	strm << ' />' << "\n";
      else
	strm << '>' << "\n" ;
	@children.each{ |child|
	  child.describeBody(strm, indentstr + "  ") ;
	}
	strm << indentstr << '</' << @name << '>' << "\n" ;
      end
    end
  end

  ##======================================================================
  ##======================================================================
  class XsdDefs

    ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ## instance variables

    attr :defs,	 	true ;
    attr :name,	  	true ;
    attr :definedAt,	true ;

    ##----------------------------------------
    ## initialize

    def initialize()
      setDefs(nil) ;
    end

    ##----------------------------------------
    ## setDefs

    def setDefs(defs) 
      @defs = defs ;
      if(!@defs.nil?) then
	@name = defs.attributes['name'] ;
      end
      @defineAt = nil ;
    end

    ##----------------------------------------
    ## check GlobalDef

    def isGlobal?
      return (@defineAt.nil? || @defineAt == "") ;
    end

  end
  
  ##======================================================================
  class XsdElement < XsdDefs
    
    ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ## instance variables
    attr :xPath,	true ;
    attr :dataType, 	true ;
    attr :minOccurs, 	true ;
    attr :maxOccurs,	true ;
    attr :isGroupRef, 	true ;

    attr :sqlTable, 	true ;
    attr :sqlSubElements, true ;

    attr :expandedStructure, true ;

    ##----------------------------------------
    ## initialize
    def initialize(defs = nil)
      @xPath = nil ;
      @dataType = nil ;
      @minOccurs = "1" ;
      @maxOccurs = "1" ;

      @sqlTable = nil ;
      @sqlSubElements = [] ;

      @expandedStructure = nil ;

      setDefs(defs) ;
    end

    ##----------------------------------------
    ## find base datatype

    def baseDataType()
      type = @dataType ;
      while(!type.parent.nil?)
	type = type.parent ;
      end
      return type ;
    end

    ##----------------------------------------
    ## scan

    def scan(topschema)

      typename = @defs.attributes['type'] ;
      if(typename.nil?()) then
	r = XML::XPath::first(@defs,"#{$prefix}:simpleType/#{$prefix}:restriction") ;
	if(!r.nil?()) then
	  typename = r.attributes['base'] ;
	end
      end
      raise("no type definition in " + @defs.to_s) if(typename.nil?()) ;

      @dataType = topschema.findDataType(typename) ;

      minOcc = @defs.attributes['minOccurs'] ;
      maxOcc = @defs.attributes['maxOccurs'] ;

      @minOccurs = minOcc if(!minOcc.nil?) ;
      @maxOccurs = maxOcc if(!maxOcc.nil?) ;
    end

    ##----------------------------------------
    ## convert to sql table definition

    def convertToSqlTable(parentStruct = nil, tableXPath = "")
      tablePrefix = xpath2sqlname(tableXPath) ;
      @sqlTable = XsdSqlTable::new(tablePrefix + @name) ;
      @sqlTable.addColumns([ ['_id_', 'int', 
			       [ItkSqlColumnDef::F_AutoIncrement]],
			     ['_pid_','int', [] ] ]) ;

      convertToSqlColumn(parentStruct, @sqlTable, tableXPath, nil) ;
      return @sqlTable ;
    end

    ##----------------------------------------
    ## convert to sql column definition

    def convertToSqlColumn(parentStruct, 
			   table, tableXPath = "", columnXPath = "")
                                                  # when columnXPath=nil, 
                                                  # the column is top of the 
                                                  # table.

      isTopInTable = columnXPath.nil?() ;
      
      if(@maxOccurs.to_i == 1 || isTopInTable) then

	exStruct = XsdExpandedStructure::new(self) ;

	if(parentStruct.nil?) then       # if parentStruct is nil, 
	                                 # this is toplevel element.
	  @expandedStructure = exStruct ;
	else
	  parentStruct.children.push(exStruct) ;
	end

	# to avoid shared data type, do duplicate data type
	@dataType = @dataType.dup() ;

	@dataType.convertToSqlColumn(@name, exStruct,
				     table, tableXPath, columnXPath) ;
      else
	convertToSqlTable(parentStruct, tableXPath) ;
      end
	  
    end

    ##----------------------------------------
    ## collect SQL tables

    def collectSqlTables(result = [])
      if(!@sqlTable.nil? && @sqlTable.is_a?(XsdSqlTable)) then
	result.push(@sqlTable) ;
      end
      @dataType.collectSqlTables(result) ;
      return result ;
    end
  end

  ##======================================================================
  ##======================================================================
  class XsdDataType < XsdDefs
    
    def xsdTypeName() ; return "Complex" ; end

    ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ## instance variables
    attr :content, 	true ;
    attr :parent,  	true ;
    attr :isBuiltin, 	true ;
    attr :genericType,  true ;	# used for conversion
    attr :sqlType,  	true ;
    attr :sqlTypeOpt, 	true ;

    ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ## constants

    ##----------------------------------------
    ## initialize
    def initialize(defs = nil)
      @content = nil ;
      @parent = nil ;
      @isBuiltin = false ;
      @genericType = nil ;
      @sqlType = nil ;
      @sqlTypeOpt = nil ;
      setDefs(defs) ;
    end

    ##----------------------------------------
    ## scan

    def scan(topschema)
      scanBody(topschema,@defs) ;
    end

    ##----------------------------------------
    ## scan body

    def scanBody(topschema,node)
      node.each{|child|
	if(child.is_a?(XML::Element)) then
	  case(child.name)
	  when 'complexContent'
	    scanBody(topschema,child) ;
	  when 'simpleContent'
	    scanBody(topschema,child) ;
	  when 'extension'
	    @parent = topschema.findDataType(child.attributes['base']) ;
	    scanBody(topschema,child) ;
	  when 'restriction'
	    @parent = topschema.findDataType(child.attributes['base']) ;
	    ## do nothing ???
	  when 'sequence'
	    @content = XsdSequence::new(child) ;
	    @content.scan(topschema) ;
	  when 'choice'
	    @content = XsdChoice::new(child) ;
	    @content.scan(topschema) ;
	  when 'all'
	    @content = XsdAll::new(child) ;
	    @content.scan(topschema) ;
	  when 'attribute'
	    ## do nothing ???
	  else
	    raise("unsupported syntax for complexType : " + child.to_s) ;
	  end
	end
      }
    end

    ##----------------------------------------
    ## convert to SQL column

    def convertToSqlColumn(colName, exStruct,
			   table, tableXPath = "", columnXPath = "")
      isTopInTable = columnXPath.nil?() ;

      if(!@parent.nil?) then
	@parent = @parent.dup() ;
	@parent.convertToSqlColumn(colName,exStruct,
				   table,tableXPath,columnXPath) ;
      end

      if(isTopInTable) then
	relXPath = "."
	fullXPath = tableXPath ;
	actualColName = "_value_" ;
	newColXPath = "" ;
      else
	relXPath = columnXPath + colName ;
#	fullXPath = tableXPath + relXPath ; ## ?? for WFS
	fullXPath = tableXPath + colName ;
	actualColName = xpath2sqlname(columnXPath + colName) ;
	newColXPath = columnXPath + colName + JointStrXPath ;
      end
      newTableXPath = tableXPath + colName + JointStrXPath ;

      if(@isBuiltin) then

	if(!@sqlType.nil?) 
	  col = table.addColumn([ actualColName, @sqlType, @sqlTypeOpt ] )  ;
	  entry = table.addColumnEntry(col, fullXPath, relXPath) ;
	  exStruct.columnEntry = entry ;
	end

      elsif(@content.is_a?(XsdSequence) ||
	    @content.is_a?(XsdChoice) ||
	    @content.is_a?(XsdAll)) then

	@content = @content.dup() ;
	origParticleList = @content.particleList ;
	@content.particleList = [] ;

	origParticleList.each{|elm|
	  elm = elm.dup() ;
	  @content.particleList.push(elm) ;

	  if(elm.is_a?(XsdElement)) then
	     elm.convertToSqlColumn(exStruct,
				    table,newTableXPath,newColXPath) ;
	   else # maybe group case
	     elm.convertToSqlColumn(colName,exStruct,
				    table,tableXPath,columnXPath) ;
	   end
	}

      elsif(!@parent.nil?) then
      else
	warning("unsupported data type for SQL table defs:" + 
		@defs.to_s,
		__LINE__);
      end
    end

    ##----------------------------------------
    ## collect SQL tables

    def collectSqlTables(result = [])
      if(!@isBuiltin && !@content.nil?) then
	@content.collectSqlTables(result) ;
      end
      return result ;
    end

    ##----------------------------------------
    ## describe

    def describe(strm = $stdout)
      metatype = xsdTypeName() ;

      strm << "#[" << metatype << ":" << @name ;
      if(!@parent.nil?) then
	strm << " < " << @parent.name() ;
      end
      strm << "]" << "\n" ;

      strm << "  Elements:" << "\n" ;
      describeElements(strm) ;
      strm << "-" * 10 << "\n" ;
    end

    ##----------------------------------------
    ## describe element called in Containers

    def describeElements(strm = $stdout)
      @parent.describeElements(strm) if(!@parent.nil?) ;
	
      if(@content.nil?) then
	strm << "\t" << "(no more elements)" << "\n"
      else
	@content.describe(strm) ;
      end
    end

  end

  ##------------------------------------------------------------
  ## class methods for XsdDataType

  class << XsdDataType
    def defineBuiltInType(gentype, name, sqlName,optarg = [])
      ty = XsdDataType::new() ;

      ty.genericType = gentype ;
      ty.name = name ;
      ty.defs = name ;
      ty.isBuiltin = true ;

      ty.sqlType = sqlName ;
      ty.sqlTypeOpt = optarg ;

      return ty ;
    end
  end

  ##======================================================================
  ##======================================================================
  class XsdGroup < XsdDataType

    def xsdTypeName(); return "Group" ;  end

    ##----------------------------------------
    ## scan

    def scan(topschema)
      refname = @defs.attributes['ref'] ;
      @parent = topschema.findGroup(refname) if(!refname.nil?) ;
	
      scanBody(topschema,@defs) ;
    end

  end
    
  ##======================================================================
  ##======================================================================
  ## class for sequence, choice, all, and any

  class XsdContainer < XsdDefs
    
    ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ## instance variables
    attr :particleList,	true ;

    ##----------------------------------------
    ## initialize

    def initialize(defs = nil)
      @particleList = Array::new ;
      setDefs(defs);
    end

    ##----------------------------------------
    ## scan

    def scan(topschema)
      @defs.each{|child|
	if(child.is_a?(XML::Element)) then
	  if(child.name == 'element') then
	    particle = XsdElement::new(child) ;
	  elsif(child.name == 'group') then
	    particle = XsdGroup::new(child) ;
	  elsif(child.name == 'sequence') then
	    particle = XsdSequence::new(child) ;
	  elsif(child.name == 'choice') then
	    particle = XsdChoice::new(child) ;
	  elsif(child.name == 'all') then
	    particle = XsdAll::new(child) ;
	  else
	    raise("unsupported syntax for #{xsdTypeName()} : " +
		  child.to_s) ;
	  end
	  particle.scan(topschema) ;
	  @particleList.push(particle) ;
	end
      }
    end

    ##----------------------------------------
    ## collect SQL tables

    def collectSqlTables(result = [])
      @particleList.each{|elm|
	elm.collectSqlTables(result) ;
      }
      return result ;
    end

    ##----------------------------------------
    ## describe

    def describe(strm = $stdout)
      strm << "    <" << xsdTypeName() << ">" << "\n" ;
      describeElements(strm) ;
    end

    def describeElements(strm= $stdout) 
      @particleList.each{|elm|
	if(elm.is_a?(XsdElement)) then
	  strm << "\t" << elm.name << " : " << elm.dataType.name << "\n" ;
	elsif (elm.is_a?(XsdContainer)) then
	  elm.describeElements(strm = $stdout) ;
	elsif (elm.is_a?(XsdDataType)) then
	  elm.describeElements(strm = $stdout) ;
	else
	  raise("unknown particle type : " + elm.to_s) ;
	end
      }
    end

  end
  
  ##======================================================================
  ##======================================================================
  ## class for sequence

  class XsdSequence < XsdContainer  
    def xsdTypeName() ; return "sequence" ; end ;
  end
    
  ##======================================================================
  ##======================================================================
  ## class for choice

  class XsdChoice < XsdContainer  
    def xsdTypeName() ; return "choice" ; end ;
  end
    
  ##======================================================================
  ##======================================================================
  ## class for all

  class XsdAll < XsdContainer  
    def xsdTypeName() ; return "all" ; end ;
  end
    
  ##======================================================================
  ##======================================================================
  class XsdSchema

    ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ## class constants

    BuiltInTypes = Hash::new() ;

    def builtInType(name)
      return BuiltInTypes[name] ;
    end

    ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ## instance variables
    attr :defs, true ;
    attr :elementTab, true ;
    attr :elementList, true ;
    attr :dataTypeTab, true ;
    attr :dataTypeList, true ;
    attr :groupTab, true ;
    attr :groupList, true ;

    attr :sqlTableList, true ;

    attr :xPathColumnTab, true ; ## map table from xpath to columnEntry

    ##----------------------------------------
    ## initialize

    def initialize(schema = nil)
      @elementTab = Hash::new() ;
      @elementList = Array::new() ;
      @dataTypeTab = Hash::new() ;
      @dataTypeList = Array::new() ;
      @groupTab = Hash::new() ;
      @groupList = Array::new() ;
      
      @sqlTableList = Array::new() ;
      
      @xPathColumnTab = Hash::new() ;

      setSchema(schema) ;
    end

    ##----------------------------------------
    ## set schema top

    def setSchema(schema = nil)
      if(schema.is_a?(IO))
	@defs = XML::Document.new(schema) ;
      elsif(schema.is_a?(String))
	@defs = XML::Document.new(schema) ;
      elsif(schema.is_a?(XML::Document))
	@defs = schema ;
      elsif(schema.nil?)
	@defs = nil ;
      else
	raise("unknown schema data : " + schema.to_s) ;
      end
    end

    ##----------------------------------------
    ## scan Schema

    def scanSchema()
      scanSchema1stPass() ;
      scanSchema2ndPass() ;
    end

    ##----------------------------------------
    ## scan Schema first pass

    def scanSchema1stPass()
#      XML::XPath::each(@defs,"/*:schema"){|schm|
      XML::XPath::each(@defs.root,"."){|schm|
	if(schm.name == "schema") then		# !!!
	  $prefix = schm.prefix ;
	  schm.each{|defs|
	    if(defs.is_a?(XML::Element)) then
	      case(defs.name)
	      when('element')
		scanElement1stPass(defs) ;
	      when('complexType')
		scanDataType1stPass(defs) ;
	      when('simpleType')
		scanDataType1stPass(defs) ;
	      when('group')
		scanGroup1stPass(defs) ;
	      end
	    end
	  }
	end
      }
    end

    ##----------------------------------------
    ## scan Schema second pass

    def scanSchema2ndPass()
      scanElement2ndPass() ;
      scanDataType2ndPass() ;
      scanGroup2ndPass() ;
    end

    ##----------------------------------------
    ## scan Element (1st)

    def scanElement1stPass(defs)
      element = XsdElement::new(defs) ;
      @elementTab[element.name()] = element ;
      @elementList.push(element) ;
    end

    ##----------------------------------------
    ## scan Element (2nd)

    def scanElement2ndPass()
      @elementTab.each{|name,defs|
	defs.scan(self) ;
      }
    end

    ##----------------------------------------
    ## scan DataType (1st)

    def scanDataType1stPass(defs)
      dataType = XsdDataType::new(defs) ;
      @dataTypeTab[dataType.name()] = dataType ;
      @dataTypeList.push(dataType) ;
    end

    ##----------------------------------------
    ## scan DataType (2nd)

    def scanDataType2ndPass()
      @dataTypeTab.each{|name,defs|
	defs.scan(self) ;
      }
    end

    ##----------------------------------------
    ## scan Group (1st)

    def scanGroup1stPass(defs)
      group = XsdDataType::new(defs) ;
      @groupTab[group.name()] = group ;
      @groupList.push(group) ;
    end

    ##----------------------------------------
    ## scan Group (2nd)

    def scanGroup2ndPass()
      @groupTab.each{|name,defs|
	defs.scan(self) ;
      }
    end

    ##----------------------------------------
    ## define SQL tables

    def defineSqlTables()
      @elementList.each{|elm|
	elm.convertToSqlTable() ;
      }
      
      @sqlTableList = Array::new ;
      @elementList.each{|elm|
	elm.collectSqlTables(@sqlTableList) ;
      }

      @sqlTableList.each{|tab|
	tab.colEntryList.each{|col|
	  @xPathColumnTab[col.fullXPath] = col ;
	}
      }

      return @sqlTableList ;
    end

    ##----------------------------------------
    ## find dataType from name

    def findDataType(typename)
      barename = typename.sub(/^.*:/,'') ;
      barename = typename if(barename.nil?) ;

      r = @dataTypeTab[barename] ;
      if(r.nil?) then
	r = builtInType(barename)
	raise("Unknown datatype:" + typename) if(r.nil?) ;
      end
      
      return r ;
    end
      
    ##----------------------------------------
    ## find group from name

    def findGroup(typename)
      barename = typename.sub(/^.*:/,'') ;
      barename = typename if(barename.nil?) ;

      r = @groupTab[barename] ;
      if(r.nil?) then
	r = builtInType(barename)
	raise("Unknown datatype:" + typename) if(r.nil?) ;
      end
      
      return r ;
    end
      
    ##----------------------------------------
    ## find element from name

    def findElement(elementname)
      barename = elementname.sub(/^.*:/,'') ;
      barename = elementname if(barename.nil?) ;

      r = @elementTab[barename] ;
      raise("Unknown element:" + elementname) if(r.nil?) ;
      
      return r ;
    end
      
    ##----------------------------------------
    ## describe

    def describe(strm = $stdout)
      strm << "<<<<<<<<<<<Elements>>>>>>>>>>>>" << "\n" ;
      @elementList.each{|elm|
	strm << "\t" << elm.name << " : " << elm.dataType.name << "\n"
      }

      strm << "-" * 20 << "\n" ;
      strm << "<<<<<<<<<<<DataTypes>>>>>>>>>>>" << "\n" ;
      @dataTypeList.each{|type|
	type.describe(strm) ;
      }

      strm << "-" * 50 << "\n" ;
    end

  end

  ##======================================================================
  ## class methods for XsdSchema

  class << XsdSchema

    ##----------------------------------------
    ## read schema from file
    def scanFile(filename)
      return XsdSchema::new(File::new(filename)) ;
    end

    ##----------------------------------------
    ## read schema from string
    def scanString(xmlString)
      return XsdSchema::new(xmlString) ;
    end
    
    ##----------------------------------------
    ## read schema from XML Schema
    def scanXML(xml)
      return XsdSchema::new(xml) ;
    end

    ##----------------------------------------
    ## define built-in type
    def defineBuiltInType(gentype, name,sqlName,optarg = [])
      ty = XsdDataType.defineBuiltInType(gentype, name,sqlName,optarg) ;
      XsdSchema::BuiltInTypes[name] = ty ;
    end

  end

  ##------------------------------------------------------------
  # define builtin types

  XsdSchema::defineBuiltInType('int', "integer",	"int") ;
  XsdSchema::defineBuiltInType('flt', "float",  	"double") ;
  XsdSchema::defineBuiltInType('str', "string",		"blob") ;
  XsdSchema::defineBuiltInType('int', "unsignedByte",	"int unsigned") ;
  XsdSchema::defineBuiltInType('int', "unsignedLong",	"int unsigned") ;
  XsdSchema::defineBuiltInType('int', "unsignedInt",	"int unsigned") ;

  XsdSchema::defineBuiltInType('str', "SqlTinyBlob",	"tinyblob") ;
  XsdSchema::defineBuiltInType('str', "SqlBlob",	"blob") ;
  XsdSchema::defineBuiltInType('str', "SqlMediumBlob",	"mediumblob") ;
  XsdSchema::defineBuiltInType('str', "SqlLongBlob",	"longblob") ;

  XsdSchema::defineBuiltInType('nil', "AbstractFeatureType", nil) ;
  XsdSchema::defineBuiltInType('nil', "AbstractFeatureCollectionType", nil) ;
  
  XsdSchema::defineBuiltInType('geo', "geometryPropertyType", "geometry",
			       [ ItkSqlColumnDef::F_NotNull,
				 ItkSqlColumnDef::F_Index]) ;

##//////////////////////////////////////////////////////////////////////
end

