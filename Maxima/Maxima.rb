#! /usr/bin/env ruby
## -*- mode: ruby -*-

#--======================================================================
#++
module Itk
  #--============================================================
  #++
  ## Maxima interface
  class Maxima
    #--::::::::::::::::::::::::::::::::::::::::::::::::::
    #++
    ## maxima command
    CommandName = 'maxima' ;
    #CommandPath = '/usr/bin/maxima'

    ## command line option
    CommandOpts = '--very-quiet'

    #--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    #++
    ## [String] full path for maxima command.
    attr :commandPath, true ;
    ## [String] command line option.
    attr :commandOpts, true ;
    ## [IO] a pipe process of Maxima.
    attr :strm, true ;

    #----------------------------------------------------
    #++
    ## initialization
    def initialize()
      @commandPath = findFullPathToCom(CommandName) ;
      @commandOpts = CommandOpts ;
      setup() ;
    end

    #--------------------------------------------------------------
    #++
    ## find full path using "which" command.
    ## _com_:: [a String] command name.
    ## *return*:: [a String] full path or nil.
    def findFullPathToCom(com)
      path = nil ;
      open("| which #{com}","r"){|strm|
        path = strm.gets ;
        path.chomp! if(path) ;
      }
    end

    #----------------------------------------------------
    #++
    ## setup pipe and suppress 2d display
    def setup()
      @strm = IO::popen("#{@commandPath} #{@commandOpts}",'r+') ;
      call("display2d:false;")
      call("linel:1000000000;")
    end

    #----------------------------------------------------
    #++
    ## simple call.
    ## From String to String.
    ## _form_:: [String] form to send to Maxima.
    ## *return*:: [String] answer from Maxima.
    def call(form)
#      p [:inp, form] ;
      @strm.puts(form) ;
#      r = @strm.gets() ;
      r = readAfterSkip() ;
#      p [:ret, r] ;
      r
    end

    #----------------------------------------------------
    #++
    ## read after skip errors/warnings
    ## *return*:: [String] read answer form from Maxima.
    def readAfterSkip()
      r = nil ;
      while(r = @strm.gets())
        break if (!(r =~ /errors/ || r =~ /warnings/)) ;
      end
      return r ;
    end

    #----------------------------------------------------
    #++
    ## reform Maxima form for Ruby
    ## _form_:: [String] Maxima's anser form.
    ## *return*:: [String] String that can be parse as a Ruby object.
    def reformForRuby(form)
      # "-.123.." -> "-0.123"
#      form.gsub!(/\-\./,'-0.') ;
      form.gsub!(/([^0-9])\./,"\\10.") ;
      form.gsub!(/^\./,"0.") ;
      form ;
    end

    #----------------------------------------------------
    #++
    ## scan Maxima form for Ruby
    ## _form_:: [String] Maxima form.
    ## *return*:: [Object] Ruby object.
    def scan(form)
      self.instance_eval(reformForRuby(form)) ;
    end

    #----------------------------------------------------
    #++
    ## calc determinant of a given matrix
    ## _matrix_:: [Array of Array of Numeric]
    ## *return*:: [Float] a determinant of the _matrix_.
    def determinant(matrix)
      form = "determinant(#{matrix2maxima(matrix)});" ;
      reply = call(form) ;
      scan(reply) ;
    end

    #----------------------------------------------------
    #++
    ## calc invert matrix
    ## _matrix_:: Array of Array of Numeric
    def invert(matrix)
      form = "invert(#{matrix2maxima(matrix)});" ;
      reply = call(form) ;
      scan(reply) ;
    end

    #----------------------------------------------------
    #++
    #--
    ## *** Maxima の返り値が実数ではないため、対応できず。 ***
    ## calc eigen values of matrix
    ## _matrix_:: [Array of Array of Numeric]
    ## *return*:: [Float] An Array of eigen values
    def eigenvalues_not_work(matrix)
      form = "eigenvalues(#{matrix2maxima(matrix)});" ;
      reply = call(form) ;
      eValMaxima = scan(reply) ;
      eVal = [] ;
      (0...eValMaxima[0].size).each{|i|
        ev = eValMaxima[0][i] ;
        n = eValMaxima[1][i] ;
        n.times{ eVal.push(ev)} ;
      }
      return eVal ;
    end

    #----------------------------------------------------
    #++
    ## calc trace of matrix
    ## _matrix_:: [Array of Array of Numeric]
    ## *return*:: [Float] the trace value
    def trace(matrix)
      form = "mat_trace(#{matrix2maxima(matrix)});" ;
      reply = call(form) ;
      scan(reply) ;
    end

    #----------------------------------------------------
    #++
    ## converter from Ruby Matrix to Maxima form
    ## _matrix_:: [Array of Array of Numeric]
    ## *return*:: [String] a Maxima matrix.
    def matrix2maxima(matrix)
      str = "matrix(" ;
      matrix.each{|vector|
        str += "[" + vector.map{|v| float2maxima(v)}.join(',') + "]," ;
      }
      str.chop!() ; ## remove last ","
      str += ")" ;
      return str ;
    end

    #----------------------------------------------------
    #++
    ## converter from Ruby Float to Maxima Float
    ## _value_:: [Float]
    ## *return*:: [String] a Maxima float value.
    def float2maxima(value)
      str = value.to_s ;
      str.gsub!(/^0\./,'.') ;
      str.gsub!(/^-0\./,'-.') ;
      return str ;
    end

    #----------------------------------------------------
    #++
    ## converter from Maxima form to Ruby Matrix
    ## *_arrays_:: list of Array of Numeric
    ## *return*:: [Array of Array]
    def matrix(*arrays)
      Array.new(arrays.size){|i| arrays[i]} ;
    end

  end ## class Maxima

end ## module Itk

########################################################################
########################################################################
########################################################################
if($0==__FILE__) then
  require 'test/unit'
  require 'pp' ;

  #--============================================================
  #++
  class TC_Maxima < Test::Unit::TestCase
    #----------------------------------------------------
    #++
    def setup
      puts ('*' * 5 ) + ' ' + [:run, name].inspect + ' ' + ('*' * 5) ;
      super
    end

    #----------------------------------------------------
    #++
    ## setup test
    def test_a()
      mx = Itk::Maxima.new() ;
      pp mx ;
    end

    #----------------------------------------------------
    #++
    ## determinant and invert maxtrix
    def test_b()
      mx = Itk::Maxima.new() ;
      x = [[1.0,2,3,4],[4,1,2,3],[3,1,4,2],[1,2,1,3]] ;
      pp x ;
      pp mx.determinant(x) ;
      pp mx.invert(x) ;
    end

    #----------------------------------------------------
    #++
    ## determinant and invert maxtrix
    def test_c()
      mx = Itk::Maxima.new() ;
      x = [[1.0,2,3,4],[4,1,2,3],[3,1,4,2],[1,2,1,3]] ;
      pp x ;
#      pp mx.eigenvalues(x) ;
      pp mx.trace(x) ;
    end
  end ## class TC_Maxima
end ## if($0==__FILE__)
