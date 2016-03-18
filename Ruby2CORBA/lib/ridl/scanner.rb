#--------------------------------------------------------------------
# scanner.rb - IDL scanner
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
require 'racc/parser'

module IDL
  class ParseError < StandardError
    attr_reader :positions
    def initialize(msg, positions)
      super(msg)
      @positions = positions
    end
    def inspect
      puts self.class.name+": "+message
      @positions.each { |pos|
        print "    "
        puts pos
      }
      nil
    end
  end

  class Scanner
    Position = Struct.new(nil, :name, :line, :column)

    class Position
      def to_s
        format("%s: line %d, column %d", name.to_s, line, column)
      end
      def inspect
        to_s
      end
    end

    class In
      def initialize(src, name = '', line = 0, column = 1)
        @src, @fwd, @bwd = src, src.getc, nil
        @pos = Position.new(name, line, column)
        @mark = nil
      end
      def position
        @pos
      end
      def column
        @pos.column
      end
      # cursor set at last gotten character.
      # ex: after initialization, position is (0,0).
      def to_s; @src.to_s; end

      def lookc
        @fwd
      end

      def getc
        cur = @fwd
        @fwd = @src.getc unless @src.nil?
        @mark << cur unless @mark.nil?
        if [nil, ?\n, ?\r].include? @bwd
          if @bwd == ?\r and cur == ?\n
          else
            @pos.line += 1
            @pos.column = 1
          end
              else
          @pos.column += 1
        end

        if false
          if not @bwd.nil? or cur.nil? or @fwd.nil?
          printf("%c(%02x), %c(%02x), %c(%02x) @(l:%d,c:%d)\n",
                @bwd,@bwd,cur,cur,@fwd,@fwd, @pos.line, @pos.column)
          end
        end
        @bwd = cur
      end

      def gets
        return nil if @fwd.nil?
        
        s = ""
        s << getc until [nil, ?\n, ?\r].include? lookc
        s << getc while [?\n, ?\r].include? lookc

        @mark << s unless @mark.nil?
        s
      end
      alias skipc getc

      def _include?(ch, *chars)
        chars.each { |v|
          return TRUE if case v
            when Array
              _include?(ch, *v)
            when Enumerable
              v.include? ch
            when Fixnum
              v == ch
            else
              false
            end
        }
        return FALSE
      end

      def skipwhile(*chars, &block)
        if block.nil?
          block = Proc.new { |ch| _include?(ch, *chars) }
        end

        until (ch = lookc).nil?
          break unless block.call(ch)
          skipc
        end
        ch
      end

      def skipuntil(*chars, &block)
        if block.nil?
          block = Proc.new { |ch| _include?(ch, *chars) }
        end

        until (ch = lookc).nil?
          break if block.call(ch)
          skipc
        end
        ch
      end

      def mark(*ini)
        @mark = ""
        ini.each { |i|
          case i
          when nil
          when String
            @mark << i.dup
          when Fixnum
            @mark << i
          when Array
            i.each { |j| @mark << j } # array of array is not incoming.
          end
        }
      end
      
      def getregion
        ret = @mark
        @mark = nil
        return ret
      end
    end

    class StrIStream
      def initialize(src)
        @src = src
        @i = 0
      end
      def to_s
        @src
      end
      def getc
        ch = @src[@i]
        @i += 1
        ch
      end
      def close
        @i = 0
      end
    end #of class StrIStream

    # Scanner
    def initialize(src, directiver, params = {})
      @includepaths = params[:includepaths] || []
      @stack = []
      @expansions = []
      @prefix = nil
      @directiver = directiver
      @defined = Hash.new
      @ifdef = Array.new
      @elsif = false
      i = nil
      nm = ''
      case src
      when String
        i = StrIStream.new(src)
      when File
        i = src
        nm = src.path
      when IO
        i = src
      else
        parse_error "illegale type for input source: #{src.type} "
      end
      @in = In.new(i, nm)
    end
    def find_include(fname)
      path = if File.file?(fname) && File.readable?(fname)
        fname
      else
        fp = @includepaths.find do |p|
          f = p + "/" + fname
          File.file?(f) && File.readable?(f)
        end
        fp += '/' + fname if !fp.nil?
        fp
      end
    end
    def enter_include(src)
      if @directiver.is_included?(src)
        @directiver.declare_include(src)
      else
        @stack << [:include, @prefix, @ifdef, @in, @elsif]
        fpath = find_include(src)
        if fpath.nil?
          parse_error "Cannot open include file '#{src}'"
        end
        @prefix = nil
        @ifdef = Array.new
        @in = In.new(File.open(fpath, 'r'), fpath)
        @directiver.enter_include(src)
        @directiver.pragma_prefix(nil)
      end
    end
    def enter_expansion(src, define)
      @stack << [:define, nil, nil, @in, nil]
      @expansions << define
      @in = In.new(StrIStream.new(src), @in.position.name, @in.position.line, @in.position.column)
    end
    def is_expanded?(define)
      @expansions.include?(define)
    end
    def more_source?
      @stack.size>0
    end
    def in_expansion?
      more_source? and @stack.last[0] == :define
    end
    def leave_source()
      if @stack.size>0
        if @stack.last[0] == :include
          @directiver.leave_include
          type, @prefix, @ifdef, @in, @elsif = @stack.pop
          @directiver.pragma_prefix(@prefix)
        else
          type, prefix_, ifdef_, @in, elsif_ = @stack.pop
          @expansions.pop
        end
      end
    end
    def do_parse?
      @ifdef.size == 0 or @ifdef[@ifdef.length - 1]
    end
    def positions
      @stack.collect {|type_,pfx_,ifdef_,in_,elsif_| in_.position }
    end
    def parse_error(msg, ex = nil)
      e = IDL::ParseError.new(msg, positions)
      e.set_backtrace(ex.backtrace) unless ex.nil?
      raise e
    end

    def resolve_define(id, stack = [])
      if @defined.has_key?(id)
        define_ = @defined[id]
        stack << id
        stack.include?(define_) ? nil : resolve_define(define_, stack)
      else
        id
      end
    end

    ESCTBL = {
      ?n => ?\n, ?t => ?\t, ?v => ?\v, ?b => ?\b,
      ?r => ?\r, ?f => ?\f, ?a => ?\a
    }

    KEYWORDS = [ # see 3.2.4 "Keywords" of CORBA V2.3 specification
      "abstract",  "double",    "long",    "readonly",   "typeid",
      "any",       "enum",      "module",  "sequence",   "typeprefix",
      "attribute", "exception", "native",  "short",      "unsigned",
      "boolean",   "factory",   "Object",  "string",     "union",
      "case",      "FALSE",     "octet",   "struct",     "ValueBase",
      "char",      "fixed",     "oneway",  "supports",   "valuetype",
      "const",     "float",     "out",     "switch",     "void",
      "context",   "in",        "private", "TRUE",       "wchar",
      "custom",    "inout",     "public",  "truncatable","wstring",
      "default",   "interface", "raises",  "typedef",    "local",
    ].collect! { |a| [a.downcase, a] }

    RUBYKW = [
    '__FILE__', 'and',    'def',      'end',    'in',     'or',     'self',   'unless',
    '__LINE__', 'begin',  'defined?', 'ensure', 'module', 'redo',   'super',  'until',
    'BEGIN',    'break',  'do',       'false',  'next',   'rescue', 'then',   'when',
    'END',      'case',   'else',     'for',    'nil',    'retry',  'true',   'while',
    'alias',    'class',  'elsif',    'if',     'not',    'return', 'undef',  'yield',
    ]

    def next_identifier(first = nil)
      @in.mark(first)
      while TRUE
        case @in.lookc
        when nil
          break
        when ?0..?9, ?a..?z, ?A..?Z, ?_
          @in.skipc
        else
          break
        end
      end
      s0 = @in.getregion
      s1 = s0.downcase

      # simple check
      if (s0.length == 0)
        parse_error "identifier expected!"
      else
        case s0[0]
        when ?a..?z, ?A..?Z
        when ?_   ## if starts with CORBA IDL escape => remove
          s0.slice!(0)
          #s1.slice!(0)
        else
          parse_error "identifier must begin with alphabet character: #{s0}"
        end
      end

      # preprocessor check
      if @defined.has_key?(s0) and !is_expanded?(s0)
        # enter expansion as new source
        enter_expansion(@defined[s0], s0)
        # call next_token to parse expanded source
        next_token
      # keyword check
      elsif (a = KEYWORDS.assoc(s1)).nil?
        [ :identifier,
          if RUBYKW.include?(s0)
            'r_'+s0   # prefix Ruby keywords with 'r_'
          else
            s0
          end
        ]
      elsif s0 == a[1]
        [ a[1], a[2] ]
      else
        parse_error "`#{s0}' collides with a keyword `#{a[1]}'"
      end
    end

    def next_escape
      ret = 0
      case (ch = @in.getc)
      when nil
        ret = 0
      when ?0..?7
        ret = ch - ?0
        1.upto(2) {
          ch = @in.lookc
          break if ch.nil? or !((?0..?7) === ch)
          ret = ret * 8 + (ch - ?0)
          @in.skipc
        }
      when ?x # i'm not sure '\x' should be 0 or 'x'. currently returns 0.
        ret = 0
        1.upto(2) {
          case ch = @in.lookc
          when ?0..?9
            ret = ret * 16 + (ch - ?0)
          when ?a..?f
            ret = ret * 16 + (10 + ch - ?a)
          when ?A..?F
            ret = ret * 16 + (10 + ch - ?A)
          else
            break
          end
          @in.skipc
        }
      when ?u
        ret = ""
        1.upto(4) {
          case ch = @in.lookc
          when ?0..?9, ?a..?f, ?A..?F
            ret << ch
          else
            break
          end
          @in.skipc
        }
        ret = ret.hex
      when ?n, ?t, ?v, ?b, ?r, ?f, ?a
        ret = ESCTBL[ch]
      else
        ret = ch
      end
      return ret
    end

    def skipfloat
      if (@in.lookc == ?.)
        @in.skipc
        @in.skipwhile(?0..?9)
      end
      if [?e, ?E].include? @in.lookc
        @in.skipc
        @in.skipc if [?+, ?-].include? @in.lookc
        @in.skipwhile(?0..?9)
      end
    end

    def getline
      s = ""
      while TRUE
        s << @in.gets
        until s.chomp!.nil?; end
        break unless s[s.length - 1] == ?\\
        s.chop!
      end
      s
    end

    def parse_directive
      @in.skipwhile(?\ , ?\t)
      s = getline
      /^(\w*)\s*/ === s
      s1,s2 = $1, $' #'

      if /(else|endif|elif)/ === s1
        if @ifdef.size == 0
          parse_error "#else/#elif/#endif must not appear without preceding #if"
        end
        case s1
        when "else"
          if @elsif
            @ifdef[@ifdef.size - 1] = false
          else
            @ifdef[@ifdef.size - 1] ^= true;
          end
        when "endif"
          @ifdef.pop
          @elsif = false
        else
          if @elsif
            @ifdef[@ifdef.size - 1] = false
          else
            if not @ifdef[@ifdef.size - 1]
              while s2 =~ /[^\w]defined\s*\(\s*(\w+)\s*\)/
                def_id = $1
                s2.gsub!(/[^\w]defined\s*\(\s*(\w+)\s*\)/, " #{@defined.has_key?(def_id).to_s} ")
              end
              @ifdef[@ifdef.size - 1] = eval(s2)
              @elsif = @ifdef[@ifdef.size - 1]
            end
          end
        end

      elsif do_parse?
        case s1
        when "pragma"
          parse_pragma(s2)

        when "define"
          a = s2.split
          a[1] = true if a[1].nil?
          if a[0].nil?
            parse_error "no #define target."
          elsif not @defined[a[0]].nil?
            parse_error "#{a[0]} is already #define-d."
          end
          @defined[a[0]] = a[1]

        when "undef"
          @defined.delete(s2)

        when /ifn?def/
          if not (/^(\w+)/ === s2)
            parse_error "no #ifdef target."
          end
          @ifdef.push(@defined[$1].nil? ^ (s1 == "ifdef"))

        when "elif"
          if @ifdef.size == 0
            parse_error "#elif must not appear without preceding #if"
          end
          @ifdef[@ifdef.size - 1] ^= true;
          while s2 =~ /[^\w]defined\s*\(\s*(\w+)\s*\)/
             def_id = $1
             s2.gsub!(/[^\w]defined\s*\(\s*(\w+)\s*\)/, " #{@defined.has_key?(def_id).to_s} ")
          end

        when "if"
          while s2 =~ /(^|[\W])defined\s*\(\s*(\w+)\s*\)/
             def_id = $1
             s2.gsub!(/(^|[\W])(defined\s*\(\s*\w+\s*\))/, '\1'+"#{@defined.has_key?(def_id).to_s}")
          end
          if s2 =~ /[A-Za-z_][\w]*/
            s2.gsub!(/[A-Za-z_][\w]*/) do |id_| resolve_define(id_) end
          end
          begin
            @ifdef.push(eval(s2))
          rescue => ex
            p ex
            puts ex.backtrace.join("\n")
            parse_error "error evaluating #if"
          end

        when "include"
          if s2[0] == ?" || s2[0]==?<
            if s2.size>2
              s2.strip!
              s2 = s2.slice(1..(s2.size-2))
            else
              s2 = ""
            end
          end
          enter_include(s2)

        when /[0-9]+/
          # ignore line directive
        else
          parse_error "unknown directive: #{s}."
        end
      end
    end

    def parse_pragma(s)
      case s
      when /^ID\s+(.*)\s+"(.*)"\s*$/
        @directiver.pragma_id($1, $2)
      when /^version\s+(.*)\s+([0-9]+)\.([0-9]+)\s*$/
        @directiver.pragma_version($1, $2, $3)
      when /^prefix\s+"(.*)"\s*$/
        @prefix = $1
        @directiver.pragma_prefix(@prefix)
      else
        parse_error "unknown pragma: #{s}."
      end
    end

    def next_token
      sign = nil
      str = " " #initialize size 1 string
      while TRUE
        ch = @in.getc
        if ch.nil?
          if @ifdef.size>0 and !in_expansion?
            parse_error "mismatched #if/#endif"
          end
          if more_source?
            leave_source
            next
          else
            return [FALSE, nil]
          end
        end
        
        linefirst = (@in.column == 1)
        if [?\ , ?\t].include? ch
          @in.skipwhile( ?\ , ?\t )
          next
        end

        if linefirst
          if ch == ?\#
            parse_directive
            next
          end
        end
        if not do_parse?
          getline
          next
        end

        str[0] = ch
        case ch
        when ?\ , ?\t
          @in.skipwhile( ?\ , ?\t )
          next
    
        when ?\n, ?\r
          @in.skipwhile( ?\n, ?\r )
          next

        when ?(, ?), ?[, ?], ?{, ?},
            ?^, ?~,
            ?*, ?%, ?&, ?|,
            ?<, ?=, ?>,
            ?,, ?;
          return [str, str]

        when ?: #
          if @in.lookc == ?: #
            @in.skipc
            return ["::", "::"]
          else
            return [":", ":"]
          end

        when ?L
          case @in.lookc
          when ?\'  #' #single quote, for a character literal.
            ret = 0
            @in.skipc # skip 'L'
            case @in.lookc
            when ?\\
              @in.skipc
              ret = next_escape
            when ?\' #'
              ret = 0
            else
              ret = @in.getc
            end

            if @in.lookc != ?\' #'
              parse_error "wide character literal must be closed with \"'\""
            end

            @in.skipc
            return [ :wide_character_literal, ret ]

          when ?\" #" #double quote, for a string literal.
            ret = []
            @in.skipc # skip 'L'
            while TRUE
              case @in.lookc
              when ?\\
                @in.skipc
                ret << next_escape
              when ?\" #"
                @in.skipc
                return [ :wide_string_literal, ret ]
              else
                ret << @in.getc
              end
            end

          else
            return next_identifier(ch)
          end

        when ?_, ?a..?z, ?A..?Z
          return next_identifier(ch)

        when ?/ #
          case @in.lookc
          when ?*  # skip comment like a `/* ... */'
            @in.skipc # forward cursor next to `/*'
            ch1 = nil
            @in.skipuntil { |ch|
              ch0 = ch1; ch1 = ch
              ch0 == ?* and ch1 == ?/ #
            }
            if @in.lookc.nil?
              parse_error "cannot found comment closing brase(\`*/\'). "
            end
            @in.skipc
            next

          when ?/ # skip comment like a `// ...\n'
            @in.skipc
            @in.skipuntil(?\n, ?\r)
            next
      
          else
            return [ "/", "/" ]
          end

        when ?+, ?-
          case @in.lookc
          when nil
            return [str, str]
          when ?0..?9
            sign = ch
            next
          else
            return [str, str]
          end

        when ?1..?9
          @in.mark(sign, ch)
          sign = nil
          @in.skipwhile(?0..?9)
          skipfloat if (isfloat = [?., ?e, ?E].include? @in.lookc)
          
          r = nil
          if [?d, ?D].include? @in.lookc
            parse_error "fixed-point's not been supported yet."
          else
            r = @in.getregion
          end

          if isfloat
            return [:floating_pt_literal, r.to_f]
          else
            return [:integer_literal, r.to_i]
          end

        when ?. #
          @in.mark(ch)
          @in.skipwhile(?0..?9)
          skipfloat if [?e, ?E].include? @in.lookc
          if [?d, ?D].include? @in.lookc
            parse_error "fixed-point's not been supported yet."
          else
            s = @in.getregion
            if s == "."
              parse_error "token consists of only one dot(.) is invalid."
            end
            ret = s.to_f
          end
          return [:floating_pt_literal, ret]

        when ?0
          @in.mark(sign, ch)
          sign = nil

          case @in.lookc
          when ?x, ?X
            @in.skipc
            @in.skipwhile(?0..?9, ?a..?f, ?A..?F)
            s = @in.getregion
            return [:integer_literal, s.hex]

          else
            dec = FALSE
            float = FALSE
            @in.skipwhile(?0..?7)
            if (?8..?9).include? @in.lookc
              dec = TRUE
              @in.skipwhile(?0..?9)
            end

            if [?., ?e, ?E].include? @in.lookc
              float = TRUE
              skipfloat
            end
            if [?d, ?D].include? @in.lookc
                parse_error "fixed-point's not been supported yet."
            end

            ret = nil
            s = @in.getregion
            if float
              ret = [:floating_pt_literal, s.to_f]
            elsif dec
              parse_error "literal starts with `0' is octal: #{s}"
            else
              ret = [:integer_literal, s.oct]
            end
            return ret
          end

        when ?\'  #' #single quote, for a character literal.
          ret = 0
          case @in.lookc
          when ?\\
            @in.skipc
            ret = next_escape
          when ?\' #'
            ret = 0
          else
            ret = @in.getc
          end

          if @in.lookc != ?\' #'
            parse_error "character literal must be closed with \"'\""
          end

          @in.skipc
          return [ :character_literal, ret ]

        when ?\" #" #double quote, for a string literal.
          ret = ""
          while TRUE
            case @in.lookc
            when ?\\
              @in.skipc
              ret << next_escape
            when ?\" #"
              @in.skipc
              return [ :string_literal, ret ]
            else
              ret << @in.getc
            end
          end

        else
          parse_error format("illegal character `%c'", ch)

        end #of case

      end #of while
      parse_error "unexcepted error"
    end #of method next_token
  end

end
