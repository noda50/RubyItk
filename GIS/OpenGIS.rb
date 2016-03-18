## -*- Mode: ruby -*-

require 'rexml/document' ;
module XML 
  include REXML ;
end


module OpenGIS

##//////////////////////////////////////////////////////////////////////

  $gmlVersion = 2.0 ; 
  # $gmlVersion = 3.0 ;

  if($gmlVersion < 3.0) then
    $tagName_exterior = "gml:outerBoundaryIs" ;
    $tagName_interior = "gml:iinerBoundaryIs" ;
  else
    $tagName_exterior = "gml:exterior" ;
    $tagName_interior = "gml:interior" ;
  end

##----------------------------------------------------------------------
def xmlTaggedBlock(taglabel,prop,bodyStr,indent=nil)
  if(prop.is_a?(Hash)) then
    propStr = "" ;
    prop.each{|slot,value| propStr += " #{slot}='#{value}'" ;} ;
  elsif(prop.nil?()) then
    propStr = "" ;
  else 
    propStr = prop.to_s ;
  end

  if(bodyStr.nil? || bodyStr == "") then
    str = "<#{taglabel}#{propStr}/>" ;
  else
    str = "<#{taglabel}#{propStr}>#{bodyStr}</#{taglabel}>" ;
  end

  return str ;
end
   
##======================================================================
class Geometry
  ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  attr :attrList, true ;

  ##----------------------------------------
  ## Well Known Text converter
  def init() 
    @attrList = Hash::new ;
  end

  ##--------------------------------------------------
  ## WKT,WBT & SQL

  ##----------------------------------------
  ## Well Known Text tagname
  def wktTagName()
    return self.class.wktTagName() ;
  end

  ##----------------------------------------
  ## Well Known Text converter
  def to_WKT()
    raise("to_WKT(WKT converter) is not defined for this class: " +
	  self.class.name ) ;
  end

  ##----------------------------------------
  ## Well Known Binary converter
  def to_WKB()
    raise("to_WKB(WKB converter) is not defined for this class: " +
	  self.class.name ) ;
  end

  ##----------------------------------------
  ## SQL (text) string converter
  def to_SQL()
    return "GeomFromText('#{to_WKT()}')";
  end

  ##--------------------------------------------------
  ## GML

  ##----------------------------------------
  ## GML converter top
  def to_GML(indent=nil)
    return xmlTaggedBlock(gmlTagFullName(),
			  to_GML_attr(),
			  to_GML_body(),indent) ;
  end

  ##----------------------------------------
  ## GML converter for aliased class 
  def to_GML_as(aClassStr,indent=nil)
    return xmlTaggedBlock(aClassStr,
			  to_GML_attr(),
			  to_GML_body(),indent) ;
  end

  ##----------------------------------------
  ## GML format tag prefix
  def gmlTagPrefix()
    return self.class.gmlTagPrefix() ;
  end

  ##----------------------------------------
  ## GML format tagname (body)
  def gmlTagName()
    return self.class.gmlTagName() ;
  end

  ##----------------------------------------
  ## GML format tagname (fullname)
  def gmlTagFullName()
    return self.class.gmlTagFullName() ;
  end

  ##----------------------------------------
  ## to GML attrib list string in begin tag
  def to_GML_attr(indent=nil)
    attrStr = "" ;
    @attrList.each{ |slot,value| attrStr += " #{slot}='#{value}'" ; } ;
    return attrStr ;
  end

  ##----------------------------------------
  ## GML format converter
  def to_GML_body(indent=nil)
    return "" ;
  end


end

##--------------------------------------------------
## class methods for Geometry

