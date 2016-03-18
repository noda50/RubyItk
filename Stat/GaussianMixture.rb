#! /usr/bin/env ruby
## -*- mode: ruby -*-
## = Gaussian Mixture
## Author:: Itsuki Noda
## Version:: 0.0 2016/03/18 I.Noda
##
## === History
## * [2016/03/18]: Create This File.
## * [YYYY/MM/DD]: add more
## == Usage
## * ...

$LOAD_PATH.push("~/lib/ruby");

require 'Stat/Gaussian.rb' ;
require 'pp' ;

#--======================================================================
module Stat
  
  #--============================================================
  #++
  ## Gaussian Mixture Density Function 
  class GaussianMixture < RandomValue
    
    #--========================================
    #++
    ## Weighted Gaussian
    class WeightedGaussian < Gaussian
      #--::::::::::::::::::::::::::::::
      #++
      ## weight
      attr_accessor :weight ;

      #--------------------------------
      #++
      ## constractor
      def initialize(weight = 1.0, mean = 0.0, std = 1.0)
        super(mean, std) ;
        @weight = weight ;
      end

      #-------------------------------
      #++
      ## weighted density
      def density(x)
        return @weight * super(x) ;
      end

      #------------------------------
      #++
      ## get string
      def to_s()
        ("#WG[w=%f, m=%f, s=%f]" % [@weight, @mean, @std]) ;
      end

    end ## class WeightedGaussian

    #--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    #++
    ## Weighted Gaussian List
    attr_accessor :distList ;

    #----------------------------------------------------
    #++
    ## constractor
    ## _param_:: parameters
    ##           if _param_ is integer, generate N weighted gaussian.
    ##           if _param_ is array, each element of the array should be
    ##           a list [weight, mean, std]
    def initialize(param)
      setup(param) ;
    end

    #----------------------------------------------------
    #++
    ## setup
    ## _param_:: parameters
    ##           if _param_ is integer, generate N weighted gaussian.
    ##           if _param_ is array, each element of the array should be
    ##           a list [weight, mean, std]
    def setup(param)
      @distList = [] ;
      if(param.is_a?(Array)) then
        param.each{|p| ## p should be [weight, mean, std]
          (weight, mean, std) = p ;
          @distList.push(WeightedGaussian.new(weight, mean, std)) ;
        }
      elsif(param.is_a?(Fixnum)) then
        (0...param).each{|i|
          @distList.push(WeightedGaussian.new()) ;
        }
      else
        raise ("param should be an integer or array of [weight, mean, std]:" +
               "param=" + param.inspect) ;
      end
      normalize() ;
    end

    #----------------------------------------------------
    #++
    ## normalize.
    ## make sum of weights to be 1.0
    def normalize()
      weightSum = 0.0 ;
      @distList.each{|wg|
        weightSum += wg.weight ;
      }
      if(weightSum > 0.0) then
        @distList.each{|wg|
          wg.weight /= weightSum ;
        }
      else
        raise "sum of weight should be positive.  weight sum =" + weightSum ;
      end
    end
    
    #----------------------------------------------------
    #++
    ## get density of x
    def density(x)
      v = 0.0 ;
      @distList.each{|wg|
        v += wg.density(x) ;
      }
      return v ;
    end

    #----------------------------------------------------
    #++
    ## get random value
    def rand()
      v = Kernel::rand() ;
      @distList.each{|wg|
        v -= wg.weight ;
        if(v <= 0.0) then
          return wg.rand() ;
        end
      }
      return distList.last.rand() ;
    end

    #----------------------------------------------------
    #++
    ## get random value
    def value()
      return rand() ;
    end
    
    #----------------------------------------------------
    #++
    ## convert to string
    ## *return*:: string
    def to_s()
      return ('#Mixture[' +
              @distList.map(){|wg| wg.to_s()}.join(",") +
              ']') ;
    end

    #--==================================================
    #--::::::::::::::::::::::::::::::::::::::::::::::::::
    #--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    #----------------------------------------------------
  end # class GaussianMixture

end # module Stat

########################################################################
########################################################################
########################################################################
if($0 == __FILE__) then

  require 'test/unit'
  require 'gnuplot.rb' ;
  require 'Stat/Uniform.rb' ;

  #--============================================================
  #++
  ## unit test for this file.
  class TC_GaussianMixture < Test::Unit::TestCase
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
      gm = Stat::GaussianMixture.new(3) ;
      puts gm ;
      pp gm ;
    end

    #----------------------------------------------------
    #++
    ## about test_b
    def test_b
      wGen = Stat::Uniform.new(0.1, 1.0) ;
      mGen = Stat::Uniform.new(-1.0, 1.0) ;
      sGen = Stat::Uniform.new(0.0, 0.3) ;
      param = [] ;
      (0...3).each{|i|
        param.push([wGen.value(), mGen.value(), sGen.value()]) ;
      }
      gm = Stat::GaussianMixture.new(param) ;
      puts gm ;
      pp gm ;
      Gnuplot::directMultiPlot(1){|gplot|
        min = -2.0 ;
        max = 2.0 ;
        d = 0.01 ;
        v = min ;
        while(v <= max)
          gplot.dmpXYPlot(0, v, gm.density(v)) ;
          v += d ;
        end
      }
    end

  end # class TC_GaussianMixture
end # if($0 == __FILE__)
