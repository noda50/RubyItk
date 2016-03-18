## -*- Mode: ruby -*-

##======================================================================
class ItkSqlColumnDef

  ##------------------------------
  ## slots

  attr :name, true ;
  attr :type, true ;
  attr :length, true ;
  attr :flags, true ;
  attr :index, true ;	# index in column list in table. 
                        # used to analyze answer in select

  ##------------------------------
  ## flag constants

  F_Index 	= 'index' ;
  F_NotNull 	= 'not_null' ;
  F_Uniq 	= 'uniq' ;
  F_AutoIncrement = 'auto_increment' ;

  ##------------------------------
  ## initialize

  def initialize(name,type,flags=[])
    @name = name ;

    if(type.is_a?(Array)) then
      @type = type[0] ;
      @length = type[1] ;
    else
      @type = type ;
      @length = nil ;
    end
      
    @flags = flags ;
    adjustAllFlagDependency() ;
  end

  ##------------------------------
  ## flag operation

  def addFlag(flag)
    @flags.push(flag) if !chkFlag(flag) ;
  end

  def deleteFlag(flag)
    @flags.delete(flag) ;
  end

  def chkFlag(flag)
    return @flags.member?(flag) ;
  end

  ##------------------------------
  ## flag dependency check

  def adjustFlagDependency(flag)
    depFlag = nil ;
    case(flag)
    when F_AutoIncrement
      depFlag = F_Index ;
    when F_Index
      depFlag = F_NotNull ;
    when F_Uniq
      depFlag = F_NotNull ;
    end
    if(!depFlag.nil?) then
      addFlag(depFlag) ;
      adjustFlagDependency(depFlag) ;
    end
  end

  def adjustAllFlagDependency()
    @flags.each{|f|
      adjustFlagDependency(f) ;
    }
  end
    
  ##------------------------------
  ## check individual flags
  
  def isIndex?()
    return chkFlag(F_Index) ;
  end

  def isNotNull?()
    return chkFlag(F_NotNull) ;
  end

  def isUniq?()
    return chkFlag(F_Uniq) ;
  end

  def isAutoIncrement?()
    return chkFlag(F_AutoIncrement) ;
  end

  ##------------------------------
  ## spatial check

  SpatialTypes = [
    'geometry',
    'point','linestring','polygon',
    'multipoint','multilinestring','geometrycollection'] ;

  def isSpatial?()
    return SpatialTypes.member?(@type) ;
  end

  ##------------------------------
  ## declare string

  def strDeclare(withIndexP = FALSE)
    str = "" ;
    str += "#{@name} #{@type}" ;
    str += "(#{@length.to_i})" 	if(!@length.nil?) ;
    str += " not null" 		if(isNotNull?()) ;
    str += " uniq"		if(isUniq?()) ;
    str += " auto_increment"	if(isAutoIncrement?()) ;

    if(withIndexP && isIndex?()) then
      str += ", " ;
      str += "spatial " if(isSpatial?()) ;
      str += "index" ;
      str += " (#{@name})" ;
    end

    return str ;
  end
  
  ##------------------------------
  ## show string
  
  def strShow()
    if(isSpatial?()) then
      return "AsText(#{@name})"
    else
      return @name.to_s ;
    end
  end

end

