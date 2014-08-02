#! /usr/bin/env ruby
## -*- mode: ruby -*-
## = With Configuration Utility
## Author:: Itsuki Noda
## Version:: 0.0 2010/??/?? I.Noda
##
## === History
## * [2010/??/??]: Create This File.
## * [2014/08/01]: reform and add access method to get Conf from class
## == Usage
## * ...

$LOAD_PATH.push("~/lib/ruby") ;
require 'sexp.rb' ;

## WithConfParam library

#--======================================================================
#++
## Meta class for configuration facility.
class WithConfParam

  #--::::::::::::::::::::::::::::::::::::::::::::::::::
  #++
  ## default configuration.
  DefaultConf = { nil => nil } ;
  ## default value if missing key
  DefaultValue = nil ;
  
  #--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
  #++
  ## store configuration for each instance
  attr :conf, true ;
  
  #----------------------------------------------------
  #++
  ## class method to access default config
  ## _key_:: key of the configuration
  ## *return*:: the value for the _key_.
  def self.getConf(key)
    if(self::DefaultConf.has_key?(key))
      return self::DefaultConf[key] ;
    elsif(self == WithConfParam) then
      return nil ;
    else
      return self.superclass().getConf(key) ;
    end
  end

  #----------------------------------------------------
  #++
  ## initialize with configuration
  ## _conf_:: configuration for the instance
  def initialize(conf = {}) 
    setPiledConf(conf) ;
  end

  #----------------------------------------------------
  #++
  ## generate instance configuration including class default configurations
  ## _conf_:: configuration for the instance
  def setPiledConf(conf) 
    @conf = genPiledConf(conf) ;
  end

  #----------------------------------------------------
  #++
  ## generate configuration with class default configurations
  ## _conf_:: configuration for the instance
  ## *return*:: the configuration table for the instance
  def genPiledConf(conf = {})
    return genPiledDefaultConf().update(conf) ;
  end

  #----------------------------------------------------
  #++
  ## generate class default configurations recursively
  ## _klass_:: the class now processing
  ## *return*:: default configuration table for the instance
  def genPiledDefaultConf(klass = self.class())
    if(klass == WithConfParam) then
      return klass::DefaultConf.dup() ;
    else
      newConf = genPiledDefaultConf(klass.superclass()) ;
      if(klass.const_defined?(:DefaultConf)) 
        newConf.update(klass::DefaultConf) ;
      end
      
      return newConf ;
    end
  end

  #----------------------------------------------------
  #++
  ## set configuration value
  ## _key_:: key of the configuration
  ## _value_:: value of the configuration
  def setConf(key, value)
    @conf[key] = value ;
  end

  #----------------------------------------------------
  #++
  ## get configuration value
  ## _key_:: key of the configuration
  ## _defaultValue_:: default value for missing key
  ## _conf_:: temporal configuration
  ## *return*:: the value for the _key_.
  def getConf(key, defaultValue = DefaultValue, conf = @conf)
    if (conf.key?(key)) then
      return conf[key] ;
    elsif(conf != @conf && @conf.key?(key)) then
      return @conf[key] ;
    else
      return defaultValue ;
    end
  end

  #----------------------------------------------------
  #++
  ## convert to Sexp format.
  ## *return*:: an Sexp object
  def to_SexpConf()
    return to_SexpConfBody(:conf, @conf) ;
  end

  #----------------------------------------------------
  #++
  ## body method for to_SexpConf()
  ## _tag_:: tag to indicate the object
  ## _conf_:: the configuration
  ## *return*:: an Sexp object
  def to_SexpConfBody(tag, conf)
    body = Sexp::nil ;
    atomP = false ;
    if(conf.is_a?(Hash)) then
      conf.each{|key,value|
        next if (key.nil? && value.nil?) ;
        entry = to_SexpConfBody(key,value) ;
        body = Sexp::cons(entry, body) ;
      }
      body = body.reverse() ;
    elsif(conf.is_a?(Array)) then
      conf.each{|value|
        entry = to_SexpConfBody(nil, value) ;
        body = Sexp::cons(entry, body) ;
      }
      body = body.reverse() ;
    else
      body = Sexp::list(conf) ;
      atomP = true ;
    end

    if(tag.nil?) then
      body = body.car() if(atomP) ;
      sexp = body ;
    else
      sexp = Sexp::cons(tag, body) ;
    end
    
    return sexp ;
  end

end ## class WithConfParam


########################################################################
########################################################################
########################################################################
if($0 == __FILE__) then

  require 'test/unit'

  #--============================================================
  #++
  ## unit test for this file.
  class TC_WithConfParam < Test::Unit::TestCase
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
    ## basic check
    class FooA < WithConfParam
      DefaultConf = { :x => 1, :z => 0 } ;
    end

    class BarA < FooA
      DefaultConf = { :y => 2 } ;
    end

    class CooA < BarA
      DefaultConf = { :x => 3 } ;
    end

    def test_a
      f0 = FooA.new() ;
      b0 = BarA.new() ;
      c0 = CooA.new() ;
      c1 = CooA.new({:y => 4}) ;

      p [:f0, :x, f0.getConf(:x)] ;
      p [:f0, :y, f0.getConf(:y)] ;
      p [:b0, :x, b0.getConf(:x)] ;
      p [:b0, :y, b0.getConf(:y)] ;
      p [:c0, :x, c0.getConf(:x)] ;
      p [:c0, :y, c0.getConf(:y)] ;
      p [:c1, :x, c1.getConf(:x)] ;
      p [:c1, :y, c1.getConf(:y)] ;

    end

    #----------------------------------------------------
    #++
    ## getConf for the class
    def test_b
      p [FooA, :x, FooA.getConf(:x)] ;
      p [FooA, :y, FooA.getConf(:y)] ;
      p [BarA, :x, BarA.getConf(:x)] ;
      p [BarA, :y, BarA.getConf(:y)] ;
      p [CooA, :x, CooA.getConf(:x)] ;
      p [CooA, :y, CooA.getConf(:y)] ;
      p [CooA, :z, CooA.getConf(:z)] ;
    end


  end # class TC_Foo < Test::Unit::TestCase
end # if($0 == __FILE__)