class << Geometry
  ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  ## list of subclasses. used in scanner
  SubClassList = [Geometry] ;

  ##----------------------------------------
  ## redefine inherited to register subclass into SubClassList
  def inherited(klass)
    SubClassList.push(klass) ;
    super(klass) ;
  end

  ##--------------------------------------------------
  ## for WKT

  ##------------------------------
  ## WKT tagname

  def wktTagName()
    return "GEOMETRY" ;
  end
  
  ##------------------------------
  ## WKT scanner

  def scanWkt(str)
    matchp = (str =~ /^\s*([a-zA-Z]+)\s*\((.*)\)\s*$/) ;

    raise("unknown data format for WKT: " + str) if(!matchp) ;

    headerStr = $1 ;
    bodyStr = $2 ;
    
    klass = nil ;
    SubClassList.each{|c| 
      if(headerStr == c.wktTagName()) then
	klass = c ;
	break ;
      end
    }

    raise("unknown tagname for WKT '" + headerStr + 
	  "' in : " + str) if(klass.nil?()) ;
    
    return klass.scanWktBody(bodyStr) ;
  end

  ##------------------------------
  ## WKT scanner body

  def scanWktBody(bodyStr)
    raise("WKT scanner for Class " + wktTagName() + " is not define yet.") ;
  end

  ##--------------------------------------------------
  ## for GML
    
  ##------------------------------
  ## GML tagname

  def gmlTagPrefix() 
    return "gml" ;
  end

  ##------------------------------
  ## GML tagname

  def gmlTagName() 
    return "Geometry" ;
  end

  ##------------------------------
  ## GML tagname

  def gmlTagFullName() 
    return gmlTagPrefix() + ":" + gmlTagName() ;
  end

  ##------------------------------
  ## find class by node's tagname.  return nil if not found.

  def findClassByNodeTag(node)
    tagname = node.name() ;
    prefix = node.prefix() ;
    klass = nil ;
    SubClassList.each{|c|
      if(prefix == c.gmlTagPrefix() && tagname == c.gmlTagName()) then
	klass = c ;
	break ;
      end
    }
    return klass ;
  end

  ##------------------------------
  ## GML scanner

  def scanGml(xmlNode)
    klass = findClassByNodeTag(xmlNode) ;

    raise("unknown tagname for GML '" + xmlNode.name + "' in : " +
	  xmlNode.to_s) if (klass.nil?()) ;

    return klass.scanGmlBody(xmlNode) ;
  end
      
  ##------------------------------
  ## WKT scanner body

  def scanGmlBody(xmlNode)
    raise("GML scanner for Class " + gmlTagName() + " is not define yet.") ;
  end

end

##======================================================================
class Point < Geometry
  ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  attr :x, true ;
  attr :y, true ;

  ##----------------------------------------
  ## initialize
  def initialize(x = 0,y = 0)
    init() ;
    setXY(x,y) ;
  end

  ##----------------------------------------
  ## set by Pos
  def setPos(pos)
    @pos.copyFrom(pos) ;
  end

  ##----------------------------------------
  ## set by XY
  def setXY(x,y)
    @x = x ;
    @y = y ;
  end

  ##----------------------------------------
  ## copyFrom
  def copyFrom(point)
    setXY(point.x,point.y) ;
  end

  ##----------------------------------------
  ## bare text string of point
  def to_WKT_bare()
    return "#{@x} #{@y}" ;
  end

  ##----------------------------------------
  ## Well Known Text converter
  def to_WKT()
    return "#{wktTagName()}(#{to_WKT_bare()})" ;
  end

  ##----------------------------------------
  ## GML format converter
  def to_GML_body(indent=nil)
    rstr = xmlTaggedBlock("gml:coordinates",nil,to_GML_body_bare(indent)) ;
    return rstr ;
  end

  ##----------------------------------------
  ## GML format converter
  def to_GML_body_bare(indent=nil)
    return "#{@x},#{@y}" ;
  end

end

##--------------------------------------------------
## class methods for Point

