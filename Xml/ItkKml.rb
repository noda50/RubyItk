## -*- Mode: ruby -*-

$LOAD_PATH.push("/usr/users/noda/lib/ruby") ;

require 'ItkXml.rb' ;
require 'WithConfParam.rb' ;
require 'Geo2DGml.rb' ;
require 'pp' ;

##======================================================================
module ItkKml ; end 
class << ItkKml
  include ItkKml ;
  extend ItkKml ;
end

##======================================================================
##======================================================================
module ItkKml

  ##======================================================================
  class LatLon < Geo2D::Point

    ##::::::::::::::::::::::::::::::::::::::::::::::::::

    ##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    alias :lat :x ;
    alias :lat= :x= ;
    alias :lon :y ;
    alias :lon= :y= ;

    attr :alt, true ;
    
    ##--------------------------------------------------
    def initialize(lat = nil, lon = nil, alt = nil)
      if(lat.is_a?(Geo2D::Vector)) then
        setByPoint(lat) ;
      elsif(lat)
        set(lat, lon, alt) ;
      end
    end

    ##--------------------------------------------------
    def set(lat, lon, alt = 0)
      self.lat = convert2deg(lat) ;
      self.lon = convert2deg(lon) ;
      @alt = alt ;
    end

    ##--------------------------------------------------
    def setByPoint(geoPoint, alt = 0)
      self.lat = geoPoint.x ;
      self.lon = geoPoint.y ;
    end

    ##--------------------------------------------------
    def convert2deg(value)
      return ((value.is_a?(String)) ? dms2deg(value) : value) ;
    end

    ##--------------------------------------------------
    def dms2deg(str)
      v = str.split('.').map ;
      sec = v[2].to_f + (v[3].to_f / (10.0 ** v[3].length)) ;
      min = v[1].to_f + (sec / 60.0) ;
      deg = v[0].to_f + (min / 60.0) ;
      return deg ;
    end

    ##--------------------------------------------------
    def jpn2wgs()
      ## À¤³¦Â¬ÃÏ·Ï°ÞÅÙ = ÆüËÜÂ¬ÃÏ·Ï°ÞÅÙ - 0.00010695*ÆüËÜÂ¬ÃÏ·Ï°ÞÅÙ 
      ##                  + 0.000017464*ÆüËÜÂ¬ÃÏ·Ï·ÐÅÙ + 0.0046017
      newLat = (self.lat - 0.00010695 * self.lat + 
                0.000017464 * self.lon + 0.0046017) ;

      ## À¤³¦Â¬ÃÏ·Ï·ÐÅÙ = ÆüËÜÂ¬ÃÏ·Ï·ÐÅÙ - 0.000046038 * ÆüËÜÂ¬ÃÏ·Ï°ÞÅÙ 
      ##                  - 0.000083043 * ÆüËÜÂ¬ÃÏ·Ï·ÐÅÙ + 0.010040
      newLon = (self.lon - 0.000046038 * self.lat - 
                0.000083043 * self.lon + 0.010040) ;

      LatLon.new(newLat, newLon) ;
    end

    ##--------------------------------------------------
    def to_coordinates()
      if(@alt.nil?)
        return [self.lon,self.lat,0].join(",") ;
      else
        return [self.lon, self.lat, @alt].join(",") ;
      end
    end

    ##--------------------------------------------------
    def to_s()
      ('#<LatLon:%10.7f, %11.7f>'  % [self.lat, self.lon])
    end

    ##--------------------------------------------------
    def inspect()
      ('<LatLon:%10.7f, %11.7f>'  % [self.lat, self.lon])
    end

    ##--------------------------------------------------
    def equal(latlon)
      (self.lat == latlon.lat && 
       self.lon == latlon.lon && 
       self.alt == latlon.alt) 
    end

    ##--------------------------------------------------
    MedianLength = 10001.96 ; # [km]
    Equater = 40075.017/4.0 ; # [km]

    def km2deg(dx, dy)  ## dx to North, dy to East
      latVal = 90.0 * dx / MedianLength ;
      lonVal = 90.0 * dy / (Equater * Math::cos(Geo2D::deg2rad(self.lat))) ;

      return [latVal, lonVal] ;
    end

    ##--------------------------------------------------
    def deg2km(dLat, dLon)  
      dx = MedianLength * dLat / 90.0 ;
      dy = (Equater * Math::cos(Geo2D::deg2rad(self.lat))) * dLon / 90.0 ;

      return [dx, dy] ;
    end

  end ## class LatLon

  ##======================================================================
  class Style < WithConfParam

    ##==================================================
    class Label < WithConfParam
      ##::::::::::::::::::::::::::::::
      DefaultConf = { 
        :scale => 1.0,
        :color => 'b2ffffff',
        nil => nil 
      } ;
      ##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
      ##------------------------------
      def to_Axml
        ['LabelStyle',
         ['scale', getConf(:scale)],
         ['color', getConf(:color)]] ;
      end
    end ## class Icon 

    ##==================================================
    class Icon < WithConfParam
      ##::::::::::::::::::::::::::::::
      DefaultConf = { 
        :color => nil,
        :scale => 1.0,
        :href => 'http://maps.google.com/mapfiles/kml/paddle/red-diamond.png',
        :hotSpot => ({ 'x' => 20, 'y' => 20, 
                       'xunits' => 'pixels', 'yunits' => 'pixels' }),
        nil => nil 
      } ;
      ##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
      ##------------------------------
      def to_Axml
        ['IconStyle',
         ['color', getConf(:color)],
         ['scale', getConf(:scale)],
         ['Icon',
          ['href', getConf(:href)]],
         [[nil, 'hotSpot', getConf(:hotSpot)]]]
      end
    end ## class Icon 

    ##==================================================
    class Line < WithConfParam
      ##::::::::::::::::::::::::::::::
      DefaultConf = { 
        :color => '7f00aaff',
        :width => '2',
        nil => nil 
      } ;
      ##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
      ##------------------------------
      def to_Axml
        ['LineStyle',
         ['color', getConf(:color)],
         ['width', getConf(:width)]] ;
      end
    end ## class Line 

    ##==================================================
    class Poly < WithConfParam
      ##::::::::::::::::::::::::::::::
      DefaultConf = { 
        :color => '7f00aaff',
        :fill => true,
        nil => nil 
      } ;
      ##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
      ##------------------------------
      def to_Axml
        ['PolyStyle',
         ['color', getConf(:color)],
         ['fill', (getConf(:fill) ? 1 : 0)]] ;
      end
    end ## class Line 

    ##::::::::::::::::::::::::::::::::::::::::::::::::::
    DefaultConf = {
      nil => nil 
    } ;
    
    ##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    attr :id, true ;
    attr :icon, true ;
    attr :label, true ;
    attr :line, true ;
    attr :poly, true ;

    ##--------------------------------------------------
    def initialize(id, conf = {})
      super(conf) ;
      @id = id ;

      @icon = getConfStyleItem(:icon, Icon) ;
      @label = getConfStyleItem(:label, Label) ;
      @line = getConfStyleItem(:line, Line) ;
      @poly = getConfStyleItem(:poly, Poly) ;

    end

    ##--------------------------------------------------
    def getConfStyleItem(key, klass)
      style = getConf(key) ;
      if(style.is_a?(Hash))
        style = klass.new(style) ;
      elsif(style == true)
        style = klass.new() ;
      end
    end

    ##--------------------------------------------------
    def to_Axml()
      axml = [(@id.nil? ? 'Style' : [nil, 'Style', ['id', @id]])] ;

      axml.push(@icon.to_Axml) if(@icon) ;
      axml.push(@label.to_Axml) if(@label) ;
      axml.push(@line.to_Axml) if(@line) ;
      axml.push(@poly.to_Axml) if(@poly) ;

      return axml
    end

  end

  ##======================================================================
  class StyleMap < WithConfParam
    ##::::::::::::::::::::::::::::::::::::::::::::::::::
    DefaultConf = { 
      :normal => '#normal',
      :highlight => '#highlight',
      nil => nil 
    } ;
    ##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    attr :id, true ;
    attr :normal, true ;
    attr :highlight, true ;

    ##--------------------------------------------------
    def initialize(id = nil, conf = {})
      @id = id ;
      super(conf) ;
      @normal = getConf(:normal) ;
      @highlight = getConf(:highlight) ;
    end

    ##--------------------------------------------------
    def to_Axml()
      axml = [(@id ? 'StyleMap' : [nil, 'StyleMap', ['id', @id]]),
              ['Pair',
               ['key', 'normal'],
               ['styleUrl', @normal]],
              ['Pair',
               ['key', 'highlight'],
               ['styleUrl', @highlight]]] ;
      return axml ;
    end

  end ## class StyleMap 

  ##======================================================================
  class Placemark < WithConfParam
    ##::::::::::::::::::::::::::::::::::::::::::::::::::
    GeoType = nil ;
    DefaultConf = { 
      :open => true,
      :timestamp => nil,
      :lookAt => nil,
      :description => nil,
      :style => nil,
      :styleUrl => nil,
      :altitudeMode => nil,  ## nil | :relativeToGround | ???
      nil => nil 
    } ;

    ##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    attr :name, true ;
    attr :open, true ;
    attr :description, true ;
    attr :style, true ;
    attr :lookAt, true ;
    attr :coord, true ;
    attr :timestamp, true ;

    ##--------------------------------------------------
    def initialize(name = nil, conf = {})
      @name = name ;
      super(conf) ;
      @open = getConf(:open) ;
      @lookAt = getConf(:lookAt) ;
      @style = getConf(:style) ;
      @description = getConf(:description) ;
      @timestamp = getConf(:timestamp) ;
    end

    ##--------------------------------------------------
    def to_Axml()
      axml = ['Placemark', 
              ['name', @name.to_s],
              ['open', (@open ? 1 : 0)]] ;

      axml.push(to_Axml_timestamp()) if (!@timestamp.nil?) ;

      axml.push(to_Axml_lookAt()) if(!@lookAt.nil?) ;

      axml.push(to_Axml_style()) if(!@style.nil?) ;

      axml.push(to_Axml_description()) if (!@description.nil?) ;

      axml.push(to_Axml_geometry()) ;

      return axml ;
    end

    ##--------------------------------------------------
    def to_Axml_timestamp()
      ['TimeStamp',
#       ['when', @timestamp.strftime("%Y-%m-%dT%H:%M:%S")]]
       ['when', @timestamp.strftime("%Y-%m-%dT%H:%M:%S+09:00")]]
    end

    ##--------------------------------------------------
    def to_Axml_description(cdatap = true)
      val = (cdatap ? 
             REXML::CData.new(@description.to_s) :
             @description) ;
      return ['description', val] ;
    end

    ##--------------------------------------------------
    def to_Axml_lookAt()
      return  nil ;  ## not implemented
    end
    
    ##--------------------------------------------------
    def to_Axml_style()
      if(@style.is_a?(String)) ## suppose style reference
        return ['styleUrl', @style]
      elsif(@style.is_a?(Style))
        return @style.to_Axml() ;
      else
        raise "unknown style spec.:" + @style.to_s ;
      end
    end
    
    ##--------------------------------------------------
    def to_Axml_geometry()
      raise "to_Axml_geometry() is undefined for this class" + self.class.name;
    end
    
    ##--------------------------------------------------
    def to_Axml_coordinates()
      if(@coord.is_a?(Array))
        coordList = @coord.map{|pos| pos.to_coordinates()} ;
        coordListList = [] ;
        # return coordList.join(' ') ;
        while(coordList.length > 0)
          coordListList.push(coordList.slice!(0,10)) ;
        end
        return coordListList.map{|clist| clist.join(" ")} ;
      else
        return @coord.to_coordinates() ;
      end
    end

    ##--------------------------------------------------
    def coordinatesAxml(coords)
      if(coords.is_a?(Array))
        return ['coordinates',  *coords] ;
      else
        return ['coordinates',  coords] ;
      end
    end
    
  end ## class Placemark

  ##======================================================================
  class Point < Placemark
    ##::::::::::::::::::::::::::::::::::::::::::::::::::
    GeoType = 'Point' ;
    DefaultConf = { 
      :coord => [0, 0, 0],
    } ;

    ##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    
    ##--------------------------------------------------
    def initialize(name = nil, conf = {})
      super ;
      setCoord(getConf(:coord)) ;
    end

    ##--------------------------------------------------
    def setCoord(coord)
      if(coord.is_a?(LatLon))
        @coord = coord ;
      else
        @coord = LatLon.new(*coord) ;
      end
    end

    ##--------------------------------------------------
    def to_Axml_geometry()
      coords = to_Axml_coordinates() ;
      axml = [GeoType, coordinatesAxml(coords)] ;
      return axml ;
    end

  end ## class Point 

  ##======================================================================
  class LineString < Placemark
    ##::::::::::::::::::::::::::::::::::::::::::::::::::
    GeoType = 'LineString' ;
    DefaultConf = { 
      :coord => [[0, 0, 0],[1, 1, 0]],
    } ;

    ##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    
    ##--------------------------------------------------
    def initialize(name = nil, conf = {})
      super ;
      setCoord(getConf(:coord)) ;
    end

    ##--------------------------------------------------
    def setCoord(coordList)
      @coord = [] ;
      coordList.each{|coord|
        ll = (coord.is_a?(LatLon) ? coord : LatLon.new(*coord)) ;
        @coord.push(ll) ;
      }
      @coord ;
    end

    ##--------------------------------------------------
    def to_Axml_geometry()
      coords = to_Axml_coordinates() ;
      axml = [GeoType, coordinatesAxml(coords)] ;
      return axml ;
    end
  end

  ##======================================================================
  class Polygon < Placemark
    ##::::::::::::::::::::::::::::::::::::::::::::::::::
    GeoType = 'Polygon' ;
    DefaultConf = { 
      :coord => [[0, 0, 0],[1, 0, 0],[1, 1, 0],[0, 1, 0],[0, 0, 0]],
    } ;

    ##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    
    ##--------------------------------------------------
    def initialize(name = nil, conf = {})
      super ;
      polygon = getConf(:polygon) ;
      if(polygon)
        setCoordByGeoPolygon(polygon) ;
      else
        setCoord(getConf(:coord)) ;
      end
    end

    ##--------------------------------------------------
    def setCoord(coordList)
      if(coordList)
        @coord = [] ;
        coordList.each{|coord|
          ll = nil ;
          case(coord)
          when LatLon ; ll = coord ;
          when Geo2D::Vector ; ll = LatLon.new(coord) ;
          when Array ; ll = LatLon.new(*coord) ;
          else
            raise "unknown coord element type:" + coord.inspect ;
          end
                
          @coord.push(ll) ;
        }

        ## ÎØ¤òÊÄ¤¸¤ë
        closeCoord() ;
      
        return @coord ;
      else
        return nil ;
      end
    end

    ##--------------------------------------------------
    def setCoordByGeoPolygon(polygon)
      coordList = [] ;
      polygon.eachPoint{|point|
        coordList.push(point) ;
      }
      setCoord(coordList) ;
    end

    ##--------------------------------------------------
    def closeCoord()
      if(@coord && @coord.length > 0) 
        @coord.push(@coord.first) if(! @coord.first.equal(@coord.last)) ;
      end
    end


    ##--------------------------------------------------
    def to_Axml_geometry()
      coords = to_Axml_coordinates() ;
      axml = [GeoType,
              ['outerBoundaryIs',
               ['LinearRing', coordinatesAxml(coords)]]] ;
      return axml ;
    end

  end ## class Polygon

  ##======================================================================
  class Ellipse < Polygon
    ##::::::::::::::::::::::::::::::::::::::::::::::::::
    DefaultConf = {
      :coord => [],
      :center => [0.0, 0.0], ## [lat,lon]
      :radius => [1.0, 1.0], ## [km, km]
      :nPoints => 8,
    } ;

    ##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@

    ##--------------------------------------------------
    def initialize(name = nil, conf = {})
      super ;
      genEllipseShape()
    end

    ##--------------------------------------------------
    def genEllipseShape()
      @center = getConf(:center) ;
      @radius = getConf(:radius) ;
      @nPoints = getConf(:nPoints) ;

      centerLL = LatLon.new(*@center) ;
      radiusLL = centerLL.km2deg(*@radius) ;

      @coord = [] ;

      dTheta = 2.0 * Math::PI / @nPoints.to_f ;
      theta = 0.0 ;
      (0...@nPoints).each{|i|
        x = @center[0] + radiusLL[0] * Math::cos(theta) ;
        y = @center[1] + radiusLL[1] * Math::sin(theta) ;

        ll = LatLon.new(x,y) ;
        @coord.push(ll) ;

        theta += dTheta ;
      }

      closeCoord() ;
    end

  end ## class Ellipse

  ##======================================================================
  class Folder < WithConfParam
    ##::::::::::::::::::::::::::::::::::::::::::::::::::
    DefaultConf = { 
      :open => true,
      :style => nil,
    } ;
    ##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    attr :name, true ;
    attr :open, true ;

    attr :contents, true ;
    attr :styles, true ;
    
    ##--------------------------------------------------
    def initialize(name = nil, contents = [], conf = {})
      @name = name ;
      super(conf) ;

      @open = getConf(:open) ;

      @contents = [] ;
      pushContentList(contents) ;

      @styles = [] ;
      pushStyleList(getConf(:styles)) ;
    end

    ##--------------------------------------------------
    def pushContentList(contentList)
      contentList.each{|content|
        pushContent(content) ;
      }
    end

    ##--------------------------------------------------
    def pushContent(content)
      if(content.is_a?(Placemark))
        @contents.push(content) ;
      elsif(content.is_a?(Folder))
        @contents.push(content) ;
      elsif(content.is_a?(Array))  ## supose Folder
        folder = Folder.new(nil, content) ;
        @contents.push(folder) ;
      elsif(content.is_a?(Hash))   ## supose Placemark
        klass = content[:type] ;
        pmark = klass.new(content[:name], content) ;
        @contents.push(pmark) ;
      else
        raise "Unknown content type:" + content.to_s ;
      end
    end

    ##--------------------------------------------------
    def pushStyleList(styleList)
      if(!styleList.nil?)
        styleList.each{|style|
          pushStyle(style) ;
        }
      end
    end

    ##--------------------------------------------------
    def pushStyle(style)
      if(style.is_a?(Style))
        @styles.push(style) ;
      elsif(style.is_a?(StyleMap))
        @styles.push(style) ;
      elsif(style.is_a?(Hash))  ## suppose Style or StyleMap
        klass = style[:type] ;
        sty = klass.new(style[:id], style) ;
        @styles.push(sty)
      else
        raise "Unknown style type:" + style.to_s ;
      end
    end

    ##--------------------------------------------------
    def to_Axml()
      axml = ['Folder',
              ['name', @name],
              ['open', (@open ? 1 : 0)]] ;

      to_AxmlBody(axml) ;

      return axml ;
    end

    ##--------------------------------------------------
    def to_AxmlBody(axml)
      @styles.each{|style|
        axml.push(style.to_Axml) ;
      }

      @contents.each{|content|
        axml.push(content.to_Axml) ;
      }
      return axml ;
    end

  end ## class Folder

  ##======================================================================
  class Document < Folder
    ##::::::::::::::::::::::::::::::::::::::::::::::::::
    DefaultConf = { 
    } ;
    ##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    ##--------------------------------------------------
    def initialize(name = nil, contents = [], conf = {})
      super ;
    end

    ##--------------------------------------------------
    def to_Axml(wrapByKmlTag = true)
      axml = ['Document',
              ['name', @name]] ;
      to_AxmlBody(axml) ;
      
      if(wrapByKmlTag)
        axml = [[nil, 'kml',
                 { 'xmlns' => "http://www.opengis.net/kml/2.2",
                   'xmlns:gx' => "http://www.google.com/kml/ext/2.2",
                   'xmlns:kml' => "http://www.opengis.net/kml/2.2",
                   'xmlns:atom' => "http://www.w3.org/2005/Atom" }],
                axml] ;
      end

      return axml ;
    end

    ##--------------------------------------------------
    def to_kml()
      axml = to_Axml() ;
      return ItkXml::to_Xml(axml) ;
    end

    ##--------------------------------------------------
    def write(ostrm = $stdout)
      kml = to_kml() ;
      ostrm << '<?xml version="1.0" encoding="UTF-8"?>' << "\n" ;
      kml.write(ostrm,0) ;
      ostrm << "\n" ;
    end
  end ## class Document

