#! /usr/bin/env ruby
## -*- Mode:Ruby -*-
##Header:
##Title: Canvas Utility using Tgif
##Author: Itsuki Noda
##Type: class definition
##Date: 2004/12/01
##EndHeader:

require 'tempfile' ;

class MyCanvasTgif < MyCanvasDevBase

  attr :strm, true ;
#  attr :workstrm, true ;

  attr :openpagep, true ;
  attr :pageN, true ;
  attr :totalpage, true ;

  attr :openfilep, true ;

  ##----------------------------------------------------------------------
  ## setup
  ##

  def initialize(param = {})
    super(param) ;

    setStreamByParam(param) ;
    @pageN = 0 ;
    @openpagep = FALSE ;
    @totalpage = 0 ;
    @openfilep = FALSE ;
#    @workstrm = Tempfile::new("myCanvasTgif") ;
    @workbuf = [] ;
  end

  ##--------------------
  ## default size	(A4 size)

  def dfltSizeX()
    return 1050 ;
  end

  def dfltSizeY()
    return 1480 ;
  end


  ##--------------------
  ## set stream by Param

  def setStreamByParam(param)
    strm = $stdout ;

    if(param.key?('stream'))
      strm = param['stream'] ;
    elsif(param.key?('filename'))
      strm = File::open(param['filename'],"w") ;
      openfilep = TRUE ;
    end

    setStream(strm) ;
  end

  ##--------------------
  ## set stream

  def setStream(strm=$stdout)
    @strm = strm ;
  end

  ##----------------------------------------------------------------------
  ## toplevel : common interface with myGtkCanvas and tgif
  ##

  ##----------------------------------------
  ## run()

  def run()
    # do nothing
  end

  ##----------------------------------------
  ## finish()

  def finish() 
    docHeader(@strm,@totalpage) ;

    pageN = 0 ;
    @workbuf.each { |b| 
      pageN += 1 ;
      pageHeader(@strm,pageN) ;
      @strm << b ; 
      pageTailer(@strm) ;
    }

    docTailer(@strm) ;

    @strm.close() if(@openfilep) ;
  end

  ##----------------------------------------
  ## flush
  ##

  def flush()
    # do nothing
  end

  ##----------------------------------------
  ## begin/end Page

  def beginPage(color="white")
    newbuf = String.new("") ;
    needheaderp = TRUE ;

    if(color.nil? && @totalpage > 0)
      newbuf = String.new(@workbuf[@totalpage-1]) ;
      needheaderp = FALSE ;
    end

    @totalpage += 1 ;
    @workbuf[@totalpage-1] = newbuf ;

    clearPage(color) if(!color.nil?)
  end

  def endPage() 
    flush() ;
  end

  ##----------------------------------------
  ## clear Page

  def clearPage(color="white")  #currently, ignore color ;
    @workbuf[@totalpage-1] = "" ;
  end

  ##----------------------------------------------------------------------
  ## doc/pageHeader
  ##

  def docHeader (strm,totalpage=1,currentpage=1)
    strm.printf(@@docHeaderForm,currentpage,totalpage) ;
  end
  
  def docTailer (strm)
   strm.print(@@docTailerForm) ;
  end

  def pageHeader (strm,pageN)
    strm.printf(@@pageHeaderForm,pageN) ;
  end

  def pageTailer (strm)
    strm.print(@@pageTailerForm) ;
  end

  ##----------------------------------------------------------------------
  ## draw objects
  ##

  ##----------------------------------------
  ## add object to current Page

  def addToPage(str)
    @workbuf[@totalpage-1] << str ;
  end

  ##------------------------------
  ## draw line
  ##

  def drawLine(x0,y0,x1,y1,thickness = 1,color = "black",linetype=0)

    #linetype = 0 .. 8
    #	0 : solid
    #   8 : fine dashed

    p0 = 6 + thickness * 2 ;
    p1 = 2 + thickness ;
    addToPage(sprintf(@@lineForm,color,valX(x0),valY(y0),valX(x1),valY(y1),
		      thickness,linetype,thickness,p0,p1,p0,p1,p0,p1,p0,p1)) ;
  end

  def drawSolidLine(x0,y0,x1,y1,thickness = 1,color = "black")
    drawLine(x0,y0,x1,y1,thickness,color,0) ;
  end

  def drawDashedLine(x0,y0,x1,y1,thickness = 1,color = "black")
    drawLine(x0,y0,x1,y1,thickness,color,8) ;	
  end

  ##------------------------------
  ## draw ellipse (circle)
  ##

  def drawEllipse(x,y,rx,ry,filledp=TRUE,color="black")
    if(filledp) then
      p0 = 1 ;
    else
      p0 = 0 ;
    end

    addToPage(sprintf(@@circleForm,color,
		      valX(x-rx),valY(y-ry),valX(x+rx),valY(y+ry),
		      p0,p0)) ;
  end

  ##------------------------------
  ## draw rectangle
  ##
  
  def drawRectangle(x,y,w,h,filledp,color="black")
    if(filledp) then
      p0 = 1 ;
    else
      p0 = 0 ;
    end

    addToPage(sprintf(@@rectangleForm,color,
		      valX(x),valY(y),valX(x+w),valY(y+h),
		      p0,p0)) ;
  end

  ##------------------------------
  ## draw text
  ##
  
  def drawText(x,y,text,fontSize = 14, fontFamily = :times, color = "black")
    fontTable = {:times => "Times-Roman"} ;
    font = fontTable[fontFamily] ;

    p([valX(x), valY(y)]) ;

    addToPage(sprintf(@@textForm,
                      color, valX(x), valY(y), valY(y),
                      color, font, fontSize, 
                      text)) ;
  end