class << Point
  ##--------------------------------------------------
  ## for WKT

  ##------------------------------
  ## WKT tagname

  def wktTagName()
    return "POINT" ;
  end
  
  ##------------------------------
  ## WKT scanner body

  def scanWktBody(bodyStr)
    matchp = (bodyStr =~ /^\s*([^\s]+)\s+([^\s]+)\s*$/) ;
    raise ("Illegal body format for WKT of Point : " + bodyStr) if(!matchp) ;
    
    xStr = $1 ; yStr = $2 ;

    return self.new(xStr.to_f,yStr.to_f) ;
  end

  ##--------------------------------------------------
  ## for GML
    
  ##------------------------------
  ## GML tagname

  def gmlTagName() 
    return "Point" ;
  end
  
  ##------------------------------
  ## GML scanner body

  def scanGmlBody(xmlNode)
    coord = XML::XPath::first(xmlNode,"gml:coordinates") ;

    raise("No coordinates elements in : " + xmlNode.to_s) if(coord.nil?) ;

    coordStr = coord.text() ;
    (xStr,yStr) = coordStr.split(',') ;

    return self.new(xStr.to_f,yStr.to_f) ;
  end

end

##======================================================================
class Curve < Geometry
  ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  attr :points, true ;  ## points should be an array of Point instances

  ##----------------------------------------
  ## initialize
  def initialize(points = Array::new()) ;
    init() ;
    setPoints(points) ;
  end

  ##----------------------------------------
  ## clear point list
  def clear()
    @points = [] ;
  end

  ##----------------------------------------
  ## set point list
  def setPoints(points) 
    clear() ;
    pushPoints(points) ;
  end

  ##----------------------------------------
  ## set point list
  def pushPoints(points) 
    points.each{|p| pushPoint(p) ; } ;
  end

  ##----------------------------------------
  ## push new pos
  def pushPoint(p) # p should be a Point or [x,y]
    if(p.is_a?(Point)) then
      @points.push(p) ;
    elsif(p.is_a?(Array)) then
      @points.push(Point::new(p[0],p[1])) ;
    else
      raise "Unknown format for pushing point data to Curve." + p.to_s ;
    end
  end

  ##----------------------------------------
  ## push new pos
  def pushXY(x,y) 
    pushPoint(Point::new(x,y)) ;
  end

  ##----------------------------------------
  ## check simplicity
  def isSimple?
    raise ("isSimple? is not defined for this class: " +
	   self.class.name ) ;
  end

  ##----------------------------------------
  ## check closed
  def isClosed?
    raise ("isClosed? is not defined for this class: " +
	   self.class.name ) ;
  end

  ##----------------------------------------
  ## bare text string of point
  def to_WKT_bare()
    ret =  "";
    @points.each{|p|
      ret += "," if(ret != "") ;
      ret += p.to_WKT_bare() ;
    }
    return "(" + ret + ")";
  end

  ##----------------------------------------
  ## GML format converter
  def to_GML_body(indent=nil)
    ret = "" ;
    @points.each{|p|
      ret +=" " if(ret != "") ;
      ret += p.to_GML_body_bare(indent) ;
    }
    rstr = xmlTaggedBlock("gml:coordinates",nil,ret) ;
    return rstr ;
  end

end

##--------------------------------------------------
## class methods for Curve

class << Curve
  ##--------------------------------------------------
  ## for WKT

  ##------------------------------
  ## WKT tagname

  def wktTagName()
    return "CURVE" ;
  end
  
  ##------------------------------
  ## WKT scanner body

  def scanWktBody(bodyStr)
    pointStrList = bodyStr.split(/,/) ;
    pointList = [] ;
    pointStrList.each { |pointStr|
      point = Point.scanWktBody(pointStr) ;
      pointList.push(point) ;
    }
    return self.new(pointList) ;
  end

  ##--------------------------------------------------
  ## for GML
    
  ##------------------------------
  ## GML tagname

  def gmlTagName() 
    return "Curve" ;
  end
  
  ##------------------------------
  ## GML scanner body

  def scanGmlBody(xmlNode)
    coord = XML::XPath::first(xmlNode,"gml:coordinates") ;

    raise("No coordinates elements in : " + xmlNode.to_s) if(coord.nil?) ;

    coordStr = coord.text() ;

    pointStrList = coordStr.split(/\s+/) ;
    pointList = [] ;
    pointStrList.each {|pointStr|
      next if (pointStr == "") ;
      (xStr,yStr) = pointStr.split(',') ;
      pointList.push(Point.new(xStr.to_f,yStr.to_f)) ;
    }

    return self.new(pointList) ;
  end