end ## module ItkKml


########################################################################
########################################################################
########################################################################
if(__FILE__ == $0) then

  ##----------------------------------------------------------------------
  def methodName(offset = 0)
    if  /`(.*)'/.match(caller[offset]) ;
      return $1
    end
    nil
  end

  ##======================================================================
  class Test

    ##::::::::::::::::::::::::::::::::::::::::::::::::::
    SampleFile = (File::dirname($0) + 
                  "/../unkou.¿ÌºÒÃÏ°è±¿¹Ô¥Ç¡¼¥¿_20110311.euc.csv") ;

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
    def test_A()
      pmark = ItkKml::Placemark.new('foo') ;
      p pmark ;
      p pmark.to_Axml ;
    end

    ##--------------------------------------------------
    def test_B()
      pmark = ItkKml::Point.new('foo', {:coord => [35, 135]}) ;
      p pmark ;
      p pmark.to_Axml ;
      ItkXml::to_Xml(pmark.to_Axml).write($stdout,1) ;
      $stdout << "\n" ;
    end

    ##--------------------------------------------------
    def test_C()
      pmark = ItkKml::LineString.new('foo', {:coord => [[35, 135],
                                                        [35, 136],
                                                        [36, 136]]}) ;
      p pmark ;
      p pmark.to_Axml ;
      ItkXml::to_Xml(pmark.to_Axml).write($stdout,1) ;
      $stdout << "\n" ;
    end

    ##--------------------------------------------------
    def test_D()
      pmark = ItkKml::Polygon.new('foo', {:coord => [[35, 135],
                                                     [35, 136],
                                                     [36, 136]]}) ;
      p pmark ;
      p pmark.to_Axml ;
      ItkXml::to_Xml(pmark.to_Axml).write($stdout,1) ;
      $stdout << "\n" ;
    end

    ##--------------------------------------------------
    def test_E()
      style = ItkKml::Style::Icon.new({}) ;
      p style ;
      p style.to_Axml ;
      ItkXml::to_Xml(style.to_Axml).write($stdout,1) ;
      $stdout << "\n" ;
    end

    ##--------------------------------------------------
    def test_F()
      style = ItkKml::Style.new('foo', 
                                { :icon => true,
                                  :label => true,
                                  :line => true,
                                  :poly => true,
                                }) ;
      p style ;
      p style.to_Axml ;
      ItkXml::to_Xml(style.to_Axml).write($stdout,1) ;
      $stdout << "\n" ;
    end

    ##--------------------------------------------------
    def test_F2()
      style = ItkKml::Style.new(nil,
                                { :icon => true,
                                  :poly => { :color => '33ffff00' },
                                }) ;
      p style ;
      p style.to_Axml ;
      ItkXml::to_Xml(style.to_Axml).write($stdout,1) ;
      $stdout << "\n" ;
    end

    ##--------------------------------------------------
    def test_G()
      style = ItkKml::StyleMap.new(nil) ;
      p style ;
      p style.to_Axml ;
      ItkXml::to_Xml(style.to_Axml).write($stdout,1) ;
      $stdout << "\n" ;

      style = ItkKml::StyleMap.new('foo',
                                   { :normal => '#bar',
                                     :highlight => '#baz'}) ;
      p style ;
      p style.to_Axml ;
      ItkXml::to_Xml(style.to_Axml).write($stdout,1) ;
      $stdout << "\n" ;
    end

    ##--------------------------------------------------
    def test_H()
      pmarks = [ItkKml::Point.new('p1', {:coord => [35,135]}),
                ItkKml::LineString.new('l1',
                                       { :coord => [[35,135],
                                                    [36,136],
                                                    [36,135]] })] ;
      styles = [ItkKml::Style.new('foo', ({ :icon => true,
                                            :line => true,
                                            :poly => true,
                                            :label => true })),
                ItkKml::Style.new('bar', ({ :icon => true,
                                            :line => true,
                                            :poly => true,
                                            :label => true }))] ;

      folder = ItkKml::Folder.new('foo', pmarks, { :styles => styles }) ;

      p folder ;
      p folder.to_Axml ;
      ItkXml::to_Xml(folder.to_Axml).write($stdout,1) ;
      $stdout << "\n" ;
    end

    ##--------------------------------------------------
    def test_J()
      pmarks = [ItkKml::Point.new('p1', {:coord => [35,135]}),
                ItkKml::LineString.new('l1',
                                       { :coord => [[35,135],
                                                    [36,136],
                                                    [36,135]] })] ;
      styles = [ItkKml::Style.new('foo', ({ :icon => true,
                                            :line => true,
                                            :poly => true,
                                            :label => true })),
                ItkKml::Style.new('bar', ({ :icon => true,
                                            :line => true,
                                            :poly => true,
                                            :label => true }))] ;

      folder = ItkKml::Folder.new('foo', pmarks, { :styles => styles }) ;

      kdoc = ItkKml::Document.new('foobarbaz', [folder]) ;

#      p kdoc ;
#      p kdoc.to_Axml ;
      kdoc.write($stdout) ;
    end

  end

  ##################################################
  ##################################################
  ##################################################

  myTest = Test.new() ;

  p ARGV ;
  testList = (ARGV.length > 0 ? ARGV : myTest.listTest()) ;

  testList.each{|testMethod|
    puts '-' * 50
    p [:try, testMethod] ;
    myTest.send(testMethod) ;
  }
  
end