##======================================================================
class ItkSqlTableDef

  ##------------------------------
  ## slots

  attr :name,		true ;
  attr :columns,	true ; # array of column defs
  attr :columnTable,	true ; # hash table of column defs

  ##------------------------------
  ## initialize

  def initialize(name,colDefs)
    init(name,colDefs) ;
  end

  ##------------------------------
  ## init body

  def init(name,colDefs)
    @name = name ;
    @columns = Array::new ;
    @columnTable = Hash::new ;
    addColumns(colDefs) ;
  end

  ##------------------------------
  ## add column

  def addColumn(colDef)
    if(colDef.is_a?(ItkSqlColumnDef))
      col = colDef ;
    elsif(colDef.is_a?(Array)) # suppose colDef = [name,[type,length],flags]
      col = ItkSqlColumnDef::new(colDef[0],colDef[1],colDef[2]) ;
    else
      raise("Unknown format for column defs:" + colDef.to_s) ;
    end
    col.index = @columns.length() ;
    @columns.push(col) ;
    @columnTable[col.name] = col ;

    return col
  end

  ##------------------------------
  ## add column list

  def addColumns(colDefs)
    colDefs.each{|col|
      addColumn(col) ;
    }
    return @columns ;
  end

  ##------------------------------
  ## get column

  def column(name)
    return @columnTable[name] ;
  end

  ##------------------------------
  ## column declare string

  def strDeclareCol(withIndexP = TRUE) 
    str = "" ;
    @columns.each{ |col|
      str += ", " if(str != "") ;
      str += col.strDeclare(withIndexP) ;
    }
    return str ;
  end
    
  ##------------------------------
  ## column show string

  def strShowCol()
    str = "" ;
    @columns.each{ |col|
      str += ", " if(str != "") ;
      str += col.strShow() ;
    }
    return str ;
  end
  
  ##------------------------------
  ## string for create table

  def strCreateTable()
    return "create table #{@name} (#{strDeclareCol()});"
  end

  ##------------------------------
  ## string for drop table

  def strDropTable()
    return "drop table #{@name};"
  end

  ##------------------------------
  ## string for simple insert

  def strSimpleInsert(colValList,delayP = FALSE) 
    			# colValList = [[col,val],[col,val],...]
    collist = "" ;
    vallist = "" ;
    colValList.each{ |cv|
      col = cv[0] ; val = cv[1] ;
      col = col.name() if(col.is_a?(ItkSqlColumnDef)) ;

      collist += ", " if(collist != "") ;
      collist += col.to_s ;

      vallist += ", " if(vallist != "") ;
      vallist += val.to_s ;
    }

    str = "insert" ;
    str += " delayed" if delayP ;
    str += " into #{@name}" ;
    str += " (#{collist}) values (#{vallist})" ;
    str += ";" ;

    return str ;
  end

  ##------------------------------
  ## string for simple select

  def strSimpleSelect(strCond = nil, strShow = nil)
    strShow = strShowCol() if(strShow.nil?) ;

    str = "select #{strShow} from #{@name}" ;
    
    if(!strCond.nil?) then
      str += " where #{strCond}" ;
    end

    str += ";" ;
  end

  ##------------------------------
  ## string for simple count

  def strSimpleCount(strCond = nil)
    return strSimpleSelect(strCond,'count(*)') ;
  end

  ##--------------------------------------------------
  ## describe

  def describe(strm = $stdout)
    strm << '#' << self.class.name << '[' << 'name="' << @name << '"]' ;
    strm << "\n" ;

    strm << "\t" << "column declaration : " << "\n\t\t" ;
    strm << strDeclareCol.gsub(/,\s+/,",\n\t\t") ;
    strm << "\n" ;
  end

end

##======================================================================

ItkSqlTableDefConstName = 'TableDef' ;

class ItkSqlTableEntry

  ##------------------------------
  ## Table Definitions

  def tableDef()
    return self.class.const_get(ItkSqlTableDefConstName) ;
  end
    

  ##------------------------------
  ## list of col-val pair for insert operation

  def listColValForInsert()
    list = Array::new ;
    tableDef().columns.each{|col|
      next if(col.isAutoIncrement?()) ;
      
      if(col.isSpatial?()) then
	valstr = eval("#{col.name}.to_SQL") ;
      else
	valstr = "'" + eval("#{col.name}").to_s + "'" ;
      end
      list.push([col.name,valstr]) ;
    }
    return list ;
  end

  ##------------------------------
  ## generate simple insert operation string

  def strSimpleInsert(delayP = FALSE)
    return tableDef.strSimpleInsert(listColValForInsert(),delayP) ;
  end

end

##--------------------------------------------------
class << ItkSqlTableEntry

  def declareTable(name,columns)
    self.const_set(ItkSqlTableDefConstName,
		   ItkSqlTableDef::new(name,columns)) ;
    columns.each{|col|
      attr(col[0],true) ;
    }
  end

  def tableDef()
    return self.const_get(ItkSqlTableDefConstName) ;
  end

  def strCreateTable() 
    tableDef().strCreateTable() ;
  end

  def strDropTable() 
    tableDef().strDropTable() ;
  end

  def strSimpleCount(cond) ;
    tableDef().strSimpleCount(cond) ;
  end

  def strSimpleSelect(cond) ;
    tableDef().strSimpleSelect(cond) ;
  end
end


