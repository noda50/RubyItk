## -*- Mode:Ruby -*-
##= Generic Canvas Utility
# Author:: Itsuki Noda
# Type:: class definition
# Date:: 2004/12/01
# === Note:
# * should be included before "test/unit".
#
# === Usage:
# * create canvas
#	canvas = MyCanvas.new('gtk',  # or 'tgif'
#			{ 'width'	=> 512,
#			  'height'	=> 512,
#			  'scale'	=> 100,
#			  'centerp'	=> true,
#			  'filename'	=> "foo.obj",	# used in tgif
#			  '' 		=> nil}) ;
#
# * single page
#	canvas.singlePage(bgcolor) {
#	  # draw operations
#	}
#
# * multi page 
#	canvas.multiPage() {
#	  canvas.page(bgcolor) { # draw opereations }
#	  canvas.page(bgcolor) { # draw opereations }
#	  ...
#	}
#
# * animation
#	canvas.animation(true,interval=0,bgcolor="white") {|i|
#	  # draw operations
#	}
#	-OR-
#	canvas.animation(10,interval=0,bgcolor="white") {|i|
#	  # draw operations
#	}
#	-OR-
#	canvas.animation((0...10),interval=0,bgcolor="white") {|i|
#	  # draw operations
#	}
#
# * primitive form
#	canvas.run() ;
#	canvas.beginPage(bgcolor) ;
#	# draw operations
#	canvas.endPage() ;
#	# additional pages
#	canvas.finish() ;
#
# * draw primitives
#	drawDashedLine(x0,y0,x1,y1,thickness=1,color="grey") ;
#	drawSolidLine(x0,y0,x1,y1,thickness=1,color="black") ;
#
#	drawCircle(x,y,r,fillp,color="black")
#	drawEmptyCircle(x,y,r,color="black")
#	drawFilledCircle(x,y,r,color="black")
#	drawFramedCircle(x,y,r,framecolor="black",fillcolor="white")
#
#       drawEllipse(x,y,rx,ry,fillp=false,color="black")
#
#	drawRectangle(x,y,w,h,fillp,color="black")
#	drawEmptyRectangle(x,y,w,h,color="black")
#	drawFilledRectangle(x,y,w,h,color="black") 
#	drawFramedRectangle(x,y,w,h,framecolor="black",fillcolor="white")
#	drawEmptyRectangleAbs(x0,y0,x1,y1,color="black")
#	drawFilledRectangleAbs(x0,y0,x1,y1,color="black") 
#	drawFramedRectangleAbs(x0,y0,x1,y1,framecolor="black",fillcolor="white")
#
#	drawPolygon([[x0,y0],[x1,y1],...],fillp, color="black")
#	drawEmptyPolygon([[x0,y0],[x1,y1],...], color="black")
#	drawFilledPolygon([[x0,y0],[x1,y1],...], color="black")
#	drawFramedPolygon([[x0,y0],[x1,y1],...], framecolor="black",fillcolor="white")
#       drawText(x,y,text,fontSize = 14, fontFamily = :times, color = "black") 
#

$LOAD_PATH.push(File::dirname(__FILE__)) ;

require "myCanvasDevBase.rb" ;
require "myCanvasTgif.rb" ;
require "myCanvasGtk.rb" ;
## require "myCanvasGtk2.rb" ;
## require "myCanvasTk.rb" ;


#--======================================================================
#++
## top level facility of Canvas.
class MyCanvas < MyCanvasDevBase

  #--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  #++
  ## device to handle MyCanvas. 
  ## should be one of MyCanvasGtk, Gtk2, Tgif, and Tk.
  attr :device, true ;

  #--------------------------------------------------------------
  #++
  # setSize by param table
  def initialize(devtype,param)
    setupDevice(devtype,param) ;
  end

  #--------------------------------------------------------------
  #++
  # setSize by param table
  def setupDevice(devtype,param) 
    case devtype
    when 'gtk', :gtk
      @device = MyCanvasGtk.new(param) ;