end

##======================================================================
class LineString < Curve

  ##----------------------------------------
  ## Well Known Text converter
  def to_WKT()
    return ("#{wktTagName()}#{to_WKT_bare()}") ;
  end
  
end

##--------------------------------------------------
## class methods for LineString

class << LineString
  ##--------------------------------------------------
  ## for WKT

  ##----------------------------------------
  ## WKT tagname

  def wktTagName()
    return "LINESTRING"
  end

  ##--------------------------------------------------
  ## for GML
    
  ##----------------------------------------
  ## GML tagname

  def gmlTagName()
    return "LineString" ;
  end

end

##======================================================================
class LinearRing < LineString

end

##--------------------------------------------------
## class methods for LinearRing

class << LinearRing
  
  ##--------------------------------------------------
  ## for GML
    
  ##----------------------------------------
  ## GML tagname

  def gmlTagName()
    return "LinearRing" ;
  end

end


##======================================================================
class Surface < Geometry
  ##~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  attr :exterior, true ; ## should be a Curve instance or nil
  attr :interior, true ; ## should be an array of Curve instances

  ##----------------------------------------
  ## initialize
  def initialize(exterior = nil,interior = Array::new()) ;
    init() ;
    set(exterior,interior) ;
  end

  ##----------------------------------------
  ## clear curve list
  def clear()
    @exterior = nil ;
    @interior = [] ;
  end

  ##----------------------------------------
  ## set curve list
  def set(exterior,interior)
    clear() ;
    setExterior(exterior) ;
    pushInterior(interior) ;
  end

  ##----------------------------------------
  ## push new curve
  def setExterior(exterior)
    if(exterior.is_a?(Curve)) then
      @exterior = exterior ;
    elsif(exterior.is_a?(Array)) then
      @exterior = Curve::new(exterior) ;
    else
      raise "Unknown format for pushing curve data to Surface." + 
	exterior.to_s ;
    end
  end

  ##----------------------------------------
  ## push new curve
  def pushInterior(interior)
    interior.each{|c|
      pushInterior1(c) ;
    }
  end

  ##----------------------------------------
  ## push new pos
  def pushInterior1(curve)
    if(curve.is_a?(Curve)) then
      @interior.push(curve) ;
    elsif(curve.is_a?(Array)) then
      @interior.push(Curve::new(curve))
    else
      raise "Unknown format for pushing curve data to Surface." + curve.to_s ;
    end
  end

  ##----------------------------------------
  ## bare text string of point
  def to_WKT_bare()
    ret = "(" ;
    if(!@exterior.nil?) 
      ret += @exterior.to_WKT_bare() 
    else
      ret += "()" ;
    end
    @interior.each{|c|
      ret += c.to_WKT_bare() ;
    }
    ret += ")" ;
    return ret ;
  end

end

##--------------------------------------------------
## class methods for Surface

