#! /usr/bin/env ruby
## -*- Mode: ruby -*-
########################################################################
##Header:
##File: LinearAlgebra/Matrix
##Author: Itsuki Noda
##Date: 2013/03/24
##EndHeader:
########################################################################

$LOAD_PATH.push("~/lib/ruby") ;
require 'Stat/Random.rb' ;

##======================================================================
module LinearAlgebra

  ##============================================================
  class Matrix
    ##==============================
    class SingularMatrixException < Exception
      attr :k, true ;
      attr :matrix, true ;
      attr :work, true ;
      attr :result, true ;

      ##--------------------------------------------------
      def initialize(matrix, k, work, result)
        @matrix = matrix ;
        @k = k ;
        @work = work ;
        @result = result ;
      end
    end # class SingularMatrixException

    ##::::::::::::::::::::::::::::::::::::::::::::::::::
    PivotEps = 1.0e-100 ;

    ##@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    attr :n, true ;
    attr :m, true ;
    attr :value, true ;

    ##--------------------------------------------------
    def initialize(n=nil, m=n, v=0.0)
      setup(n,m,v) if(!n.nil?) ;
    end

    ##--------------------------------------------------
    def setup(n, m, v)
      @n = n ;
      @m = m ;
      @value = Array.new(@n) ;
      (0...@n).each{|i|
        @value[i] = Array.new(@m) ;
        (0...@m).each{|j|
          self[i,j] = v ;
        }
      }
      @value ;
    end

    ##--------------------------------------------------
    def [](n, m)
      @value[n][m] ;
    end

    ##--------------------------------------------------
    def []=(n, m, v)
      @value[n][m] = v ;
    end

    ##--------------------------------------------------
    def each(&block)
      (0...@n).each{|i|
        (0...@m).each{|j|
          block.call(i,j) ;
        }
      }
    end

    ##--------------------------------------------------
    def eachValue(&block)
      self.each{|i,j|
        block.call(self[i,j],i,j) ;
      }
    end

    ##--------------------------------------------------
    def eachSetValue(&block)
      self.each{|i,j|
        self[i,j] = block.call(i,j) ;
      }
    end

    ##--------------------------------------------------
    def dup()
      newMatrix = Matrix.new(@n,@m) ;
      self.each{|i,j|
        newMatrix[i,j] = self[i,j]
      }
      return newMatrix ;
    end

    ##--------------------------------------------------
    def letUnit(n = @n)
      setup(n, n, 0.0) ;
      (0...@n).each{|i|
        self[i,i] = 1.0 ;
      }
      return self ;
    end

    ##--------------------------------------------------
    def setValue(v)  ## v should be a Random Value or a number.
      self.eachSetValue{|i,j|
        (v.is_a?(Stat::RandomValue) ? v.value :
         v.is_a?(Array) ? v[i][j] : v)
      }
    end

    ##--------------------------------------------------
    def setUniformRandom(min, max)
      setValue(Stat::Uniform.new(min,max)) ;
    end

    ##--------------------------------------------------
    def transpose()
      result = Matrix.new(@m,@n) ;
      self.each{|i,j|
        result[j,i] = self[i,j] ;
      }
      return result ;
    end

    ##--------------------------------------------------
    def add(mx)
      if(self.n != mx.n || self.m != mx.m) then
        raise "unmatch size: (#{self.n},#{self.m}) <=> (#{mx.n},#{mx.m})"
      end

      result = self.dup() ;
      self.each{|i,j|
        result[i,j] += mx[i,j] ;
      }
      return result ;
    end

    ##--------------------------------------------------
    def sub(mx)
      if(self.n != mx.n || self.m != mx.m) then
        raise "unmatch size: (#{self.n},#{self.m}) <=> (#{mx.n},#{mx.m})"
      end

      result = self.dup() ;
      self.each{|i,j|
        result[i,j] -= mx[i,j] ;
      }
      return result ;
    end

    ##--------------------------------------------------
    def mul(a)

      if(a.is_a?(Matrix)) then
        return mulMatrix(a) ;
      elsif(a.is_a?(Numeric))
        return mulScalar(a) ;
      else
        raise "Unsupported matrix multiply by : #{a.inspect}" ;
      end
    end

    ##--------------------------------------------------
    def mulScalar(a)
      result = self.dup() ;
      result.each{|i,j|
        result[i,j] *= a ;
      }
      return result ;
    end

    ##--------------------------------------------------
    def mulMatrix(mx)
      raise "unmatch row-col: #{self} : #{mx}" if (@m != mx.n) ;

      result = Matrix.new(@n, mx.m) ;
      (0...@n).each{|i|
        (0...mx.m).each{|j|
          v = 0.0 ;
          (0...@m).each{|k|
            v += self[i,k] * mx[k,j] ;
          }
          result[i,j] = v ;
        }
      }

      return result ;
    end

    ##--------------------------------------------------
    ## Gaussian Sweep Out
    ##----------------------------------------
    def swapRow(i,j)
      if(i < 0 || i >= @n || j < 0 || j >= @n) then
        raise("out of range of row index:(#{i},#{j}) in #{self.to_s}")
      end

      buffer = @value[i] ;
      @value[i] = @value[j] ;
      @value[j] = buffer ;

      self ;
    end

    ##----------------------------------------
    def swapCol(i,j)
      if(i < 0 || i >= @m || j < 0 || j >= @m) then
        raise("out of range of col index:(#{i},#{j}) in #{self.to_s}")
      end

      (0...@n).each{|k|
        buffer = self[k,i] ;
        self[k,i] = self[k,j] ;
        self[k,j] = buffer ;
      }

      self ;
    end

    ##----------------------------------------
    def abs(v)
      (v > 0 ? v : -v)
    end

    ##----------------------------------------
    def findPivotKth(k)
      if(k < 0 || k >= @n) then
        raise("out of range of row-col index:(#{k},#{k}) in #{self.to_s}")
      end

      maxV = nil ;
      maxI = nil ;
      (k...@n).each{|i|
        v = abs(self[i,k]) ;
        if(maxV.nil? || maxV < v) then
          maxV = v ;
          maxI = i ;
        end
      }

      return maxI ;
    end

    ##----------------------------------------
    def mulKthRow(k, a)
      (0...@m).each{|j|
        self[k,j] = a * self[k,j] ;
      }
    end

    ##----------------------------------------
    def sweepOutRowKth(k)
      (0...@n).each{|i|
        if(i != k) then
          a = self[i,k] / self[k,k] ;
          (0...@m).each{|j|
            self[i,j] = self[i,j] - a * self[k,j] ;
          }
        end
      }
    end

    ##----------------------------------------
    def inverse()
      inverseBySweepOut() ;
    end

    ##----------------------------------------
    def inverseBySweepOut()
      raise "The matrix is not square: #{self}" if (@n != @m) ;

      original = self.dup ;
      target = Matrix.unit(@n) ;

      (0...@n).each{|k|
        i = original.findPivotKth(k) ;
        original.swapRow(i,k) ;
        target.swapRow(i,k) ;

        v =  original[k,k] ;

        if(abs(v) < PivotEps) then
          raise SingularMatrixException.new(self, k, original, target) ;
        end

        original.mulKthRow(k, (1.0/v)) ;
        target.mulKthRow(k, (1.0/v)) ;
        (0...@n).each{|i|
          if(i != k) then
            a = original[i,k] / original[k,k] ;
            (0...@m).each{|j|
              original[i,j] = original[i,j] - a * original[k,j] ;
              target[i,j] = target[i,j] - a * target[k,j] ;
            }
          end
        }
      }

      return target ;
    end

    ##--------------------------------------------------
    def row(i)
      @value[i] ;
    end

    ##--------------------------------------------------
    def col(j)
      r = Array.new(@n) ;
      (0...@n).each{|i|
        r[i] = self[i,j] ;
      }
      return r ;
    end

    ##--------------------------------------------------
    def to_a
      r = Array.new(@n * @m) ;
      self.each{|i,j|
        r[i * @m + j] = self[i,j] ;
      }
      return r ;
    end

    ##--------------------------------------------------
    def to_s
      ("\#Mx<(#{@n},#{@m}):" + @value.inspect + ">")
    end

    ##--------------------------------------------------
    def inspect
      ("\#Mx<(#{@n},#{@m}):" + @value.inspect + ">")
    end

  end ## class Matrix
  ##============================================================
  class << Matrix
    def unit(n)
      uMatrix = Matrix.new() ;
      uMatrix.letUnit(n) ;
      return uMatrix ;
    end
  end ## class << Matrix
  ##============================================================

