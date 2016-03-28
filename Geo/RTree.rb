#! /usr/bin/env ruby
## -*- mode: ruby -*-
## = RTree implement by pure Ruby
## Author:: Itsuki Noda
## Version:: 0.0 2016/03/20 I.Noda
##
## === History
## * [2016/03/20]: Create This File.
## * [YYYY/MM/DD]: add more
## == Usage
## * ...

$LOAD_PATH.push("~/lib/ruby");
require 'WithConfParam.rb' ;
require 'Geo2D.rb' ;

#--======================================================================
module Geo2D
  #--======================================================================
  #++
  ## RTree implements by pure ruby
  class RTree < WithConfParam
    #--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    #++
    ## description of DefaultOptsions.
    DefaultConf = { :branchN => 4,
                    nil => nil
                  } ;

    #--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    #++
    ## branching factor at node
    attr_accessor :branchN ;
    ## root node
    attr_accessor :root ;

    #--------------------------------------------------------------
    #++
    ## description of method initialize
    ## _conf_:: about argument baz.
    def initialize(conf = {})
      super(conf) ;
      setup() ;
    end

    #--------------------------------------------------------------
    #++
    ## setup parameters.
    def setup()
      @branchN = getConf(:branchN) ;
      @root = Node.new(self) ;
    end

    #--------------------------------------------------------------
    #++
    ## insert geo object.
    def insert(geo)
      @root.insert(geo) ;
    end

    #--------------------------------------------------------------
    #++
    ## insert geo object.
    def delete(geo)
      @root.delete(geo) ;
    end

    #--------------------------------------------------------------
    #++
    ## search
    def searchByBBox(bbox)
      @root.searchByBBox(bbox, []) ;
    end

    #--------------------------------------------------------------
    #++
    ## show tree.
    def showTree(strm = $stdout)
      @root.showTree(strm, "", "  ") ;
    end

    #--============================================================
    #--::::::::::::::::::::::::::::::::::::::::::::::::::::::::::::
    #--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    #--------------------------------------------------------------

    #--============================================================
    #++
    ## Node class
    class Node
      #--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
      #++
      ## mother tree
      attr_accessor :tree ;
      ## parent node.
      attr_accessor :parent ;
      ## children node.  an array of Node or entity
      attr_accessor :children ;
      ## flag to indicate bottom. the bottom node's children should be entities.
      attr_accessor :isBottom ;
      ## boundary box.
      attr_accessor :bbox ;
      ## object counter
      attr_accessor :count ;

      #------------------------------------------
      #++
      ## initializer/constructor
      def initialize(parent)
        setParent(parent) ;
        @children = [] ;
        @isBottom = true ;
        @bbox = nil ;
        @count = 0 ;
      end
      
      #------------------------------------------
      #++
      ## initializer/constructor
      def setParent(parent)
        if(parent.is_a?(RTree))
          @parent = nil ;
          @tree = parent ;
        elsif(parent.is_a?(Node))
          @parent = parent ;
          @tree = parent.tree ;
        elsif(parent.nil?)
          @parent = nil ;
          @tree = nil ;
        else
          raise "Illegal parent:" + parent.inspect ;
        end
      end

      #------------------------------------------
      #++
      ## branch N.
      def branchN()
        return @tree.branchN ;
      end

      #------------------------------------------
      #++
      ## fill check.
      def isFill()
        return (@children.size >= branchN()) ;
      end
      
      #------------------------------------------
      #++
      ## insert.
      def insert(geo)
        if(isBottom()) then
          insertToBottom(geo) ;
        else
          insertToMiddle(geo) ;
        end
      end

      #------------------------------------------
      #++
      ## insert to bottom node.
      def insertToBottom(geo) ;
        if(isFill()) then
          bottomDown() ;
          insert(geo) ;
        else
          @children.push(geo) ;
          @count += 1;
          updateBBox(geo) ;
        end
      end

      #------------------------------------------
      #++
      ## update bbox.
      def updateBBox(geo)
        @bbox = insertToBox(@bbox, geo) ;
      end
      
      #------------------------------------------
      #++
      ## update bbox.
      def insertToBox(box, geo)
        if(box.nil?) ;
          box = geo.bbox() ;
        else
          box.insert(geo) ;
        end
        return box ;
      end

      #------------------------------------------
      #++
      ## bottom Down.
      def bottomDown()
        newChildren = [] ;
        @children.each{|leaf|
          node = Node.new(self) ;
          node.insert(leaf) ;
          newChildren.push(node) ;
        }
        @children = newChildren ;
        @isBottom = false ;
      end
      
      #------------------------------------------
      #++
      ## insert to middle node.
      def insertToMiddle(geo)
        bestNode = nil ;
        bestCost = nil ;
        @children.each{|node|
          cost = node.calcInsertCost(geo) ;
          if(bestNode.nil? || cost < bestCost) then
            bestNode = node ;
            bestCost = cost ;
          end
        }
        bestNode.insert(geo) ;
        updateBBox(geo) ;
        @count += 1 ;
      end

      #------------------------------------------
      #++
      ## calc insert cost
      def calcInsertCost(geo)
        incArea = calcIncreasingArea(geo) ;
        return incArea * @count ;
      end
      
      #------------------------------------------
      #++
      ## calc insert cost
      def calcIncreasingArea(geo)
        if(@bbox.nil?) then
          return geo.bbox.grossArea() ;
        else
          tempBBox = @bbox.dup(true) ;
          origArea = tempBBox.grossArea() ;
          tempBBox.insert(geo) ;
          newArea = tempBBox.grossArea() ;
          return newArea - origArea ;
        end
      end
      
      #------------------------------------------
      #++
      ## search by BBox
      def searchByBBox(_bbox, result)
        if(_bbox.intersectsWithBox(bbox())) then
          if(isBottom()) then
            @children.each{|child|
              result.push(child) if(_bbox.intersectsWithBox(child.bbox())) ;
            }
          else
            @children.each{|child|
              child.searchByBBox(_bbox, result) ;
            }
          end
        end
        return result ;
      end

      #------------------------------------------
      #++
      ## delete.
      def delete(geo)
        c = 0 ;
        if(!bbox().nil? && bbox().intersectsWithBox(geo.bbox())) then
          if(isBottom()) then
            c = deleteFromBottom(geo) ;
          else
            c = deleteFromMiddle(geo) ;
          end
          recalcBBox() if(c>0) ;
        end
        return c ;
      end

      #------------------------------------------
      #++
      ## delete from bottom node.
      def deleteFromBottom(geo)
        c = 0 ;
        @children.each{|obj|
          if(geo == obj) then
            @children.delete(obj) ;
            @count -= 1 ;
            c += 1 ;
          end
        }
        return c ;
      end

      #------------------------------------------
      #++
      ## delete from middle node.
      def deleteFromMiddle(geo)
        csum = 0 ;
        @children.each{|child|
          c = child.delete(geo) ;
          @count -= c ;
          csum += c ;
        }
        return csum ;
      end

      #------------------------------------------
      #++
      ## delete from bottom node.
      def recalcBBox()
        @bbox = nil ;
        @children.each{|child|
          childBBox = child.bbox() ;
          if(!childBBox.nil?) then
            if(@bbox.nil?) then
              @bbox = childBBox.dup() ;
            else
              @bbox.insert(childBBox) ;
            end
          end
        }
        return @bbox ;
      end

      #------------------------------------------
      #++
      ## show tree.
      def showTree(strm, indent, nextIndent)
        strm << indent << "*+[#{@count}]: #{@bbox}" << "\n" ;
        c = 0 ;
        @children.each{|child|
          c += 1 ;
          if(child.is_a?(Node)) then
            child.showTree(strm, indent + nextIndent,
                           (c < @children.size ? "| " : "  ")) ;
          else
            strm << indent + nextIndent ;
            strm << "*===[" << child.to_s << "]" << "\n" ;
          end
        }
      end

      #--========================================
      #--::::::::::::::::::::::::::::::::::::::::
      #--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
      #------------------------------------------
    end # class Node
    
  end # class Foo