class << Surface
  ##--------------------------------------------------
  ## for WKT

  ##----------------------------------------
  ## WKT tagname

  def wktTagName()
    return "SURFACE"
  end

  ##------------------------------
  ## WKT scanner body

  def scanWktBody(bodyStr)
    return scanWktGeneric(bodyStr,Curve) ;
  end

  ##------------------------------
  ## WKT scanner body

  def scanWktBodyGeneric(bodyStr,contentClass = Curve)
    curveStrList = bodyStr.split(/\)/) ;
    exterior = nil ;
    interior = [] ;
    curveStrList.each { |curveStr|
      curveStr.sub!(/,*\s*\(/, '') ;
      curve = contentClass.scanWktBody(curveStr) ;
      if(exterior.nil?) then
	exterior = curve ;
      else
	interior.push(curve) ;
      end
    }
    return self.new(exterior,interior) ;
  end

  ##--------------------------------------------------
  ## for GML
    
  ##----------------------------------------
  ## GML tagname

  def gmlTagName()
    return "Surface" ;
  end

  ##------------------------------
  ## GML scanner body

  def scanGmlBody(xmlNode)
    exteriorNode = XML::XPath::first(xmlNode, "gml:exterior") ||
                   XML::XPath::first(xmlNode, "gml:outerBoundaryIs") ;

    raise("No exterior elements in : " + xmlNode.to_s) if(exteriorNode.nil?) ;

    extGeo = XML::XPath::first(exteriorNode,"*") ;
    exterior = Geometry.scanGml(extGeo) ;

    interior = [] ;
    XML::XPath::each(xmlNode,"gml:interior|gml:innerBoundaryIs") { |node|
      interior.push(Geometry.scanGml(node[0])) ;
    }

    return self.new(exterior,interior) ;
  end

end

##======================================================================
class Polygon < Surface

  ##----------------------------------------
  ## Well Known Text converter
  def to_WKT()
    return ("#{wktTagName()}#{to_WKT_bare()}") ;
  end
  
  ##----------------------------------------
  ## GML format converter
  def to_GML_body(indent=nil)
    exterior = xmlTaggedBlock($tagName_exterior,nil,
			      @exterior.to_GML_as("gml:LinearRing",indent)) ;
    interior = "" ;
    @interior.each{|c|
      interior +="\n" ;
      interior += xmlTaggedBlock($tagName_interior,nil,
				 c.to_GML_as("gml:LinearRing",indent)) ;
    }
			      
    rstr = exterior + interior ;
    return rstr ;
  end

end

##--------------------------------------------------
## class methods for Polygon

class << Polygon
  ##--------------------------------------------------
  ## for WKT

  ##----------------------------------------
  ## WKT tagname

  def wktTagName()
    return "POLYGON"
  end

  ##------------------------------
  ## WKT scanner body

  def scanWktBody(bodyStr)
    return scanWktBodyGeneric(bodyStr,LineString) ;
  end

  ##--------------------------------------------------
  ## for GML
    
  ##----------------------------------------
  ## GML tagname

  def gmlTagName()
    return "Polygon" ;
  end

end

##======================================================================
class Box < Polygon

  ##----------------------------------------
  ## GML format converter
  def to_GML_body(indent=nil)
    exterior = xmlTaggedBlock($tagName_exterior,nil,
			      @exterior.to_GML_as("gml:LinearRing",indent)) ;
    interior = "" ;

    rstr = exterior + interior ;
    return rstr ;
  end

end

##--------------------------------------------------
## class methods for Polygon

class << Box
  ##--------------------------------------------------
  ## for GML
    
  ##----------------------------------------
  ## GML tagname

  def gmlTagName()
    return "Box" ;
  end

  ##------------------------------
  ## GML scanner body

  def scanGmlBody(xmlNode)
    curve = Curve.scanGmlBody(xmlNode) ;
    points = curve.points() ;
    p0 = points[0] ;  p1 = points[1] ;    

    x0 = p0.x ; y0 = p0.y ; 
    x1 = p1.x ; y1 = p1.y ;

    pointList = [[x0,y0],[x0,y1],[x1,y1],[x1,y0],[x0,y0]] ;
    ring = LinearRing::new(pointList) ;
    interior = [] ;

    return self.new(ring,interior) ;
  end
end

##======================================================================
class GeometryCollection < Geometry
  attr :geometries,	true ;

  ##----------------------------------------
  ## initialize
  def initialize(geoms = Array::new())
    init() ;
    setGeometries(geoms) ;
  end
    
  ##----------------------------------------
  ## clear list
  def clear() 
    @geometries = [] ;
  end

  ##----------------------------------------
  ## set geometry list
  def setGeometries(geoms)
    clear() ;
    pushGeometries(geoms) ;
  end

  ##----------------------------------------
  ## push geometry list
  def pushGeometries(geoms) # geoms should be an array of Geometries
    geoms.each{|geom|  
      pushGeometry(geom) ;
    } ;
  end

  ##----------------------------------------
  ## push geometry list
  def pushGeometry(geom) # geom should be a Geometry instance
    @geometries.push(geom) ; 
  end

  ##----------------------------------------
  ## Well Known Text bare converter
  def to_WKT_bare()
    ret = "" ;
    geometries.each{ |obj|
      ret += "," if (ret != "") ;
      ret += obj.to_WKT() ;
    }
    return "(" + ret + ")" ;
  end
  
  ##----------------------------------------
  ## Well Known Text converter
  def to_WKT()
    return ("#{wktTagName}#{to_WKT_bare()}") ;
  end
  
end

##--------------------------------------------------
## class methods for GeometryCollection

class << GeometryCollection
  ##--------------------------------------------------
  ## for WKT

  ##----------------------------------------
  ## WKT tagname

  def wktTagName()
    return "GEOMETRYCOLLECTION" ;
  end

  ##--------------------------------------------------
  ## for GML
    
  ##----------------------------------------
  ## GML tagname

  def gmlTagName()
    return "GeometryCollection" ;
  end

end

##======================================================================
class MultiPoint < GeometryCollection

  ##----------------------------------------
  alias setPoints	setGeometries ;
  alias pushPoints	pushGeometries ;
  alias pushPoint	pushGeometry ;

  ##----------------------------------------
  ## push geometry list
  def pushGeometry(geom) # geom should be a Point instance
    if(geom.is_a?(Point)) then
      @geometries.push(geom) ; 
    else
      raise("Unknown format for pushing point data to MultiPoint." + 
	    geom.to_s) ;
    end
  end

  ##----------------------------------------
  ## Well Known Text bare converter
  def to_WKT_bare()
    ret = "" ;
    geometries.each{ |obj|
      ret += "," if (ret != "") ;
      ret += obj.to_WKT_bare() ;
    }
    return "(" + ret + ")" ;
  end
  
  ##----------------------------------------
  ## Well Known Text tagname
  def wktTagName()
    return "MULTIPOINT" ;
  end

  ##----------------------------------------
  ## Well Known Text converter
  def to_WKT()
    return ("#{wktTagName()}#{to_WKT_bare()}") ;
  end
  
end

##--------------------------------------------------
## class methods for MultiPoint

class << MultiPoint
  ##--------------------------------------------------
  ## for WKT

  ##----------------------------------------
  ## WTK tagname

  def wktTagName()
    return "MULTIPOINT" ;
  end

  ##--------------------------------------------------
  ## for GML
    
  ##----------------------------------------
  ## GML tagname

  def gmlTagName()
    return "MultiPoint" ;
  end

end

##======================================================================
class MultiCurve < GeometryCollection

end

##--------------------------------------------------
## class methods for MultiCurve

class << MultiCurve
  ##--------------------------------------------------
  ## for WKT

  ##----------------------------------------
  ## WKT tagname

  def wktTagName()
    return "MULTICURVE" ;
  end

  ##--------------------------------------------------
  ## for GML
    
  ##----------------------------------------
  ## GML tagname

  def gmlTagName()
    return "MultiCurve" ;
  end

end

##======================================================================
class MultiLineString < MultiCurve

  ##----------------------------------------
  alias setLineStrings	setGeometries ;
  alias pushLineStrings	pushGeometries ;
  alias pushLineString	pushGeometry ;

  ##----------------------------------------
  ## push geometry list
  def pushGeometry(geom) # geom should be a LineString instance
    if(geom.is_a?(LineString)) then
      @geometries.push(geom) ; 
    else
      raise("Unknown format for pushing point data to MultiLineString." + 
	    geom.to_s) ;
    end
  end

  ##----------------------------------------
  ## Well Known Text bare converter
  def to_WKT_bare()
    ret = "" ;
    geometries.each{ |obj|
      ret += "," if (ret != "") ;
      ret += obj.to_WKT_bare() ;
    }
    return "(" + ret + ")" ;
  end
  
  ##----------------------------------------
  ## Well Known Text converter
  def to_WKT()
    return ("#{wktTagName()}#{to_WKT_bare()}") ;
  end

end

##--------------------------------------------------
## class methods for MultiLineString

class << MultiLineString
  ##--------------------------------------------------
  ## for WKT

  ##----------------------------------------
  ## WKT tagname

  def wktTagName()
    return "MULTILINESTRING" ;
  end

  ##--------------------------------------------------
  ## for GML
    
  ##----------------------------------------
  ## GML tagname

  def gmlTagName()
    return "MultiLineString" ;
  end

end

##======================================================================
class MultiSurface < GeometryCollection

end

##--------------------------------------------------
## class methods for MultiSurface

class << MultiSurface
  ##--------------------------------------------------
  ## for WKT

  ##----------------------------------------
  ## WKT tagname

  def wktTagName()
    return "MULTISURFACE" ;
  end

  ##--------------------------------------------------
  ## for GML
    
  ##----------------------------------------
  ## GML tagname

  def gmlTagName()
    return "MultiSurface" ;
  end

end

##======================================================================
class MultiPolygon < MultiSurface

  ##----------------------------------------
  alias setPolygons	setGeometries ;
  alias pushPolygons	pushGeometries ;
  alias pushPolygon	pushGeometry ;

  ##----------------------------------------
  ## push geometry list
  def pushGeometry(geom) # geom should be a Polygon instance
    if(geom.is_a?(Polygon)) then
      @geometries.push(geom) ; 
    else
      raise("Unknown format for pushing point data to MultiPolygon." + 
	    geom.to_s) ;
    end
  end

  ##----------------------------------------
  ## Well Known Text bare converter
  def to_WKT_bare()
    ret = "" ;
    geometries.each{ |obj|
      ret += "," if (ret != "") ;
      ret += obj.to_WKT_bare() ;
    }
    return "(" + ret + ")" ;
  end
  
  ##----------------------------------------
  ## Well Known Text converter
  def to_WKT()
    return ("#{wktTagName()}#{to_WKT_bare()}") ;
  end

end

##--------------------------------------------------
## class methods for MultiPolygon

class << MultiPolygon
  ##--------------------------------------------------
  ## for WKT

  ##----------------------------------------
  ## WKT tagname

  def wktTagName()
    return "MULTIPOLYGON" ;
  end

  ##--------------------------------------------------
  ## for GML
    
  ##----------------------------------------
  ## GML tagname

  def gmlTagName()
    return "MultiPolygon" ;
  end

end


##======================================================================
##======================================================================
# followings are original classes


##======================================================================
class Rectangle < Polygon

  ##----------------------------------------
  ## initizlize
  def initialize(n = 0, s = 0, e = 0, w = 0)
    init() ;
    clear() ;
    setByNSEW(n,s,e,w) ;
  end

  ##----------------------------------------
  ## ne,nw,sw,se
  def ne()
    return @exterior[0] ;
  end

  def nw()
    return @exterior[1] ;
  end

  def sw()
    return @exterior[2] ;
  end

  def se()
    return @exterior[3] ;
  end

  ##----------------------------------------
  ## north/south/east/west
  def north()
    return ne().x() ;
  end

  def south()
    return se().x ;
  end

  def east()
    return ne().y ;
  end

  def west()
    return nw().y ;
  end

  ##----------------------------------------
  ## set by N,S,E,W
  def setByNSEW(n,s,e,w) 
    setExterior([[n,e],[n,w],[s,w],[s,e],[n,e]]) ;
  end

  ##----------------------------------------
  ## set by center and size
  def setByCenter(center,size) # center and size should be Point
    dx = size.x / 2 ;
    dy = size.y / 2 ;
    setByNSEW(center.x + dx, center.x - dx, center.y + dy, center.y - dy) ;
  end

  ##----------------------------------------
  ## center and size
  def center
    return Point::new(((north() + south())/2), ((east() + west())/2)) ;
  end

  def size
    return Point::new((north() - south()), (east() + west())) ;
  end

end



##//////////////////////////////////////////////////////////////////////
end

