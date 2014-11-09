#! /usr/bin/env ruby
## -*- mode: ruby -*-
## = Logger for Experiments
## Author:: Itsuki Noda
## Version:: 0.0 2014/06/11 I.Noda
##
## === History
## * [2014/06/11]: copy this from WithLogger.rb
##                 WithLogger has conflicts with ItkLogger
## * [2014/11/09]: Compress Mode
## == Usage
## * ...

require 'time' ;
require 'zlib' ;

$LOAD_PATH.push('~/lib/ruby') if(!$LOAD_PATH.member?('~/lib/ruby')) ;
require 'WithConfParam.rb' ;

#--======================================================================
#++
## Itk package
module Itk

  #--============================================================
  #++
  ## utilities
  module ExpLogUtility
    #--::::::::::::::::::::::::::::::::::::::::::::::::::
    #++
    ## Logging Level
    Level = {
      :none => LevelAll = 0,
      :debug => LevelDebug = 1,
      :info => LevelInfo = 2,
      :error => LevelError = 3,
      :fatal => LevelFatal = 4,
      :top => LevelNone = 5,
    } ;
    ## Table for Logging Level
    LevelName = {} ;
    Level.each{|key, value| LevelName[value] = key.to_s.capitalize} ;

    #--------------------------------------------------
    #++
    ## generic function for logging objects for each type of objects.
    def loggingTo(strm, obj, newlinep = true)
      if(obj.is_a?(Array))
        loggingTo_Array(strm, obj) ;
      elsif(obj.is_a?(Hash))
        loggingTo_Hash(strm, obj) ;
      elsif(obj.is_a?(Time))
        loggingTo_Time(strm, obj) ;
      elsif(obj.is_a?(Numeric))
        loggingTo_Atom(strm, obj) ;
      elsif(obj.is_a?(String))
        loggingTo_Atom(strm, obj) ;
      elsif(obj.is_a?(Symbol))
        loggingTo_Atom(strm, obj) ;
      elsif(obj.is_a?(Class))
        loggingTo_Atom(strm, obj) ;
      elsif(obj == true || obj == false || obj == nil)
        loggingTo_Atom(strm, obj) ;
      else
        loggingTo_Object(strm, obj) ;
      end
      strm << "\n" if(newlinep) ;
    end

    #--------------------------------------------------
    #++
    ## log output of Array
    def loggingTo_Array(strm, obj)
      strm << '[' ;
      initp = true ;
      obj.each{|value| 
        strm << ', ' if(!initp) ;
        initp = false ;
        loggingTo(strm, value, false) ;
      }
      strm << ']' ;
    end

    #--------------------------------------------------
    #++
    ## log output of Hash
    def loggingTo_Hash(strm, obj)
      strm << '{' ;
      initp = true ;
      obj.each{|key,value| 
        strm << ', ' if(!initp) ;
        initp = false ;
        loggingTo(strm, key, false) ;
        strm << '=>'
        loggingTo(strm, value, false) ;
      }
      strm << '}' ;
    end

    #--------------------------------------------------
    #++
    ## log output of Time
    def loggingTo_Time(strm, obj)
      strm << 'Time.parse(' ;
      strm << obj.strftime("%Y-%m-%dT%H:%M:%S%z").inspect
      strm << ')' ;
    end

    #--------------------------------------------------
    #++
    ## log output of other Objects
    def loggingTo_Object(strm, obj)
      strm << '{' ;
      strm << ':__class__' << '=>' << obj.class.inspect ;
      obj.instance_variables.each{|var|
        strm << ', ' ;
        strm << (var.slice(1...var.size).intern.inspect) ;
        strm << '=>'
        loggingTo(strm, obj.instance_eval("#{var}"), false) ;
      }
      strm << '}' ;
    end

    #--------------------------------------------------
    #++
    ## log output of Atomic or Primitive Objects
    def loggingTo_Atom(strm, obj)
      strm << obj.inspect ;
    end

    #--------------------------------------------------
    #++
    ## output message if level is higher than the current log level.
    # _level_ :: log level of this message.
    # _message_ :: an object to output for logging.
    def put(level,message)
      raise("put(level,message) is not implemented for this instance" + 
            self.inspect) ;
    end

    #--------------------------------------------------
    #++
    ## force logging
    # _message_ :: message or object
    def <<(message)
      put(LevelNone,message) ;
    end

    #--------------------------------------------------
    #++
    ## logging info debug level
    # _message_ :: message or object
    def debug(message)
      put(LevelDebug, message) ;
    end

    #--------------------------------------------------
    #++
    ## logging info level
    # _message_ :: message or object
    def info(message)
      put(LevelInfo, message) ;
    end

    #--------------------------------------------------
    #++
    ## logging error level
    # _message_ :: message or object
    def error(message)
      put(LevelError, message) ;
    end

    #--------------------------------------------------
    #++
    ## logging fatal level
    # _message_ :: message or object
    def fatal(message)
      put(LevelFatal, message) ;
    end

  end ## module Itk::ExpLogUtility

  module ExpLogUtility ; extend ExpLogUtility ; end

  #--============================================================
  #++
  ## Logger class
  class ExpLogger < WithConfParam
    include ExpLogUtility
    #--::::::::::::::::::::::::::::::::::::::::::::::::::
    #++
    ## defaults for initialization
    DefaultConf = {
      :stream => $stdout,
      :file => nil,
      :tee => false, ## if true and :file is given, make log both.
      :append => false,
      :level => LevelInfo,
      :withLevel => false,
      :compress => false,
    } ;

    #--@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
    #++
    ## log stream
    attr :stream, true ;
    ## logfile
    attr :file, true ;
    ## log level
    attr :level, true ;
    ## flag to output level info in the log
    attr :withLevelp, true ;
    ## flag to output stream and chained logger
    attr :tee, true ;
    ## chained logger
    attr :chain, true ;  ## chained logger
    ## compress mode
    attr :compress, true ;  ## flag whether compress or not


    #--------------------------------------------------
    #++
    ## initialization with config
    def initialize(conf = {})
      super(conf) ;
      setup() ;
    end

    #--------------------------------------------------
    #++
    ## setup using config
    def setup()
      @append = getConf(:append) ;
      @tee = getConf(:tee) ;
      @file = getConf(:file) ;
      @compress = getConf(:compress) ;
      openFile(@file) if(@file) ;
      @stream = @stream || getConf(:stream) ;
      setLevel(getConf(:level)) ;
      @withLevel = getConf(:withLevel) ;
      @stream ;
    end

    #--------------------------------------------------
    #++
    ## open file
    # _file_ :: log file name
    # _mode_ :: open mode. one of nil, 'w', 'a','r'
    # *return* :: IO stream for the opened file.
    def openFile(file, mode=nil) # mode = nil | 'w' | 'a' | 'r'
      if(mode.nil?)
        mode = @appendp ? 'a' : 'w' ;
      end

      if(@tee) then
        newConf = @conf.dup.update({ :file => nil,
                                     :stream => @stream,
                                     :compress => false,
                                     :tee => false }) ;
        @chain = self.class.new(newConf) ;
      end

      @file = file ;

      if(@compress) then
        # check suffix of file
        fname = ((@file =~ /\.gz$/) ? @file : @file + ".gz") ;
        @stream = Zlib::GzipWriter.open(fname) ;
      else
        @stream = open(@file, mode) ;
      end
    end

    #--------------------------------------------------
    #++
    ## set log level
    # _level_ :: log level. one of {:debug, :info, :error, :fatal}
    # *return* :: the level.
    def setLevel(level)
      @chain.setLevel(level) if(@chain) ;
      if(level.is_a?(Numeric)) then
        @level = level ;
      elsif(level.is_a?(String))
        @level = Level[level.intern] ;
      elsif(level.is_a?(Symbol))
        @level = Level[level] ;
      else
        @level = nil ;
      end

      raise("unknown LogLevel:" + level.inspect) if (@level.nil?) ;

      return @level ;
    end

    #--------------------------------------------------
    #++
    ## set flag to specify log output with log level
    # _flag_ :: true or false.
    def setWithLevel(flag = true)
      @chain.setWithLevel(flag) if(@chain) ;
      @withLevel = flag ;
    end

    #--------------------------------------------------
    #++
    ## output message if level is higher than the current log level.
    # _level_ :: log level of this message.
    # _message_ :: an object to output for logging.
    def put(level,message)
      @chain.put(level,message) if(@chain) ;
      if(@stream && level >= @level)
        @stream << LevelName[level] << ": " if(@withLevel) ;
        loggingTo(@stream,message) ;
      end
    end

    #--------------------------------------------------
    #++
    ## close log file
    def close()
      @stream.close() if(@file) ;
    end

  end # class ExpLogger

  #--============================================================
  #++
  # class methods for ExpLogger
  class << ExpLogger
    extend ExpLogUtility ;
    include ExpLogUtility ;

    #--::::::::::::::::::::::::::::::::::::::::::::::::::
    #++
    ## logger instance
    Entity = ExpLogger.new() ;

    #--------------------------------------------------
    #++
    ## get logger instance
    # *return* :: the instance stored in ExpLogger::Entity
    def logger()
      Entity ;
    end

    #--------------------------------------------------
    #++
    ## open log file for the logger instance
    def openFile(file, mode = nil)
      logger().openFile(file,mode) ;
    end

    #--------------------------------------------------
    #++
    ## set level for the logger instance
    def setLevel(level)
      logger().setLevel(level) ;
    end

    #--------------------------------------------------
    #++
    ## set withLevel for the logger instance
    def setWithLevel(flag=true)
      logger().setWithLevel(flag) ;
    end

    #--------------------------------------------------
    #++
    ## output for the logger instance
    def put(level, message)
      logger().put(level, message) ;
    end

    #--------------------------------------------------
    #++
    ## close the log file.
    def close()
      logger().close() ;
    end

    #--------------------------------------------------
    #++
    ## execute something with a logger
    def withExpLogger(conf = {}, &block)
      _logger = ExpLogger.new(conf) ;
      begin
        block.call(_logger) ;
      ensure
        _logger.close() ;
      end
    end

    #--------------------------------------------------
    #++
    ## top level logger
    #--------------------------------------------------
    #++
    ## output message if level is higher than the current log level.
    # _level_ :: log level of this message.
    # _message_ :: an object to output for logging.
    def put(level,message)
      self.logger().put(level,message) ;
    end

  end # class << ExpLogger

  #--------------------------------------------------
  #++
  ## execute something with a logger (def for Itk module)
  def withExpLogger(conf = {}, &block)
    ExpLogger::withExpLogger(conf, &block) ;
  end

  extend Itk ;

