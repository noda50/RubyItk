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

  require 'test/unit' ;
  require 'Stat/Uniform.rb' ;

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
    def test_a
      rtree = Geo2D::RTree.new() ;
      genX = Stat::Uniform.new(-10.0, 10.0) ;
      genY = Stat::Uniform.new(-10.0, 10.0) ;
      n = 100 ;
      (0...n).each{|i|
        x = genX.value() ;
        y = genY.value() ;
        point = Geo2D::Point.new(x,y) ;
        rtree.insert(point) ;
        p [:insert, i, point] ;
        rtree.showTree() ;
      }
    end

  end # class TC_Foo < Test::Unit::TestCase
end # if($0 == __FILE__)
