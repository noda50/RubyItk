#--------------------------------------------------------------------
# ridl.rb - main file for R2CORBA IDL compiler
#
# Author: Martin Corino
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the R2CORBA LICENSE which is
# included with this program.
#
# Copyright (c) Remedy IT Expertise BV
# Chamber of commerce Rotterdam nr.276339, The Netherlands
#--------------------------------------------------------------------
require 'ridl/require.rb'

IDL_VERSION_MAJOR = 0.freeze
IDL_VERSION_MINOR = 2.freeze
IDL_VERSION_RELEASE = 1.freeze
IDL_COPYRIGHT = 'Copyright (c) 2007-2008 Remedy IT Expertise BV, The Netherlands'.freeze

module IDL
  class RIDL
    private
    def RIDL.parse0(src, params)
      parser = ::IDL::Parser.new(params)
      s = ::IDL::StrOStream.new
      s.clear
      parser.add_walker(::IDL::RubyStubWriter.new(s, params)) if params[:client_stubs]
      parser.add_walker(::IDL::RubyServantWriter.new(s, params)) unless params[:stubs_only]
      parser.parse(src)
      s
    end
    def RIDL.parse(src, params)
      s = parse0(src, params)
      s.to_s
    end
    public
    def RIDL.eval(src, params={})
      params[:idl_eval] = true
      params[:expand_includes] = true
      params[:client_stubs] = true if params[:client_stubs].nil?
      params[:stubs_only] ||= false
      s = parse0(src, params)
      Kernel.eval(s.to_s, ::TOPLEVEL_BINDING)
      s = nil
    end
    def RIDL.fparse(fname, params = {})
      params[:client_stubs] = true if params[:client_stubs].nil?
      params[:stubs_only] ||= false
      f = File.open(fname, "r")
      self.parse(f, params)
    ensure
      f.close
    end
    def RIDL.feval(fname, params = {})
      File.open(fname, "r") { |io| self.eval(io, params) }
    end
  end

end

if File.basename($0) =~ /ridlc/

if ARGV[0] == '--preprocess'
  $IDL_PREPROCESS = true
  ARGV.shift
elsif ARGV[0] == '--ignore-pidl'
  $IDL_NOPIDL = true
  ARGV.shift
end

require 'optparse'

