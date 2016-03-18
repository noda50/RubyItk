#! /usr/bin/ruby
## -*- Mode: ruby -*-

require "tempfile" ;
require 'mysql' ;
require "XsdScanner" ;

##//////////////////////////////////////////////////////////////////////
module OpenGIS
  ##======================================================================
  ##======================================================================

  $testP = false ;

  ##======================================================================
  class WfsProcessor

    ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ## constants

    DefaultServer = 'localhost' ;
    DefaultDbName = 'gfs' ;

    SqlSchemaTableName	= '__schema__' ;
    SqlElementTableName	= '__element_schema__' ;
    SqlTypeTableName 	= '__type_schema__' ;

    ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ## instance variables

    attr :sql, 		true ;
    attr :server,	true ;
    attr :dbName,	true ;
    attr :xsd,		true ;
    attr :sqlTables,	true ;

    ##----------------------------------------
    ## initialize

    def initialize(server = DefaultServer, dbName = DefaultDbName) 
      @server = server ;
      @dbName = dbName ;
    end

    ##----------------------------------------
    ## utilities

    ##--------------------
    ## check test mode

    def test?()
      return $testP ;
    end

    ##--------------------
    ## query

    def query(qstr)
      return @sql.query(qstr) ;
    end

    ##--------------------
    ## query or test

    def queryOrTest(qstr)
      r = nil ;
      p(qstr) if (test?) ;
      r = query(qstr) if (!test?) ;
      return r ;
    end

    ##--------------------
    ## open DB

    def openDB(server = nil, dbName= nil)
      server = @server if (server.nil?) ;
      dbName = @dbName if (dbName.nil?) ;
      
      @server = server ;
      @dbName = dbName ;

      if(!test?()) 
	@sql = Mysql::new(server, nil, nil) ;
	@sql.select_db(dbName) ;
      end

      return @sql ;
    end

    ##--------------------
    ## open DB without test

    def openDBNoTest(server = nil, dbName= nil)
      backup = $testP ;
      $testP = false ;

      r = openDB(server, dbName) ;

      $testP = backup ;

      return r ;
    end

    ##--------------------
    ## check database
    
    def checkDB(dbName)
      res = @sql.query("show databases;") ;
      res.each{|row|
	return true if(row[0] == dbName) ;
      }
      return false ;
    end

    ##--------------------
    ## scan schema

    def scanSchema(schemaFile)
      strm = File::new(schemaFile) ;

      @xsd = OpenGIS::XsdSchema::new(strm) ;
      @xsd.scanSchema() ;
      @sqlTables = @xsd.defineSqlTables() ;

      strm.close() ;
    end

    ##--------------------
    ## scan schema from string

    def scanSchemaFromString(schemaString)
      strm = Tempfile::new($0) ;
      strm << schemaString ;
      strm.close() ;
      scanSchema(strm.path) ;
      strm.open() ; strm.close(true) ;
    end

    ##--------------------
    ## scan schema in DB 
    def scanSchemaFromDB(elementName)

      # if elementName is already in @xsd, then skip the operation.
      return if(!@xsd.nil? && !@xsd.findElement(elementName).nil?) ;