end ## module LinearAlgebra

##======================================================================
module LA
  include LinearAlgebra
end ## module LA

########################################################################
########################################################################
########################################################################
if(__FILE__ == $0) then
  require 'test/unit'

  ##============================================================
  class TC_Matrix < Test::Unit::TestCase

    ##----------------------------------------
    def setup
      puts ('*' * 5 ) + ' ' + [:run, name].inspect + ' ' + ('*' * 5) ;
      super
    end

    ##----------------------------------------
    def test_a()
      mx0 = LA::Matrix.new(3) ;
      p mx0 ;
      mx1 = LA::Matrix.new(3,2,1.0) ;
      p mx1 ;
    end

    ##----------------------------------------
    def test_b()
      mx0 = LA::Matrix::unit(3) ;
      p mx0 ;
    end

    ##----------------------------------------
    def test_c()
      mx0 = LA::Matrix::new(3,3) ;
      mx0.setUniformRandom(-1.0, 1.0) ;
      p [:rand, mx0] ;

      mx1 = LA::Matrix::unit(3) ;
      p [:unit, mx1] ;

      i = mx0.findPivotKth(0) ;
      p [:pivot, i] ;
      mx0.swapRow(0,i) ;
      mx1.swapRow(0,i) ;
      p [:rand, mx0] ;
      p [:unit, mx1] ;
    end

    ##----------------------------------------
    def test_d()
      mx0 = LA::Matrix::new(3,3) ;
      mx0.setValue([[2,0,1],[0,0,1],[0,1,0]]) ;

      p mx0 ;

      mx1 = mx0.inverseBySweepOut() ;

      p mx0 ;
      p mx1 ;

      p mx0.mul(mx1) ;
    end

    ##----------------------------------------
    def test_e()
      mx0 = LA::Matrix::new(3,3) ;
      mx0.setUniformRandom(-1,1) ;

      p mx0 ;

      mx1 = mx0.inverseBySweepOut() ;

      p mx0 ;
      p mx1 ;

      p mx0.mul(mx1) ;
    end

  end ## class TC_Matrix
end
