## -*- Mode: ruby -*-

$LOAD_PATH.push("/usr/users/noda/lib/ruby") ;

require 'ItkXml.rb' ;

##======================================================================
module KmlUtility ; end 
class << KmlUtility
  include KmlUtility ;
  extend KmlUtility ;
end

module KmlUtility

  ##==================================================
  class LonLat
    attr :lon, true ;
    attr :lat, true ;
    attr :height, true ;
    
    ##------------------------------
    def initialize(lon = 0.0, lat = 0.0, height = 0.0)
      @lon = lon ;
      @lat = lat ;
      @height = height ;
    end
  end

  ##==================================================
  class PosXY
    attr :x, true;
    attr :y, true;
    attr :z, true;

    ##------------------------------
    def initialize(x = 0.0, y = 0.0, z = 0.0)
      @x = x ;
      @y = y ;
      @z = z ;
    end
  end

  ##--------------------------------------------------
  ## degree radian Transform Utilities
  Deg2Rad = Math::PI / 180.0 ;
  Rad2Deg = 1.0 / Deg2Rad ;

  ##------------------------------
  def deg2rad(deg)
    deg * Deg2Rad ;
  end

  ##------------------------------
  def rad2deg(rad)
    rad * Rad2Deg ;
  end

  ##------------------------------
  def dms2deg(deg,min = 0,sec = 0)
    deg + min / 60.0 + sec / (60.0 * 60.0) 
  end

  ##--------------------------------------------------
  # 日本平面直角座標系 (JapanPlaneRecangularCS)
  JPRCS_Origin = {
    :I		=> LonLat.new(dms2deg(129, 30),	33.0),
    :II		=> LonLat.new(dms2deg(131,  0),	33.0),
    :III	=> LonLat.new(dms2deg(132, 10),	36.0),
    :IV		=> LonLat.new(dms2deg(133, 30),	33.0),
    :V		=> LonLat.new(dms2deg(134, 20),	36.0),
    :VI		=> LonLat.new(dms2deg(136,  0),	36.0),
    :VII	=> LonLat.new(dms2deg(137, 10),	36.0),
    :VIII	=> LonLat.new(dms2deg(138, 30),	36.0),
    :IX		=> LonLat.new(dms2deg(139, 50),	36.0),
    :X		=> LonLat.new(dms2deg(140, 50),	40.0),
    :XI		=> LonLat.new(dms2deg(140, 15),	44.0),
    :XII	=> LonLat.new(dms2deg(142, 15),	44.0),
    :XIII	=> LonLat.new(dms2deg(144, 15),	44.0),
    :XIV	=> LonLat.new(dms2deg(142,  0),	26.0),
    :XV		=> LonLat.new(dms2deg(127, 30),	26.0),
    :XVI	=> LonLat.new(dms2deg(124,  0),	26.0),
    :XVII	=> LonLat.new(dms2deg(131,  0),	26.0),
    :XVIII	=> LonLat.new(dms2deg(136,  0),	20.0),
    :XIX	=> LonLat.new(dms2deg(154,  0),	26.0),
  } ;

  ##------------------------------
  ## Geometry Constants
  EquatorRadius = 6378137.0 ;  # [m]
  EquatorLength = EquatorRadius * 2 * Math::PI ;
  MeridianLength = 10001.96 * 1000 ;
  
  Y2Lat = 90.0 / MeridianLength ;

  ##------------------------------
  def toLonLat(csID, x, y)
    origin = JPRCS_Origin[csID] ;
    raise "Unknown Coordinate System ID: " + csID if(origin.nil?) ;

    lat = origin.lat + y * Y2Lat ;
    latLen = EquatorLength * Math::cos(deg2rad(lat)) ;
    lon = origin.lon + 360.0 * (x / latLen) ;

    return LonLat.new(lon,lat) ;
  end

  ##------------------------------
  def toDLonLat(dx, dy, baseLonLat)
    dLat = dy * Y2Lat ;
    latLen = EquatorLength * Math::cos(deg2rad(baseLonLat.lat)) ;
    dLon = 360.0 * (dx / latLen) ;
    return LonLat.new(dLon,dLat) ;
  end

  ##--------------------------------------------------
  ## coords utility

  ##------------------------------
  def genRectangleCoordList(center, diff)  ## center and diff should be LonLat
    coordList = [] ;

    [[:n, :n],[:p, :n],[:p, :p],[:n, :p]].each{|op|
      coord = center.dup() ;
      coord.lon += ((op[0] == :n) ? -(diff.lon) : (diff.lon)) ;
      coord.lat += ((op[1] == :n) ? -(diff.lat) : (diff.lat)) ;
      coordList.push(coord) ;
    }

    return coordList ;
  end

  ##------------------------------
  def genCoordString(coordList)  ## coordList ::= [[x,y,z],...] or [LonLat,...]
    str = nil ;
    coordList.each{|coord|
      if(str.nil?)
        str = "" ;
      else
        str += " " ;
      end
      
      if(coord.is_a?(LonLat))
        str += ("%f,%f,%f" % [coord.lon, coord.lat, coord.height.to_f]) ;
      elsif (coord.is_a?(PosXY))
        str += ("%f,%f,%f" % [coord.x, coord.y, coord.z.to_f]) ;
      elsif (coord.is_a?(Array))
        str += ("%f,%f,%f" % [coord[0], coord[1], coord[2].to_f]) ;
      else
        raise "can not convert coord string from : " + coord.to_s ;
      end
    }
    return str ;
  end

  ##--------------------------------------------------
  ## other utility

  ##------------------------------
  def mergeParam(baseParam, optionParam, dupP = true)
    newParam = (dupP ? baseParam.dup() : baseParam) ;

    optionParam.each{|key,value|
      newParam[key] = value ;
    }
  end

  ##==================================================
  class Placemark
  end

  ##==================================================
  class PlacemarkPoint < Placemark
  end

  ##==================================================
  class PlacemarkLine < Placemark
  end

  ##==================================================
  class PlacemarkPolygon < Placemark
  end

  ##==================================================
  class PlacemarkRectangle < PlacemarkPolygon
  end

  ##==================================================
  class Document
    attr :name, true ;
    attr :styleMapTable, true ;
    attr :styleTable, true ;
    attr :folderTable, true ;
    attr :folderList, true ;

    attr :param, true ;

    DefaultStyleMapPrefix = 'sm' ;
    DefaultStyleNormalPrefix = 'sn' ;
    DefaultStyleHighlightPrefix = 'sh' ;
    DefaultStyleName = 'DefaultStyle' ;
    
    DefaultIconScaleNormal = 1.0 ;
    DefaultIconScaleHighlight = 1.2 ;
    

    DefaultParam = {
      :defaultStyleMapId => DefaultStyleMapPrefix + DefaultStyleName,
      :defaultStyleNormalId => DefaultStyleNormalPrefix + DefaultStyleName,
      :defaultStyleHighlightId => (DefaultStyleHighlightPrefix + 
                                   DefaultStyleName),
      :iconScaleNormal => DefaultIconScaleNormal,
      :iconScaleHighlight => DefaultIconScaleHighlight,
    } ;

    ##------------------------------
    def initialize(name, param = {})
      @name = name ;
      @param = mergeParam(DefaultParam, param, true) ;

      @styleMapTable = {} ;
      @styleTable = {} ;
      @folderTable = [] ;
      @folderTable = {} ;

      registerStyle(@param[:defaultStyleNormalId],
                    {:iconScale => @param[:iconScaleNormal]}) ;
      registerStyle(@param[:defaultStyleHighlightId],
                    {:iconScale => @param[:iconScaleHighlight]}) ;
      registerStyleMap(@param[:defaultStyleMapId],
                       @param[:defaultStyleNormalId],
                       @param[:defaultStyleHighlightId]) ;
    end

    ##------------------------------
    def registerStyleMap(styleMapId, normalStyleId, highlightStyleId)
      styleMap = StyleMap.new(styleId, normalStyleId, highlightStyleId)
      @styleMapList[styleMapId] = styleMap ;
      return styleMap ;
    end
                      
    ##------------------------------
    def getStyleMap(styleMapId)
      return @styleMapList[styleMapId] ;
    end

    ##------------------------------
    def registerStyle(styleId, styleParam = {})
      style = Style.new(styleId, styleParam)
      @styleList[styleId] = style ;
      return style ;
    end
                      
    ##------------------------------
    def getStyle(styleId)
      return @styleList[styleId] ;
    end

    ##------------------------------
    def addFolder(folderName, placemarkList = [], openP = false)
      folder = Folder.new(folderName, placemarkList, openP) ;
      @folderList.push(folder) ;
      @folderTable[folderName] = folder ;
    end

    ##------------------------------
    def getFolder(folderName)
      return @folderTable[folderName] ;
    end

    ##------------------------------
    def addPlacemark(folderName, pmark)
      getFolder(folderName).addPlacemark(pmark) ;
    end

    ##------------------------------
    def to_Axml(kmlEnvP = true)
      doc = ['Document',
             ['name', @name]] ;
      @styleMapTable.each{|key,smap|
        doc.push(smap.to_Axml) ;
      }
      @styleTable.each{|key,style|
        doc.push(style.to_Axml) ;
      }
      @folderList.each{|folder|
        doc.push(folder.to_Axml) ;
      }

      if(kmlEnvP)
        return [[nil, 'kml', ['xmlns','http://earth.google.com/kml/2.2']],
                doc] ;
      else
        return doc ;
      end
    end
  end

  ##========================================
  class StyleMap
    attr :styleId, true ;
    attr :normal, true ;
    attr :highlight, true ;

    ##------------------------------
    def initialize(id, normal, highlight)
      @styleId = id ;
      @normal = normal ;
      @highlight = highlight ;
    end

    ##------------------------------
    def to_Axml
      return [[nil, 'StyleMap', ['id', @styleId]],
              ['Pair', 
               ['key', 'normal'],
               ['styleUrl', '#' + @normal]],
              ['Pair',
               ['key', 'highlight'],
               ['styleUrl', '#' + @highlight]]] ;
    end
  end

  ##========================================
  class Style
    attr :styleId, true ;
    attr :param, true ;

    DefaultColor = 'ffffffff' ; ## TTRRGGBB  (T: Transparent)
    DefaultIcon = 'http://maps.google.com/mapfiles/kml/pushpin/ylw-pushpin.png';
    DefaultScale = 1.0 ;
    DefaultHotspot = [20,2] ;

    DefaultParam = {
      :iconUrl => DefaultIcon,
      :iconScale => DefaultScale,
      :iconColor => DefaultColor,
      :lineColor => DefaultColor,
      :polyColor => DefaultColor,
      :iconHotspot => DefaultHotspot,
    } ;

    ##------------------------------
    def initialize(id, param = {})
      @styleId = id ;
      @maram = mergeParam(DefaultParam, param, true) ;
    end

    ##------------------------------
    def to_Axml()
      return [[nil, 'Style', ['id', @styleId]],
              ['IconStyle',
               ['scale', @param[:iconScle]],
               ['Icon', ['href', @param[:iconUrl]]],
               [[nil, 'hotSpot', 
                 ['x', @param[:iconHotspot][0]],
                 ['y', @param[:iconHotspot][1]],
                 ['xunits', 'pixels'],
                 ['yunits', 'pixels']]]],
              ['LineStyle', 
               ['color', @param[:lineColor]]],
              ['PolyStyle', 
               ['color', @param[:polyColor]]]] ;
    end
  end

  ##==================================================
  class Folder
    attr :name, true ;
    attr :openP, true ;
    attr :placemarkList, true ;

    ##------------------------------
    def initialize(name, placemarkList = [], openP = false)
      @name = name ;
      @placemarkList = placemarkList ;
      @openP = openP ;
    end

    ##------------------------------
    def push(pmark)
      addPlacemark(pmark) ;
    end

    ##------------------------------
    def addPlacemark(pmark)
      @placemarkList.push(pmark) ;
    end

    ##------------------------------
    def to_Axml()
      folder = ['Folder', 
                ['name', @name],
                ['open', (@openP ? 1 : 0)]] ;

      @placemarkList.each{|pmark|
        if(pmark.is_a?(Placemark))
          folder.push(pmark.to_Axml) ;
        else
          folder.push(pmark) ;
1        end
      }

      return folder ;
    end
  end



end

##======================================================================
##======================================================================
##======================================================================
if(__FILE__ == $0) then

  ##------------------------------
  def test0()
    kdoc = KmlUtility::Document.new('foo') ;
    p kdoc.to_Axml() ;
  end

  ##==================================================
  ##==================================================
  ##==================================================
  test0() ;

end




  