##----------------------------------------------------------------------
## set tgif forms
##

##------------------------------
## doc header/tailer

  @@docHeaderForm = <<'__END__' ;
%%TGIF 4.1.41-QPL
state(0,37,100.000,0,0,0,16,1,0,1,1,0,0,0,1,1,0,'Ryumin-Light-EUC-H',0,63360,0,8,1,10,0,0,1,1,0,16,0,0,%d,%d,1,1,1050,1485,1,0,2880,0).
%%
%% @(#)$Header$
%% %%W%%
%%
unit("1 pixel/pixel").
color_info(212,65535,0,[
	"black", 0, 0, 0, 0, 0, 0, 1,
	"white", 65535, 65535, 65535, 65535, 65535, 65535, 1,
	"blue", 0, 0, 49344, 0, 0, 49152, 1,
	"yellow", 65535, 65535, 0, 65535, 65535, 0, 1,
	"khaki", 33410, 33410, 0, 33287, 33287, 0, 1,
	"red", 65535, 0, 0, 65535, 0, 0, 1,
	"green", 15420, 64507, 13364, 15603, 64494, 13522, 1,
	"green2", 15420, 64507, 13364, 15603, 64493, 13523, 1,
	"orange", 65535, 42662, 0, 65535, 42649, 0, 1,
	"magenda", 65535, 0, 65535, 65535, 0, 65534, 1,
	"#000000", 0, 0, 0, 0, 0, 0, 1,
	"#0e0e0e", 3598, 3598, 3598, 3584, 3584, 3584, 1,
	"#1c1c1c", 7196, 7196, 7196, 7168, 7168, 7168, 1,
	"#2a2a2a", 10794, 10794, 10794, 10752, 10752, 10752, 1,
	"#383838", 14392, 14392, 14392, 14336, 14336, 14336, 1,
	"#464646", 17990, 17990, 17990, 17920, 17920, 17920, 1,
	"#545454", 21588, 21588, 21588, 21504, 21504, 21504, 1,
	"#626262", 25186, 25186, 25186, 25088, 25088, 25088, 1,
	"#707070", 28784, 28784, 28784, 28672, 28672, 28672, 1,
	"#7e7e7e", 32382, 32382, 32382, 32256, 32256, 32256, 1,
	"#8c8c8c", 35980, 35980, 35980, 35840, 35840, 35840, 1,
	"#9a9a9a", 39578, 39578, 39578, 39424, 39424, 39424, 1,
	"#a8a8a8", 43176, 43176, 43176, 43008, 43008, 43008, 1,
	"#b6b6b6", 46774, 46774, 46774, 46592, 46592, 46592, 1,
	"#c4c4c4", 50372, 50372, 50372, 50176, 50176, 50176, 1,
	"#d2d2d2", 53970, 53970, 53970, 53760, 53760, 53760, 1,
	"#e0e0e0", 57568, 57568, 57568, 57344, 57344, 57344, 1,
	"#eeeeee", 61166, 61166, 61166, 60928, 60928, 60928, 1,
	"#fcfcfc", 64764, 64764, 64764, 64512, 64512, 64512, 1,
	"#ffffff", 65535, 65535, 65535, 65280, 65280, 65280, 1,
	"#190000", 6425, 0, 0, 6400, 0, 0, 1,
	"#4c0000", 19532, 0, 0, 19456, 0, 0, 1,
	"#7f0000", 32639, 0, 0, 32512, 0, 0, 1,
	"#b20000", 45746, 0, 0, 45568, 0, 0, 1,
	"#e50000", 58853, 0, 0, 58624, 0, 0, 1,
	"#ff1c1c", 65535, 7196, 7196, 65280, 7168, 7168, 1,
	"#ff3838", 65535, 14392, 14392, 65280, 14336, 14336, 1,
	"#ff5454", 65535, 21588, 21588, 65280, 21504, 21504, 1,
	"#ff7070", 65535, 28784, 28784, 65280, 28672, 28672, 1,
	"#ff8c8c", 65535, 35980, 35980, 65280, 35840, 35840, 1,
	"#190800", 6425, 2056, 0, 6400, 2048, 0, 1,
	"#4c1900", 19532, 6425, 0, 19456, 6400, 0, 1,
	"#7f2a00", 32639, 10794, 0, 32512, 10752, 0, 1,
	"#b23b00", 45746, 15163, 0, 45568, 15104, 0, 1,
	"#e54c00", 58853, 19532, 0, 58624, 19456, 0, 1,
	"#ff701c", 65535, 28784, 7196, 65280, 28672, 7168, 1,
	"#ff8238", 65535, 33410, 14392, 65280, 33280, 14336, 1,
	"#ff9554", 65535, 38293, 21588, 65280, 38144, 21504, 1,
	"#ffa870", 65535, 43176, 28784, 65280, 43008, 28672, 1,
	"#ffba8c", 65535, 47802, 35980, 65280, 47616, 35840, 1,
	"#191100", 6425, 4369, 0, 6400, 4352, 0, 1,
	"#4c3300", 19532, 13107, 0, 19456, 13056, 0, 1,
	"#7f5500", 32639, 21845, 0, 32512, 21760, 0, 1,
	"#b27600", 45746, 30326, 0, 45568, 30208, 0, 1,
	"#e59800", 58853, 39064, 0, 58624, 38912, 0, 1,
	"#ffc41c", 65535, 50372, 7196, 65280, 50176, 7168, 1,
	"#ffcd38", 65535, 52685, 14392, 65280, 52480, 14336, 1,
	"#ffd754", 65535, 55255, 21588, 65280, 55040, 21504, 1,
	"#ffe070", 65535, 57568, 28784, 65280, 57344, 28672, 1,
	"#ffe98c", 65535, 59881, 35980, 65280, 59648, 35840, 1,
	"#191900", 6425, 6425, 0, 6400, 6400, 0, 1,
	"#4c4c00", 19532, 19532, 0, 19456, 19456, 0, 1,
	"#7f7f00", 32639, 32639, 0, 32512, 32512, 0, 1,
	"#b2b200", 45746, 45746, 0, 45568, 45568, 0, 1,
	"#e5e500", 58853, 58853, 0, 58624, 58624, 0, 1,
	"#ffff1c", 65535, 65535, 7196, 65280, 65280, 7168, 1,
	"#ffff38", 65535, 65535, 14392, 65280, 65280, 14336, 1,
	"#ffff54", 65535, 65535, 21588, 65280, 65280, 21504, 1,
	"#ffff70", 65535, 65535, 28784, 65280, 65280, 28672, 1,
	"#ffff8c", 65535, 65535, 35980, 65280, 65280, 35840, 1,
	"#111900", 4369, 6425, 0, 4352, 6400, 0, 1,
	"#334c00", 13107, 19532, 0, 13056, 19456, 0, 1,
	"#557f00", 21845, 32639, 0, 21760, 32512, 0, 1,
	"#77b200", 30583, 45746, 0, 30464, 45568, 0, 1,
	"#99e500", 39321, 58853, 0, 39168, 58624, 0, 1,
	"#c4ff1c", 50372, 65535, 7196, 50176, 65280, 7168, 1,
	"#cdff38", 52685, 65535, 14392, 52480, 65280, 14336, 1,
	"#d7ff54", 55255, 65535, 21588, 55040, 65280, 21504, 1,
	"#e0ff70", 57568, 65535, 28784, 57344, 65280, 28672, 1,
	"#e9ff8c", 59881, 65535, 35980, 59648, 65280, 35840, 1,
	"#081900", 2056, 6425, 0, 2048, 6400, 0, 1,
	"#194c00", 6425, 19532, 0, 6400, 19456, 0, 1,
	"#2a7f00", 10794, 32639, 0, 10752, 32512, 0, 1,
	"#3bb200", 15163, 45746, 0, 15104, 45568, 0, 1,
	"#4ce500", 19532, 58853, 0, 19456, 58624, 0, 1,
	"#70ff1c", 28784, 65535, 7196, 28672, 65280, 7168, 1,
	"#82ff38", 33410, 65535, 14392, 33280, 65280, 14336, 1,
	"#95ff54", 38293, 65535, 21588, 38144, 65280, 21504, 1,
	"#a8ff70", 43176, 65535, 28784, 43008, 65280, 28672, 1,
	"#baff8c", 47802, 65535, 35980, 47616, 65280, 35840, 1,
	"#001900", 0, 6425, 0, 0, 6400, 0, 1,
	"#004c00", 0, 19532, 0, 0, 19456, 0, 1,
	"#007f00", 0, 32639, 0, 0, 32512, 0, 1,
	"#00b200", 0, 45746, 0, 0, 45568, 0, 1,
	"#00e500", 0, 58853, 0, 0, 58624, 0, 1,
	"#1cff1c", 7196, 65535, 7196, 7168, 65280, 7168, 1,
	"#38ff38", 14392, 65535, 14392, 14336, 65280, 14336, 1,
	"#54ff54", 21588, 65535, 21588, 21504, 65280, 21504, 1,
	"#70ff70", 28784, 65535, 28784, 28672, 65280, 28672, 1,
	"#8cff8c", 35980, 65535, 35980, 35840, 65280, 35840, 1,
	"#001908", 0, 6425, 2056, 0, 6400, 2048, 1,
	"#004c19", 0, 19532, 6425, 0, 19456, 6400, 1,
	"#007f2a", 0, 32639, 10794, 0, 32512, 10752, 1,
	"#00b23b", 0, 45746, 15163, 0, 45568, 15104, 1,
	"#00e54c", 0, 58853, 19532, 0, 58624, 19456, 1,
	"#1cff70", 7196, 65535, 28784, 7168, 65280, 28672, 1,
	"#38ff82", 14392, 65535, 33410, 14336, 65280, 33280, 1,
	"#54ff95", 21588, 65535, 38293, 21504, 65280, 38144, 1,
	"#70ffa8", 28784, 65535, 43176, 28672, 65280, 43008, 1,
	"#8cffbb", 35980, 65535, 48059, 35840, 65280, 47872, 1,
	"#001910", 0, 6425, 4112, 0, 6400, 4096, 1,
	"#004c32", 0, 19532, 12850, 0, 19456, 12800, 1,
	"#007f54", 0, 32639, 21588, 0, 32512, 21504, 1,
	"#00b276", 0, 45746, 30326, 0, 45568, 30208, 1,
	"#00e598", 0, 58853, 39064, 0, 58624, 38912, 1,
	"#1cffc4", 7196, 65535, 50372, 7168, 65280, 50176, 1,
	"#38ffcd", 14392, 65535, 52685, 14336, 65280, 52480, 1,
	"#54ffd7", 21588, 65535, 55255, 21504, 65280, 55040, 1,
	"#70ffe0", 28784, 65535, 57568, 28672, 65280, 57344, 1,
	"#8cffe9", 35980, 65535, 59881, 35840, 65280, 59648, 1,
	"#001919", 0, 6425, 6425, 0, 6400, 6400, 1,
	"#004c4c", 0, 19532, 19532, 0, 19456, 19456, 1,
	"#007f7f", 0, 32639, 32639, 0, 32512, 32512, 1,
	"#00b2b2", 0, 45746, 45746, 0, 45568, 45568, 1,
	"#00e5e5", 0, 58853, 58853, 0, 58624, 58624, 1,
	"#1cffff", 7196, 65535, 65535, 7168, 65280, 65280, 1,
	"#38ffff", 14392, 65535, 65535, 14336, 65280, 65280, 1,
	"#54ffff", 21588, 65535, 65535, 21504, 65280, 65280, 1,
	"#70ffff", 28784, 65535, 65535, 28672, 65280, 65280, 1,
	"#8cffff", 35980, 65535, 65535, 35840, 65280, 65280, 1,
	"#001019", 0, 4112, 6425, 0, 4096, 6400, 1,
	"#00324c", 0, 12850, 19532, 0, 12800, 19456, 1,
	"#00547f", 0, 21588, 32639, 0, 21504, 32512, 1,
	"#0076b2", 0, 30326, 45746, 0, 30208, 45568, 1,
	"#0098e5", 0, 39064, 58853, 0, 38912, 58624, 1,
	"#1cc4ff", 7196, 50372, 65535, 7168, 50176, 65280, 1,
	"#38cdff", 14392, 52685, 65535, 14336, 52480, 65280, 1,
	"#54d7ff", 21588, 55255, 65535, 21504, 55040, 65280, 1,
	"#70e0ff", 28784, 57568, 65535, 28672, 57344, 65280, 1,
	"#8ce9ff", 35980, 59881, 65535, 35840, 59648, 65280, 1,
	"#000819", 0, 2056, 6425, 0, 2048, 6400, 1,
	"#00194c", 0, 6425, 19532, 0, 6400, 19456, 1,
	"#002a7f", 0, 10794, 32639, 0, 10752, 32512, 1,
	"#003bb2", 0, 15163, 45746, 0, 15104, 45568, 1,
	"#004ce5", 0, 19532, 58853, 0, 19456, 58624, 1,
	"#1c70ff", 7196, 28784, 65535, 7168, 28672, 65280, 1,
	"#3882ff", 14392, 33410, 65535, 14336, 33280, 65280, 1,
	"#5495ff", 21588, 38293, 65535, 21504, 38144, 65280, 1,
	"#70a8ff", 28784, 43176, 65535, 28672, 43008, 65280, 1,
	"#8cbbff", 35980, 48059, 65535, 35840, 47872, 65280, 1,
	"#000019", 0, 0, 6425, 0, 0, 6400, 1,
	"#00004c", 0, 0, 19532, 0, 0, 19456, 1,
	"#00007f", 0, 0, 32639, 0, 0, 32512, 1,
	"#0000b2", 0, 0, 45746, 0, 0, 45568, 1,
	"#0000e5", 0, 0, 58853, 0, 0, 58624, 1,
	"#1c1cff", 7196, 7196, 65535, 7168, 7168, 65280, 1,
	"#3838ff", 14392, 14392, 65535, 14336, 14336, 65280, 1,
	"#5454ff", 21588, 21588, 65535, 21504, 21504, 65280, 1,
	"#7070ff", 28784, 28784, 65535, 28672, 28672, 65280, 1,
	"#8c8cff", 35980, 35980, 65535, 35840, 35840, 65280, 1,
	"#080019", 2056, 0, 6425, 2048, 0, 6400, 1,
	"#19004c", 6425, 0, 19532, 6400, 0, 19456, 1,
	"#2a007f", 10794, 0, 32639, 10752, 0, 32512, 1,
	"#3b00b2", 15163, 0, 45746, 15104, 0, 45568, 1,
	"#4c00e5", 19532, 0, 58853, 19456, 0, 58624, 1,
	"#701cff", 28784, 7196, 65535, 28672, 7168, 65280, 1,
	"#8238ff", 33410, 14392, 65535, 33280, 14336, 65280, 1,
	"#9554ff", 38293, 21588, 65535, 38144, 21504, 65280, 1,
	"#a870ff", 43176, 28784, 65535, 43008, 28672, 65280, 1,
	"#ba8cff", 47802, 35980, 65535, 47616, 35840, 65280, 1,
	"#110019", 4369, 0, 6425, 4352, 0, 6400, 1,
	"#33004c", 13107, 0, 19532, 13056, 0, 19456, 1,
	"#55007f", 21845, 0, 32639, 21760, 0, 32512, 1,
	"#7700b2", 30583, 0, 45746, 30464, 0, 45568, 1,
	"#9900e5", 39321, 0, 58853, 39168, 0, 58624, 1,
	"#c41cff", 50372, 7196, 65535, 50176, 7168, 65280, 1,
	"#cd38ff", 52685, 14392, 65535, 52480, 14336, 65280, 1,
	"#d754ff", 55255, 21588, 65535, 55040, 21504, 65280, 1,
	"#e070ff", 57568, 28784, 65535, 57344, 28672, 65280, 1,
	"#e98cff", 59881, 35980, 65535, 59648, 35840, 65280, 1,
	"#190019", 6425, 0, 6425, 6400, 0, 6400, 1,
	"#4c004c", 19532, 0, 19532, 19456, 0, 19456, 1,
	"#7f007f", 32639, 0, 32639, 32512, 0, 32512, 1,
	"#b200b2", 45746, 0, 45746, 45568, 0, 45568, 1,
	"#e500e5", 58853, 0, 58853, 58624, 0, 58624, 1,
	"#ff1cff", 65535, 7196, 65535, 65280, 7168, 65280, 1,
	"#ff38ff", 65535, 14392, 65535, 65280, 14336, 65280, 1,
	"#ff54ff", 65535, 21588, 65535, 65280, 21504, 65280, 1,
	"#ff70ff", 65535, 28784, 65535, 65280, 28672, 65280, 1,
	"#ff8cff", 65535, 35980, 65535, 65280, 35840, 65280, 1,
	"#190011", 6425, 0, 4369, 6400, 0, 4352, 1,
	"#4c0033", 19532, 0, 13107, 19456, 0, 13056, 1,
	"#7f0055", 32639, 0, 21845, 32512, 0, 21760, 1,
	"#b20077", 45746, 0, 30583, 45568, 0, 30464, 1,
	"#e50099", 58853, 0, 39321, 58624, 0, 39168, 1,
	"#ff1cc4", 65535, 7196, 50372, 65280, 7168, 50176, 1,
	"#ff38cd", 65535, 14392, 52685, 65280, 14336, 52480, 1,
	"#ff54d7", 65535, 21588, 55255, 65280, 21504, 55040, 1,
	"#ff70e0", 65535, 28784, 57568, 65280, 28672, 57344, 1,
	"#ff8ce9", 65535, 35980, 59881, 65280, 35840, 59648, 1,
	"#190008", 6425, 0, 2056, 6400, 0, 2048, 1,
	"#4c0019", 19532, 0, 6425, 19456, 0, 6400, 1,
	"#7f002a", 32639, 0, 10794, 32512, 0, 10752, 1,
	"#b2003b", 45746, 0, 15163, 45568, 0, 15104, 1,
	"#e5004c", 58853, 0, 19532, 58624, 0, 19456, 1,
	"#ff1c70", 65535, 7196, 28784, 65280, 7168, 28672, 1,
	"#ff3882", 65535, 14392, 33410, 65280, 14336, 33280, 1,
	"#ff5495", 65535, 21588, 38293, 65280, 21504, 38144, 1,
	"#ff70a8", 65535, 28784, 43176, 65280, 28672, 43008, 1,
	"#ff8cba", 65535, 35980, 47802, 65280, 35840, 47616, 1,
	"magenda2", 65535, 0, 65535, 65534, 0, 65534, 1,
	"red2", 65535, 0, 0, 65534, 0, 0, 1
]).
script_frac("0.6").
fg_bg_colors('#000000','white').
dont_reencode("FFDingbests:ZapfDingbats").
__END__

  @@docTailerForm = <<'__END__' ;
__END__

##------------------------------
## page header/tailer

  @@pageHeaderForm = <<'__END__' ;
page(%d,"",1,'').
__END__

  @@pageTailerForm = <<'__END__' ;
__END__


##------------------------------
## fill/empty oval form

  @@circleForm = <<'__END__' ;
oval('%s','',%d,%d,%d,%d,%d,1,1,%d,0,0,0,0,0,'1',0,[
]).
__END__

##------------------------------
## line form

  @@lineForm = <<'__END__' ;
poly('%s','',2,[
	%d,%d,%d,%d],0,%d,1,4,0,1,%d,0,0,0,0,'%d',0,0,
    "0","",[
    0,%d,%d,0,'%d','%d','0'],[0,%d,%d,0,'%d','%d','0'],[
]).
__END__

##------------------------------
## rectangle form
# box('#000000','',100,50,150,100,0,1,1,0,0,0,0,0,0,'1',0,[
# ]).
# box('#000000','',100,150,150,200,1,1,1,1,0,0,0,0,0,'1',0,[
# ]).
# sample: box('<COLOR>','',<X0>,<Y0>,<X1>,<Y1>,<FILLP>,1,1,<FILLP>,0,0,0,0,0,'1',0,[
# ]).

  @@rectangleForm = <<'__END__' ;
box('%s','',%d,%d,%d,%d,%d,1,1,%d,0,0,0,0,0,'1',0,[
]).
__END__

##------------------------------
## text form
# text('black',50,46,1,0,1,74,17,0,14,3,0,0,0,0,2,74,17,0,0,"",0,0,0,0,60,'',[
# minilines(74,17,0,0,0,0,0,[
# mini_line(74,14,3,0,0,0,[
# str_block(0,74,14,3,0,-1,0,0,0,[
# str_seg('black','Times-Roman',0,80640,74,14,3,0,-1,0,0,0,0,0,
# 	"This is a pen.")])
# ])
# ])]).
# sample: text('<COLOR>',<X>,<Y>,1,0,1,<W>,<H>,0,<FSize>,3,0,0,0,0,2,74,17,0,0,"",0,0,0,0,<Y+FSize>,'',[
# minilines(<W>,<H>,0,0,0,0,0,[
# mini_line(<W>,<FSize>,3,0,0,0,[
# str_block(0,<W>,<FSize>,3,0,-1,0,0,0,[
# str_seg('<COLOR>','<FontFamily>',0,80640,<W>,<FSize>,3,0,-1,0,0,0,0,0,
# 	"<TEXT>")])
# ])
# ])]).


  @@textForm = <<'__END__' ;
text('%s',%d,%d,1,0,1,74,17,0,14,3,0,0,0,0,2,74,17,0,0,"",0,0,0,0,%d,'',[
minilines(74,17,0,0,0,0,0,[
mini_line(74,14,3,0,0,0,[
str_block(0,74,14,3,0,-1,0,0,0,[
str_seg('%s','%s',0,80640,74,%d,3,0,-1,0,0,0,0,0,
	"%s")])
])
])]).
__END__



end