end ## module Itk



######################################################################
######################################################################
######################################################################
if($0 == __FILE__) then
  require 'test/unit'

  ##============================================================
  class TC_WithExpLogger < Test::Unit::TestCase

    ##----------------------------------------
    def setup
      name = "#{(@method_name||@__name__)}(#{self.class.name})" ;
      puts ('*' * 5 ) + ' ' + [:run, name].inspect + ' ' + ('*' * 5) ;
      super
    end

    ##----------------------------------------
    def test_a()
      data = [:foo,
              [true, false, nil, :foo, Array],
              [1, 2.0, -3.4, 0x3],
              Time.now,
              {:a => [1,2,3], :c => Hash, :d => {1 => 2, "bar" => 'baz'}},
              Foo.new()] ;
      Itk::ExpLogUtility::loggingTo($stdout , data) ;
      str = "" ;
      Itk::ExpLogUtility::loggingTo(str, data) ;
      p str ;
      d = eval(str) ;
      p [:eval, d] ;
      Itk::ExpLogUtility::loggingTo($stdout, d) ;
    end

    class Foo
      def initialize()
        @bar = "" ;
        @baz = :abcde ;
        @foo = [1,2,3,4,5] ;
      end
    end

    ##----------------------------------------
    def test_b()
      test_b_sub() ;
      Itk::ExpLogger.setWithLevel() ;
      test_b_sub() ;
    end

    ##----------------------------------------
    def test_b_sub()
      Itk::ExpLogger << "foo" ;
      Itk::ExpLogger << [:a, "b", Foo.new(), {:a => 1, 2 => 3.1415, "3" => [1,2,3]}] ;
      [Itk::ExpLogger::LevelInfo, Itk::ExpLogger::LevelDebug,
       Itk::ExpLogger::LevelError, Itk::ExpLogger::LevelFatal].each{|lv|
        Itk::ExpLogger.setLevel(lv) ;
        Itk::ExpLogger.info([:info, [:level, lv]]) ;
        Itk::ExpLogger.debug([:info, [:level, lv]]) ;
        Itk::ExpLogger.error([:info, [:level, lv]]) ;
        Itk::ExpLogger.fatal([:info, [:level, lv]]) ;
      } ;
    end

    ##----------------------------------------
    def test_c()
      data = [:foo,
              [true, false, nil, :foo, Array],
              [1, 2.0, -3.4, 0x3],
              Time.now,
              {:a => [1,2,3], :c => Hash, :d => {1 => 2, "bar" => 'baz'}},
              Foo.new()] ;

      Itk::withExpLogger({ :file => "/tmp/#{File::basename($0)}.#{$$}.log",
                           :compress => false }) {|logger|
        logger << ["hogehoge", data] ;
        logger << ["hogehoge", data] ;
        logger << ["hogehoge", data] ;
      }
      Itk::withExpLogger({ :file => "/tmp/#{File::basename($0)}.#{$$}.log",
                           :compress => true }) {|logger|
        logger << ["hogehoge", data] ;
        logger << ["hogehoge", data] ;
        logger << ["hogehoge", data] ;
      }
    end

  end ##   class TC_WithExpLogger

end