module IDL

  OPTIONS = {
      :output          => nil,
      :outputdir       => nil,
      :includepaths    => [],
      :verbose         => false,
      :expand_includes => false,
      :libinit         => true,
      :class_interfaces => [],
      :preprocess      => $IDL_PREPROCESS || false,
      :ignore_pidl     => $IDL_NOPIDL || false,
      :namespace       => nil,
      :stub_ext        => 'C.rb',
      :srv_ext         => 'S.rb',
      :stubs_only      => false,
      :client_stubs    => true,
      :search_incpath  => false
  }

  def IDL.run
    ARGV.options do |opts|
        script_name = File.basename($0, '.bat')
        if not script_name =~ /ridlc/
          script_name = "ruby "+$0
        end
        opts.banner = "Usage: #{script_name} [options] <idlfile>"

        opts.separator ""

        opts.on("-o FILE", "--output=FILE", String,
                "Specified filename to generate output in.",
                "Default: File.basename(idlfile, '.idl')+<ext>") { |OPTIONS[:output]| }
        opts.on("-s EXT", "--stub-ext=EXT", String,
                "Specifies extension for generated client stub source.",
                "Default: #{OPTIONS[:stub_ext]}") { |OPTIONS[:stub_ext]| }
        opts.on("-S EXT", "--servant-ext=EXT", String,
                "Specifies extension for generated servant source.",
                "Default: #{OPTIONS[:srv_ext]}") { |OPTIONS[:srv_ext]| }
        opts.on("-D PATH", "--directory=PATH", String,
                "Specified output directory.",
                "Default: ./") { |OPTIONS[:outputdir]| }
        opts.on("-I PATH", "--include=PATH", String,
                "Adds include searchpath.",
                "Default: nil") { |v| OPTIONS[:includepaths] << v }
        opts.on("-n NAMESPACE", "--namespace=NAMESPACE", String,
                "Defines rootlevel enclosing namespace.",
                "Default: nil") { |OPTIONS[:namespace]| }
        opts.on("-v", "--verbose",
                "Run verbose.",
                "Default: off") { |OPTIONS[:verbose]| }
        opts.on("--stubs-only",
                "Only generate client stubs, no servant code.",
                "Default: off") { |OPTIONS[:stubs_only]| OPTIONS[:client_stubs] = true }
        opts.on("--no-stubs",
                "Do not generate client stubs, only servant code.",
                "Default: off") { |OPTIONS[:client_stubs]| OPTIONS[:stubs_only] = false }
        opts.on("--expand-includes",
                "Generate code for included IDL inline.",
                "Default: off") { |OPTIONS[:expand_includes]| }
        opts.on("--no-libinit",
                "Do not generate library initialization code as preamble.",
                "Default: off") { |OPTIONS[:libinit]| }
        opts.on("--interface-as-class=INTF", String,
                "Generate a Ruby class for interface INTF instead of a module in client stubs.",
                "Default: module") { |v| OPTIONS[:class_interfaces] << v }
        opts.on("--search-includepath",
                "Use include paths to find main IDL source.",
                "Default: off") { |OPTIONS[:search_incpath]| }
        opts.on("--version",
                "Show version information and exit.") {
                    puts "Ruby2CORBA IDL compiler #{IDL_VERSION_MAJOR}.#{IDL_VERSION_MINOR}.#{IDL_VERSION_RELEASE}"
                    puts IDL_COPYRIGHT
                    exit
                }

        opts.separator ""

        opts.on("-h", "--help",
                "Show this help message.") { puts opts; puts; exit }

        opts.parse!
    end

    if ARGV.length>0
      OPTIONS[:idlfile] = ARGV[0]
      if OPTIONS[:search_incpath]
        _fname = ARGV[0]
        _fpath = if File.file?(_fname) && File.readable?(_fname)
          _fname
        else
          _fp = OPTIONS[:includepaths].find do |_p|
            _f = _p + "/" + _fname
            File.file?(_f) && File.readable?(_f)
          end
          OPTIONS[:outputdir] = _fp unless _fp.nil? || !OPTIONS[:outputdir].nil?
          _fp += '/' + _fname unless _fp.nil?
          _fp
        end
        ARGV[0] = _fpath unless _fpath.nil?
      end
      OPTIONS[:includepaths] << File.dirname(ARGV[0])
    end

    OPTIONS[:outputdir] ||= '.'

    if not ENV['TAO_ROOT'].nil?
      OPTIONS[:includepaths] << ENV['TAO_ROOT']
    elsif not ENV['ACE_ROOT'].nil?
      OPTIONS[:includepaths] << ENV['ACE_ROOT']+'/TAO'
    end

    if OPTIONS[:preprocess]
      ## PREPROCESSING
      o = if OPTIONS[:output].nil?
          $stdout
        else
          File.open(OPTIONS[:output], "w+")
        end
      OPTIONS[:output] = o

      parser = ::IDL::Parser.new(OPTIONS)
      parser.yydebug = OPTIONS[:verbose]

      begin
        parser.parse("#include \"#{ARGV[0]}\"")
      rescue => ex
        p ex
        puts ex.backtrace.join("\n") unless ex.is_a? IDL::ParseError
      ensure
        o.close
      end
    else
      ## CODE GENERATION
      file = if ARGV.length == 0
          $stdin
        else
          File.open(ARGV[0], "r")
        end
      raise RuntimeError, 'cannot read from STDOUT' if $stdout == file

      fixed_output = !OPTIONS[:output].nil?
      if !fixed_output && ARGV.length > 0
        OPTIONS[:output] = OPTIONS[:outputdir]+'/'+File.basename(ARGV[0], '.idl')+OPTIONS[:stub_ext]
      end
      co = nil
      if OPTIONS[:client_stubs]
        co = if OPTIONS[:output].nil?
            $stdout
          else
            File.open(OPTIONS[:output], "w+")
          end
      end

      so = nil
      if !OPTIONS[:stubs_only]
        so = if !fixed_output && ARGV.length == 0
            $stdout
          else
            OPTIONS[:srv_output] = if fixed_output
                OPTIONS[:output]
              else
                OPTIONS[:outputdir]+'/'+File.basename(ARGV[0], '.idl')+OPTIONS[:srv_ext]
              end
            if fixed_output && OPTIONS[:client_stubs]
              co
            else
              File.open(OPTIONS[:srv_output], "w+")
            end
          end
      end

      parser = ::IDL::Parser.new(OPTIONS)
      parser.yydebug = OPTIONS[:verbose]

      parser.add_walker(::IDL::RubyStubWriter.new(co, OPTIONS)) if OPTIONS[:client_stubs]
      parser.add_walker(::IDL::RubyServantWriter.new(so, OPTIONS)) unless OPTIONS[:stubs_only]

      begin
        parser.parse(file)
      rescue => ex
        p ex
        puts ex.backtrace.join("\n") unless ex.is_a? IDL::ParseError
      ensure
        co.close unless co.nil?
        so.close unless so.nil? || so == co
        file.close
      end
    end
  end

end

end

if __FILE__ == $0

  IDL.run

end