end # module Geo2D

########################################################################
########################################################################
########################################################################
if($0 == __FILE__) then

  require 'myCanvas.rb' ;
  require 'test/unit' ;
  require 'Stat/Uniform.rb' ;
  require 'pp' ;

  #--============================================================
  #++
  ## unit test for this file.
  class TC_Foo < Test::Unit::TestCase
    #--::::::::::::::::::::::::::::::::::::::::::::::::::
    #++
    ## desc. for TestData
    TestData = nil ;

    #----------------------------------------------------
    #++
    ## show separator and title of the test.
    def setup
#      puts ('*' * 5) + ' ' + [:run, name].inspect + ' ' + ('*' * 5) ;
      name = "#{(@method_name||@__name__)}(#{self.class.name})" ;
      puts ('*' * 5) + ' ' + [:run, name].inspect + ' ' + ('*' * 5) ;
      super
    end

    #----------------------------------------------------
    #++
    ## about test_a
    ## random plog
    def x_test_a
      rtree = Geo2D::RTree.new() ;
      size = 10.0 ;
      genX = Stat::Uniform.new(-size, size) ;
      genY = Stat::Uniform.new(-size, size) ;
      canvas = prepareCanvas(2 * size) ;
      n = 100 ;
      canvas.animation((0...n),0.1){|i|
        x = genX.value() ;
        y = genY.value() ;
        point = Geo2D::Point.new(x,y) ;
        showNodeOnCanvas(rtree.root, canvas) ;
        rtree.insert(point) ;
#        p [:insert, i, point] ;
#        rtree.showTree() ;
      }
    end

    #----------------------------------------------------
    #++
    ## about test_b
    ## shifting random plot
    def x_test_b
      rtree = Geo2D::RTree.new() ;
      size = 10.0 ;
      genX = Stat::Uniform.new(-size, size) ;
      genY = Stat::Uniform.new(-size, size) ;
      r = 10.0 ;
      canvas = prepareCanvas(r * size) ;
      n = 100 ;
      canvas.animation((0...n),0.1){|i|
        offset = r * size * ((i - n/2).to_f / n.to_f) ;
        x = genX.value() + offset ;
        y = genY.value() + offset ;
        p [:offset, offset, x, y] ;
        point = Geo2D::Point.new(x,y) ;
        rtree.insert(point) ;
        showNodeOnCanvas(rtree.root, canvas) ;
#        p [:insert, i, point] ;
#        rtree.showTree() ;
      }
    end

    #----------------------------------------------------
    #++
    ## about test_c
    ## shifting random plot

    def x_test_c
      rtree = Geo2D::RTree.new() ;
      size = 10.0 ;
      genX = Stat::Uniform.new(-size, size) ;
      genY = Stat::Uniform.new(-size, size) ;
      ##
      n = 100 ;
      (0...n).each{|i|
        x = genX.value() ;
        y = genY.value() ;
        point = Geo2D::Point.new(x,y) ;
        rtree.insert(point) ;
      }
      ##
      s = size/4.0 ;
      box = Geo2D::Box.new([-s, -s],[s, s]) ;
      plist = rtree.searchByBBox(box) ;
      pp plist ;
      ##
      canvas = prepareCanvas(2 * size) ;
      canvas.singlePage('white'){
        showNodeOnCanvas(rtree.root, canvas) ;
        canvas.drawEmptyRectangle(box.minX(), box.minY(),
                                  box.sizeX(), box.sizeY(),'orange') ;
        d = 2.0 / canvas.getScaleX() ;
        plist.each{|pt|
          canvas.drawFilledRectangle(pt.minX()-d, pt.minY()-d,
                                     2*d, 2*d, 'red') ;
        }
      }
    end
    

    #----------------------------------------------------
    #++
    ## about test_d
    ## shifting random plot

    def test_d
      rtree = Geo2D::RTree.new() ;
      size = 10.0 ;
      genX = Stat::Uniform.new(-size, size) ;
      genY = Stat::Uniform.new(-size, size) ;
      ##
      n = 500 ;
      m = 100 ;
      plist = [] ;
      canvas = prepareCanvas(2 * size) ;
      canvas.animation((0...n),0.1){|i|
        x = genX.value() ;
        y = genY.value() ;
        point = Geo2D::Point.new(x,y) ;
        plist.push(point) ;
        rtree.insert(point) ;
        if(i >= m) then
          p = plist[rand(plist.size)] ;
          rtree.delete(p) ;
          plist.delete(p) ;
        end
        showNodeOnCanvas(rtree.root, canvas) ;
      }
    end

    #----------------------------------------------------
    #++
    ## 
    def prepareCanvas(rangeXY, sizeXY = 512)
      scale = sizeXY.to_f / rangeXY.to_f ;
      canvas = MyCanvas.new('gtk',
                            { 'width' => sizeXY,
                              'height' => sizeXY,
                              'scale' => scale,
                              'centerp' => true }) ;
      return canvas ;
    end
      
    #----------------------------------------------------
    #++
    ## show on canvas
    def showRTreeOnCanvas(rtree)
      sizeX = 20.0 ;
      canvas = prepareCanvas(sizeX) ;
      canvas.singlePage('white') {
        showNodeOnCanvas(rtree.root, canvas) ;
      }
    end
    
    def showNodeOnCanvas(node, canvas)
#      p [:node, node.bbox()] ;
      bbox = node.bbox() ;
      if(node.is_a?(Geo2D::RTree::Node)) then
        return if(bbox.nil?) ;
        canvas.drawEmptyRectangle(bbox.minX(), bbox.minY(),
                                  bbox.sizeX(), bbox.sizeY(),'green') ;
        node.children.each{|child|
          showNodeOnCanvas(child, canvas) ;
        }
      else
        d = 1.0 / canvas.getScaleX() ;
        canvas.drawFilledRectangle(bbox.minX()-d, bbox.minY()-d,
                                   bbox.sizeX()+2*d, bbox.sizeY()+2*d,'red') ;
      end
    end

  end # class TC_Foo < Test::Unit::TestCase
end # if($0 == __FILE__)