#      uriList = queryOrTest("select uri from %s where element='%s';" %
#		      [SqlElementTableName, elementName]) ;
      uriList = query("select uri from %s where element='%s';" %
		      [SqlElementTableName, elementName]) ;
      uriList = [] if(uriList.nil?) ;

      uriList.each{|row|
	uri = row[0] ;
#	schemaList = queryOrTest("select schema from %s where uri = '%s';" %
#				 [SqlSchemaTableName, uri]) ;
	schemaList = query("select schema from %s where uri = '%s';" %
			   [SqlSchemaTableName, uri]) ;
	schemaList = [] if (schemaList.nil?) ;

	schemaList.each{|schema|
	  scanSchemaFromString(schema[0]) ;
	}
	schemaList.free() if !uriList.is_a?(Array) ;
	break ;
      }
      uriList.free() if !uriList.is_a?(Array) ;
    end

    ##--------------------
    ## generate query string for node.

    def strInsertEntry(xmlNode)
      name = xmlNode.name ;
      scanSchemaFromDB(name) ;
      element = @xsd.findElement(name) ;
      sqlRow = element.expandedStructure.xml2sqlRow(xmlNode) ;
      return element.sqlTable.strSimpleInsert(sqlRow) ;
    end

    ##----------------------------------------
    ## operations

    ##--------------------
    ## setup DB

    def setupDB(openP = true)
      openDB() if openP;
      
      queryOrTest("create table if not exists %s (uri blob, schema blob);" %
		  SqlSchemaTableName) ;
      queryOrTest("create table if not exists %s (element blob,uri blob);" %
		  SqlElementTableName) ;
      queryOrTest("create table if not exists %s (type blob, uri blob) ;" %
		  SqlTypeTableName) ;
    end

    ##--------------------
    ## clear DB

    def clearDB(openP = true)
      openDB() if openP;

      res = @sql.query("show tables;") ;
      res = [] if res.nil? ;

      res.each{ |row|
	queryOrTest("drop table %s;" % row[0]) ;
      }
    end

    ##--------------------
    ## register

    def register(schemaFiles, openP = true)
      openDB() if openP;
      
      schemaFiles.each {|file|
	uri = "file:#{file}" ;
	registerWithUri(file,uri) ;
      }
    end

    ##--------------------
    ## register

    def registerWithUri(file, uri)
      #----------
      # register schema
      str = File::open(file) ;
      defstr = str.read() ;
      str.close() ;
      qdefstr = Mysql::quote(defstr) ;
      queryOrTest("insert into %s (uri,schema) values ('%s', '%s');" %
		  [SqlSchemaTableName, uri, qdefstr]) ;
      #----------
      # register element to table
      scanSchema(file) ;
      @xsd.elementList.each{|elm|
	queryOrTest("insert into %s (element,uri) values ('%s','%s');" %
		    [SqlElementTableName, elm.name, uri]) ;
      }
      #----------
      # register to type table
      @xsd.dataTypeList.each { |type|
	queryOrTest("insert into %s (type,uri) values ('%s','%s');" %
		    [SqlTypeTableName, type.name, uri]) ;
      }
    end

    ##--------------------
    ## check syntax check of schema file

    def checkSchemaFile(schemaFiles) 
      schemaFiles.each{|file|
	scanSchema(file) ;
	@xsd.describe ;
	$stdout << '-' * 50 << "\n" ;
	@sqlTables.each{|tab|
	  tab.describe($stdout) ;
	  $stdout << '-' * 50 << "\n" ;
	}
      }
    end

    ##--------------------
    ## show skelton 

    def showSkelton(elementList) 
      openDB() ;
      elementList.each{|elm|
	scanSchemaFromDB(elm) ;
	@xsd.elementList.each{|e|
	  e.expandedStructure.describe($stdout) ;
	  $stdout << '-' * 50 << "\n" ;
	}
      }
    end

    ##--------------------
    ## show skelton of element in schema file
    
    def showSkeltonInSchemaFile(schemaFiles)
      schemaFiles.each{|file|
	scanSchema(file) ;
	@xsd.elementList.each{|e|
	  e.expandedStructure.describe($stdout) ;
	  $stdout << '-' * 50 << "\n" ;
	}
      }
    end

    ##--------------------
    ## create table

    def createTable(elementList)
      openDBNoTest() ;
      elementList.each{|elm|
	scanSchemaFromDB(elm) ;
	createAllTable() ;
      }
    end

    def createAllTable()
      @sqlTables.each{|tab|
	queryOrTest("create table if not exists %s (%s);" % 
		    [tab.name, tab.strDeclareCol]) ;
      }
    end

    ##--------------------
    ## drop table

    def dropTable(elementList)
      openDBNoTest() ;

      elementList.each{|elm|
	scanSchemaFromDB(elm) ;
	
	@sqlTables.each{|tab|
	  queryOrTest("drop table %s;" % [tab.name]) ;
	  $stdout << '-' * 50 << "\n" if (!test?) ;
	}
      }
    end

    ##--------------------
    ## insert one element

    def insert1(files) 
      openDBNoTest() ;

      files.each{|file|
	strm = File::new(file) ;
	xmlDoc = XML::Document.new(strm) ;
	qstr = strInsertEntry(xmlDoc.root) ;

	queryOrTest(qstr) ;
	strm.close() ;
      }
    end

    ##--------------------
    ## insert N elements

    def insertN(files) 
      openDBNoTest() ;

      files.each{|file|
	strm = File::new(file) ;
	insertNfromStream(strm) ;
	strm.close() ;
      }
    end

    ##--------------------
    ## insert N elements

    def insertNfromStream(strm) 
      filter = ItkXml::ScanFilter::new(strm) ;
      filter.setup(["gml:featureMember"], CollectionListener) ;
      filter.scanListener.setup(self) ;
      filter.run() ;
    end

    ##--------------------
    ## WFS query

    def wfsQuery(files,countP=false) 
      openDBNoTest() ;

      files.each{|file|
	strm = File::new(file) ;
	begin
	  wfsQueryFromStream(strm,$stdout,countP) ;
	rescue WfsServerCloseSocketException 
	end
	strm.close() ;
      }
    end

    ##--------------------
    ## WFS query

    def wfsServer(socket)
      openDBNoTest() ;

      begin
	wfsQueryFromStream(socket,socket,false);
      rescue WfsServerCloseSocketException 
      end
    end

    ##--------------------
    ## WFS query from stream

    def wfsQueryFromStream(istrm,ostrm,countP)
      filter = ItkXml::ScanFilter::new(istrm) ;
      filter.setup(nil, WfsScanner) ;
      filter.scanListener.setup(self,ostrm) ;
      filter.scanListener.countP = countP ;
      filter.run() ;
    end

  end

  ##======================================================================
  ## class WfsServerCloseSocketException

  class WfsServerCloseSocketException < Exception

  end

  ##======================================================================
  ## class CollitionListener

  class CollectionListener < ItkXml::BaseScanListener

    ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ## constants

    attr :depth,  true ;
    attr :processor,true ;
    attr :tag,	true ;

    ##------------------------------
    def initialize()
      super
      @scanP = false ;
      @depth = 0 ;
      @tag = nil ;
    end

    ##------------------------------
    def setup(processor)
      @processor = processor ;
    end

    ##------------------------------
    def cycle(node)
      qstr = @processor.strInsertEntry(node.elements[1]) ;

      @processor.queryOrTest(qstr) ;
    end
  end

  ##======================================================================
  ## class WFS Scanner

  class WfsScanner < ItkXml::BaseScanListener
    
    ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    ## constants

    attr :depth, true ;
    attr :majorMode, true ;
    attr :minorMode, true ;
    attr :processor,true ;
    attr :ostrm, true ;
    attr :countP, true ; 		# indicate 'get' or 'count'

    attr :uri,	true ;			# for Register

    ##------------------------------
    def initialize()
      @depth = 0 ;
      @ostrm = $stdout ;
      @countP = false ;
      @processor = nil ;
      @majorMode = nil ;
      @minorMode = nil ;
      super
    end

    ##------------------------------
    def setup(processor,strm = $stdout)
      @processor = processor ;
      @ostrm = strm ;
    end

    ##--------------------
    ## check watching element

    def isWatchedElement?(uri, local, qname, attributes)
      return @scanP ;
    end

    ##------------------------------
    def start_element(uri, local, qname, attributes)
      raise "Illegal Depth before reading #{qname}" if (@depth < 0) ;

      @majorMode = local if(@depth == 0) ;

      if(!@scanP) then
	case(@majorMode)
	when 'GetFeature' 
	  @scanP = true if @depth == 1 ;
	  #----------
	when 'Transaction' 
	  if    (@depth == 0) then
	    @transactionResultStatus = true ;
	    @transactionResultMessage = [] ;
	    @transactionInsertCount = 0 ;
	  elsif (@depth == 1) then
	    @minorMode = local ;
	    if(@minorMode == 'Update' || @minorMode == 'Delete') then
	      @scanP = true ;
	    end
	  elsif (@depth == 2 && @minorMode == 'Insert') then
	    @scanP = true ;
	  else
	    raise "Unsupported Protocol for Transaction : #{qname}" ;
	  end
	  #----------
	when 'Register'
	  @uri = attributes['uri'] if @depth == 0 ;
	  @scanP = true if @depth == 1 ;
	  #----------
	else
	  raise "Unsupported Protocol : #{qname}" ;
	end
      end

      @depth += 1 ;
      
      super(uri, local, qname, attributes) ;
    end

    ##------------------------------
    def end_element(uri, local, qname)
      super(uri, local, qname) ;
      @depth -= 1 ;
      if(@depth == 0 && @majorMode == 'Transaction') then
	outputTransactionResponse(@ostrm) ;
      end

      raise WfsServerCloseSocketException if(@depth == 0) ;
    end

    ##------------------------------
    def cycle(node) 
      case @majorMode 
      when 'GetFeature' ; doGetFeature_Query(node) ;
	#----------
      when 'Transaction'
	case @minorMode
	when 'Insert' ; doTransaction_Insert(node) ; # node is a data entry
	when 'Update' ; doTransaction_Update(node) ;
	when 'Delete' ; doTransaction_Delete(node) ; 
	else
	  raise "Unsupported Protocol for Transaction: #{@minorMode}" ;
	end
	#----------
      when 'Register' ; doRegister(node,@uri) ;
	#----------
      else
	raise "Unsupported Protocol : #{@majorMode}" ;
      end
    end

    ##------------------------------
    def doRegister(schemaNode, uri)
      strm = Tempfile::new($0) ;
      strm << schemaNode.to_s ;
      strm.close() ;
      @processor.registerWithUri(strm.path, uri) ;
      strm.open() ; strm.close(true) ;

      @processor.createAllTable() ;

      response = XML::Element::new('RegisterResponse') ;

      status = XML::Element::new('Status') ;

      response.add(status) ;
      status.add(XML::Text::new("OK")) ;

      @ostrm << response.to_s << "\n" ;
    end

    ##------------------------------
    def doGetFeature_Query(queryNode)
      typename = queryNode.attributes['typeName'] ;

      filterNode = XML::XPath::first(queryNode, "Filter") ;
      condstr = scanFilterNode(typename, filterNode) ;

      element = @processor.xsd.elementTab[typename] ;
      sqlTable = element.sqlTable ;
      cols = sqlTable.strShowCol() ;

      if(!@countP)
	qstr = ("select %s from %s where %s;"  % 
		[cols, sqlTable.name, condstr]) ;
      else 
	qstr = ("select count(*) from %s where %s;" %
		[sqlTable.name, condstr]) ;
      end

      result = @processor.queryOrTest(qstr) ;

      if(!@countP)
	outputResultXml(@ostrm,element,result) ;
      else
	if(!result.nil?) then
	  result.each{|row|
	    @ostrm << row.to_s << "\n" ;
	  }
	end
      end
    end

    ##------------------------------
    def doTransaction_Insert(entryNode)
      qstr = @processor.strInsertEntry(entryNode) ;

      @processor.queryOrTest(qstr) ;

      updateTransactionResponse(true, nil, true) ; ## insert count up
    end

    ##------------------------------
    def doTransaction_Update(updateNode)
      typename = updateNode.attributes['typeName'] ;

      propstrList = [] ;
      XML::XPath::each(updateNode, "Property") { |propertyNode|
	pstr = scanPropertyNode(typename, propertyNode) ;
	propstrList.push(pstr) ;
      }
      propstr = propstrList.join(', ') ;

      filterNode = XML::XPath::first(updateNode, "Filter") ;
      condstr = scanFilterNode(typename, filterNode) ;

      element = @processor.xsd.elementTab[typename] ;
      sqlTable = element.sqlTable ;

      qstr = ("update %s set %s where %s;" %
	      [sqlTable.name, propstr, condstr]) ;

      result = @processor.queryOrTest(qstr) ;

      updateTransactionResponse(true, @processor.sql.info()) ;
    end

    ##------------------------------
    def doTransaction_Delete(deleteNode)
      typename = deleteNode.attributes['typeName'] ;

      filterNode = XML::XPath::first(deleteNode, "Filter") ;
      condstr = scanFilterNode(typename, filterNode) ;

      element = @processor.xsd.elementTab[typename] ;
      sqlTable = element.sqlTable ;

      qstr = ("delete from %s where %s;" %
	      [sqlTable.name, condstr]) ;

      result = @processor.queryOrTest(qstr) ;

      nRows = @processor.sql.affected_rows() ;

      updateTransactionResponse(true, "Delete: #{nRows} rows affected.") ;
    end

    ##------------------------------
    def scanPropertyNode(typename, propertyNode) 
      @processor.scanSchemaFromDB(typename) ;

      propNameNode = XML::XPath::first(propertyNode, "Name") ;
      columnName = scanFilterNodeBody_PropertyName(typename, propNameNode) ;

      valueNode = XML::XPath::first(propertyNode, "Value") ;
      if(valueNode.has_elements?) then
	valuestr = scanFilterNodeBody_Expression(typename, node.elements[1]) ;
      else
	valuestr = valueNode.texts.to_s ;
      end
      
      return ("%s=%s" % [columnName,valuestr]) ;
    end

    ##------------------------------
    def scanFilterNode(typename, filterNode) 
      @processor.scanSchemaFromDB(typename) ;

      rstr = scanFilterNodeBody(typename, filterNode.elements[1]) ;

      return rstr ;
    end

    ##------------------------------
    def scanFilterNodeBody(typename, node) 
      if    (! SpacialOperator[node.name].nil?) 
	scanFilterNodeBody_GeoOp(typename, node) ;
      elsif (! ComparisonOperator[node.name].nil?)
	scanFilterNodeBody_CompOp(typename, node) ;
      elsif (! LogicalOperator[node.name].nil?)
	scanFilterNodeBody_LogicalOp(typename, node) ;
      else
	raise "unsupported filter operation #{node.to_s}." ;
      end
    end
	
    ##------------------------------
    def scanFilterNodeBody_GeoOp(typename, node) 
      opname = SpacialOperator[node.name] ;

      firstNode = node.elements[1] ;
      secondNode = node.elements[2] ;
      
      columnName = scanFilterNodeBody_PropertyName(typename, firstNode) ;

      geostr = scanFilterNodeBody_Geometry(typename, secondNode) ;

      qstr = ("%s(%s,%s)" %
	      [opname, columnName, geostr]) ;
      
      return qstr ;
    end

    SpacialOperator = { 
      'BBox' 		=> 'MBRIntersects',
      'Contains' 	=> 'MBRContains',
      'Disjoint'	=> 'MBRDisjoint',
      'Equals'		=> 'MBREqual',
      'Intersects'	=> 'MBRIntersects',
      'Overlaps'	=> 'MBROverlaps',
      'Touches'		=> 'MBRTouches',
      'Within'		=> 'MBRWithin',
      'Crosses'		=> nil,			# not supported
      'DWithin'		=> nil,			# not supported
      'Beyond'		=> nil,			# not supported
      nil		=> nil 
    } ;

    ##------------------------------
    def scanFilterNodeBody_CompOp(typename, node) 
      opname = ComparisonOperator[node.name] ;

      # from here, suppose binary infix operator

      firstNode = node.elements[1] ;
      secondNode = node.elements[2] ;

      firstArg = scanFilterNodeBody_Expression(typename, firstNode) ;
      secondArg = scanFilterNodeBody_Expression(typename, secondNode) ;
      
      qstr = ("(%s) %s (%s)" % [firstArg, opname, secondArg]) ;
      
      return qstr ;
    end

    ComparisonOperator = {
      'PropertyIsEqualTo'		=> '=',
      'PropertyIsNotEuqualTo'		=> '!=',
      'PropertyIsLessThan'		=> '<',
      'PropertyIsGreaterThan'		=> '>',
      'PropertyIsLessThanOrEqualTo'	=> '<=',
      'PropertyIsGreaterThanOrEqualTo'	=> '>=',
      'PropertyIsLike'			=> nil,		# not supported
      'PropertyIsNull'			=> nil,		# not supported
      'PropertyIsBetween'		=> nil,		# not supported
      nil				=> nil
    } ;

    ##------------------------------
    def scanFilterNodeBody_LogicalOp(typename, node) 
      op = LogicalOperator[node.name] ;
      arity = op[0] ;
      opname = op[1] ;

      if(arity > 0) then
	firstNode = node.elements[1] if(arity > 0) ;
	firstArg = scanFilterNodeBody(typename, firstNode) ;

	if(arity > 1) then
	  secondNode = node.elements[2] 
	  secondArg = scanFilterNodeBody(typename, secondNode) ;
	end

      end

      case(arity)
      when 1
	qstr = ("%s (%s)" % [opname, firstArg]) ;
      when 2
	qstr = ("(%s) %s (%s)" % [firstArg, opname, secondArg]) ;
      end

      return qstr ;
    end

    LogicalOperator = {
      'And'		=> [2, 'and'],
      'Or'		=> [2, 'or'],
      'Not'		=> [1, 'not'],
      nil		=> nil
    } ;

    ##------------------------------
    def scanFilterNodeBody_Expression(typename, node) 
      if(!ExpressionBinaryOperator[node.name].nil?) then
	return scanFilterNodeBody_ExpressionBinary(typename, node) ;
      elsif(!Geometry::findClassByNodeTag(node).nil?)
	return scanFilterNodeBody_Geometry(typename, node) ;
      else
	case(node.name)
	when 'PropertyName'
	  return scanFilterNodeBody_PropertyName(typename, node) ;
	when 'Literal' 
	  return scanFilterNodeBody_Literal(typename, node) ;
	when 'Function'
	  raise "unsupported expression : #{node.name}" ;
	else
	  raise "illegal expression : #{node.name}" ;
	end
      end
    end

    ##------------------------------
    def scanFilterNodeBody_ExpressionBinary(typename, node) 
      op = ExpressionBinaryOperator[node.name] ;
      firstArg = scanFilterNodeBody_Expression(typename, node.elements[1]) ;
      secondArg = scanFilterNodeBody_Expression(typename, node.elements[2]) ;

      qstr = ("(%s) %s (%s)" % [firstArg, op, secondArg]) ;

      return qstr ;
    end

    ExpressionBinaryOperator = {
      'Add'	=> '+',
      'Sub'	=> '-',
      'Mul'	=> '*',
      'Div'	=> '/',
      nil	=> nil
    } ;

    ##------------------------------
    def scanFilterNodeBody_PropertyName(typename, node) 
      propName = node.texts.to_s ;
      columnEntry = @processor.xsd.xPathColumnTab[typename + "/" + propName];

      raise "unknown property : #{propName}" if(columnEntry.nil?) ;

      columnName = columnEntry.column.name ;
      return columnName ;
    end

    ##------------------------------
    def scanFilterNodeBody_Geometry(typename, node) 
      geo = Geometry::scanGml(node) ;
      return geo.to_SQL() ;
    end

    ##------------------------------
    def scanFilterNodeBody_Literal(typename, node) 
      return node.texts.to_s ;
    end

    ##------------------------------
    def outputResultXml(strm,element,result)
      strm << '<?xml version="1.0" encoding="UTF-8"?>' << "\n" ;
      strm << '<FeatureCollection xmlns:gml="http://www.opengis.net/gml">' ;
      strm << "\n" ;
      
      c = 0 ;
      result.each{|row|
	strm << ' <gml:featureMember>' << "\n" ;
	outputResultXmlBody(strm,element.expandedStructure,row,2) ;
	strm << ' </gml:featureMember>' << "\n" ;
	c += 1 ;
      }

      strm << '</FeatureCollection>' << "\n" ;
    end      

    ##------------------------------
    def outputResultXmlBody(strm,structure,row,indent = 0)
      columnEntry = structure.columnEntry() ;

      if(columnEntry.nil?) then # not leaf node
	strm << (" " * indent) << ('<%s>' % structure.name) << "\n" ;
	structure.children.each{|child|
	  outputResultXmlBody(strm,child,row,indent+1) ;
	}
	strm << (" " * indent) << ('</%s>' % structure.name) << "\n" ;

      else  # leaf node
	index = structure.columnEntry.column.index() ;
	data = row[index] ;

	if(! data.nil?) then	# if data exists

	  if(columnEntry.column.isSpatial?) then  # convert geo data
	    geo = Geometry::scanWkt(data) ;
	    data = geo.to_GML ;
	  end

	  strm << (" " * indent) << ('<%s>' % structure.name) ;
	  strm << data ;
	  strm << ('</%s>' % structure.name) << "\n" ;

	end
      end
    end

    ##------------------------------
    def updateTransactionResponse(status, message, insertP = false)
      @transactionResultStatus = @transactionResultStatus && status ;

      @transactionResultMessage.push(message) if !message.nil? ;

      @transactionInsertCount += 1 if insertP ;
    end

    ##------------------------------
    def outputTransactionResponse(strm)
      if(@transactionResultStatus) then
	status = 'SUCCESS' ;
      else
	status = 'FAILED' ;
      end

      message = @transactionResultMessage.join("\n\t\t") ;

      strm << '<TransactionResponse>' << "\n" ;
      strm << '  <TransactionResult>' << "\n" ;
      strm << ("    <Status>%s</Status>" % status) << "\n" ;

      if(message != "") then
	strm << ("    <Message>%s</Message>" % message) << "\n" ;
      end

      if(@transactionInsertCount > 0) then
	strm << ("    <InsertCount>%d</InsertCount>" % 
		 @transactionInsertCount) << "\n" ;
      end
	
      strm << '  </TransactionResult>' << "\n" ;
      strm << '</TransactionResponse>' << "\n" ;
    end

  end

end
##//////////////////////////////////////////////////////////////////////