##    when 'gtk2'
##      @device = MyCanvasGtk2.new(param) ;
    when 'tgif', :tgif
      @device = MyCanvasTgif.new(param) ;
    when 'tk', :tk
      @device = MyCanvasTk.new(param) ;
    else
      $stderr.printf("Error:unknown device type : %s\n",devtype.to_s) ;
      fail ;
    end
  end

  #--------------------------------------------------------------
  #++
  # set size by param table
  def setSizeByParam(param) 
    @device.setSizeByParam(param) ;
  end

  #--------------------------------------------------------------
  #++
  # set XY size.
  def setSize(szX,szY,scale,centerp=FALSE)
    @device.setSize(szX,szY,scale,centerp) ;
  end

  #--------------------------------------------------------------
  #++
  # set shift size
  def setShift(sx,sy) 
    @device.setShift(sx,sy) 
  end

  #--------------------------------------------------------------
  #++
  # set scale
  def setScale(scale)
    @device.setScale(scale)
  end

  #--------------------------------------------------------------
  #++
  # set scale and shift parameter by boundary box
  def setScaleShiftByBoundaryBox(x0,y0,x1,y1)
    @device.setScaleShiftByBoundaryBox(x0,y0,x1,y1) ;
  end

  #--------------------------------------------------------------
  #++
  # size of X axis
  def sizeX()
    return @device.sizeX() ;
  end

  #--------------------------------------------------------------
  #++
  # size of Y axis
  def sizeY()
    return @device.sizeY() ;
  end

  #--------------------------------------------------------------
  #++
  # get scale of X axis
  def getScaleX()
    return @device.getScaleX() ;
  end

  #--------------------------------------------------------------
  #++
  # get scale of Y axis
  def getScaleY()
    return @device.getScaleY() ;
  end

  #--------------------------------------------------------------
  #++
  # get original X position
  def orgX(x)
    return @device.orgX(x) ;
  end

  #--------------------------------------------------------------
  #++
  # get original Y position
  def orgY(y)
    return @device.orgY(y) ;
  end

  #--------------------------------------------------------------
  #++
  # reverse get original X position
  def unscaleX(x)
    return @device.unscaleX(x) ;
  end

  #--------------------------------------------------------------
  #++
  # reverse get original Y position
  def unscaleY(y)
    return @device.unscaleY(y) ;
  end

  
  #--------------------------------------------------------------
  # :category: Top Level
  #++
  # run device.
  # [!!! should be defined in subclass!!!] 
  def run()
    @device.run() ;
  end

  #--------------------------------------------------------------
  # :category: Top Level
  #++
  # check run or not.
  # [!!! should be defined in subclass!!!] 
  def runP()
    @device.runP() ;
  end

  #--------------------------------------------------------------
  # :category: Top Level
  #++
  # finish device
  def finish()
    @device.finish() ;
  end

  #--------------------------------------------------------------
  # :category: Top Level
  #++
  # wait Quit() of device
  def waitQuit()
    @device.waitQuit() ;
  end

  #--------------------------------------------------------------
  # :category: Top Level
  #++
  # noExitWhenQuit()
  def noExitWhenQuit(flag = true)
    @device.noExitWhenQuit(flag) ;
  end

  #--------------------------------------------------------------
  # :category: Top Level
  #++
  # flush device
  def flush()
    @device.flush() ;
  end

  #--------------------------------------------------------------
  # :category: Top Level
  #++
  # begin a page 
  # [!!! should be defined in subclass!!!] 
  def beginPage(color="white") 
    @device.beginPage(color) ;
  end

  #--------------------------------------------------------------
  # :category: Top Level
  #++
  # end a page 
  # [!!! should be defined in subclass!!!] 
  def endPage()
    @device.endPage() ;
  end

  #--------------------------------------------------------------
  # :category: draw facility
  #++
  # draw dashed line.
  # [!!! should be defined in subclass!!!] 
  def drawDashedLine(x0,y0,x1,y1,thickness=1,color="grey") ;
    @device.drawDashedLine(x0,y0,x1,y1,thickness,color) ;
  end

  #--------------------------------------------------------------
  # :category: draw facility
  #++
  # draw solid line
  # [!!! should be defined in subclass!!!] 
  def drawSolidLine(x0,y0,x1,y1,thickness=1,color="black") ;
    @device.drawSolidLine(x0,y0,x1,y1,thickness,color) ;
  end

  #--------------------------------------------------------------
  # :category: draw facility
  #++
  # draw circle body
  # [!!! should be defined in subclass!!!] 
  def drawCircle(x,y,r,fillp=false,color="black")
    @device.drawCircle(x,y,r,fillp,color) ;
  end

  #--------------------------------------------------------------
  # :category: draw facility
  #++
  # draw circle body 
  # [!!! should be defined in subclass!!!] 
  def drawEllipse(x,y,rx,ry,fillp=false,color="black")
    @device.drawEllipse(x,y,rx,ry,fillp,color) ;
  end

  #--------------------------------------------------------------
  # :category: draw facility
  #++
  # draw rectangle body.
  # [!!! should be defined in subclass!!!] 
  def drawRectangle(x,y,w,h,fillp=false,color="black")
    @device.drawRectangle(x,y,w,h,fillp,color) ;
  end

  #--------------------------------------------------------------
  # :category: draw facility
  #++
  # draw polygon body.
  # [!!! should be defined in subclass!!!] 
  def drawPolygon(pointList, fillp=false, color="black")
    @device.drawPolygon(pointList, fillp, color) ;
  end

  #--------------------------------------------------------------
  # :category: draw facility
  #++
  # draw text
  def drawText(x,y,text,fontSize = 14, fontFamily = :times, color = "black") 
    @device.drawText(x,y,text,fontSize, fontFamily, color) ;
  end

  #--------------------------------------------------------------
  # :category: draw facility
  #++
  # draw image
  def drawImage(xdest, ydest, src, 
                xsrc = 0, ysrc = 0, width = -1, height = -1)
    @device.drawImage(xdest,ydest,src, xsrc, ysrc, width, height) ;
  end

  #--------------------------------------------------------------
  # :category: draw facility
  #++
  # get image from file
  def getImageFromFile(file)
    @device.getImageFromFile(file) ;
  end

  #--------------------------------------------------------------
  # :category: draw facility
  #++
  # clear page
  def clearPage(color="white")
    return @device.clearPage(color) ;
  end

  #--------------------------------------------------------------
  # :category: misc
  #++
  # add status info
  def addStatusInfoEntry(name, value = "")
    @device.addStatusInfoEntry(name,value) ;
  end

  #--------------------------------------------------------------
  # :category: misc
  #++
  # set status info
  def setStatusInfo(name, value)
    @device.setStatusInfo(name,value) ;
  end

  #--------------------------------------------------------------
  # :category: misc
  #++
  # thermal color scale
  def getThermalColor(level, s = 0.8, v = 1.0) # level should be in [0.0,1.0]
    h = ((1.0 - level) ** 1.4) *0.67;
    rgb = hsv2rgb(h,s,v) ;

    name = ('#%02x%02x%02x' % [(rgb[0] * 255).to_i,
                               (rgb[1] * 255).to_i,
                               (rgb[2] * 255).to_i]) ;

    return name ;
  end

  #--------------------------------------------------------------
  # :category: misc
  #++
  # saturation color scale
  def getSaturationColor(level, h = 0.0, v = 1.0) # level should be in [-1.0,1.0]
    s = (level > 0.0 ? level : -level) ;
    h = (level > 0.0 ? h : h+0.5) ;
    h += 1.0 while (h < 0.0) ;
    h -= 1.0 while (h > 1.0) ;
    rgb = hsv2rgb(h,s,v) ;

    name = ('#%02x%02x%02x' % [(rgb[0] * 255).to_i,
                               (rgb[1] * 255).to_i,
                               (rgb[2] * 255).to_i]) ;

    return name ;
  end

  #--------------------------------------------------------------
  # :category: misc
  #++
  # HSV to RGB
  def hsv2rgb(h,s,v) # h in [0,1], s in [0,1], v in [0,1]
    r = g = b = 0.0 ;

    if(s == 0.0) then
      r = g = b = v ;
    else
      hv = 360 * h ;
      hi = ((hv / 60).to_i) % 6 ;
      f = (hv/60) - hi ;
      p = v * (1 - s) ;
      q = v * (1 - f * s) ;
      t = v * (1 - (1 - f) * s) ;
      case(hi)
      when 0 ; r = v ; g = t ; b = p ;
      when 1 ; r = q ; g = v ; b = p ;
      when 2 ; r = p ; g = v ; b = t ;
      when 3 ; r = p ; g = q ; b = v ;
      when 4 ; r = t ; g = p ; b = v ;
      when 5 ; r = v ; g = p ; b = q ;
      else ; raise "HSV value is out of range : H=#{h}, S=#{s}, V=#{v}" ;
      end
    end
    return [r,g,b] ;
  end

end
