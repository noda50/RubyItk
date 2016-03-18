#--------------------------------------------------------------------
# node.rb - IDL nodes
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
module IDL
  RESERVED_RUBY_CONST = [
    'Array', 'Bignum', 'Binding', 'Class', 'Continuation', 'Dir', 'Exception',
    'FalseClass', 'File', 'Fixnum', 'Float', 'Hash', 'Integer', 'IO', 'MatchData',
    'Method', 'Module', 'NilClass', 'Numeric', 'Object', 'Proc', 'Process', 'Range',
    'Regexp', 'String', 'Struct', 'Symbol', 'Thread', 'ThreadGroup', 'Time', 'TrueClass',
    'UnboundMethod', 'Comparable', 'Enumerable', 'Errno', 'FileTest', 'GC', 'Kernel',
    'Marshal', 'Math', 'ObjectSpace', 'Signal'
  ]

  RESERVED_RUBY_MEMBER = [
    "untaint", "id", "instance_variable_get", "inspect", "taint", "public_methods", "__send__", "to_a", "display", "instance_eval",
    "extend", "clone", "protected_methods", "hash", "freeze", "type", "instance_variable_set", "methods", "instance_variables", "to_s", "method", "dup",
    "private_methods", "object_id", "send", "__id__", "singleton_methods",
    "proc", "readline", "global_variables", "singleton_method_removed", "callcc", "syscall", "fail", "untrace_var", "load", "srand", "puts", "catch", "chomp",
    "initialize_copy", "format", "scan", "print", "abort", "fork", "gsub", "trap", "test", "select", "initialize", "method_missing", "lambda", "readlines",
    "local_variables", "singleton_method_undefined", "system", "open", "caller", "eval", "set_trace_func", "require", "rand", "singleton_method_added",
    "throw", "gets", "binding", "raise", "warn", "getc", "exec", "trace_var", "irb_binding", "at_exit", "split", "putc", "loop", "chop", "sprintf", "p",
    "remove_instance_variable", "exit", "printf", "sleep", "sub", "autoload"
  ]

  class Leaf
    attr_reader :name, :intern
    attr_reader :rubyname, :scoped_rubyname
    attr_accessor :enclosure
    attr_reader :scoped_name
    attr_reader :scopes
    attr_accessor :prefix

    def typename
      self.class.name
    end
    def Leaf.mk_rubyname(nm, is_scoped)
      ret = nm.dup
      case self::RUBYNAMETYPE
      when "const"
        ret[0] = ret[0] - ?a + ?A if (?a..?z).include? ret[0]
        ret = 'R_'+ret if !is_scoped && RESERVED_RUBY_CONST.include?(ret)
      when "variable"
        ret[0] = ret[0] - ?A + ?a if (?A..?Z).include? ret[0]
        ret = 'r_'+ret if RESERVED_RUBY_MEMBER.include?(ret)
      else
        raise RuntimeError,
          "invalid RUBYNAMETYPE of #{self.to_s}: #{self::RUBYNAMETYPE}"
      end
      ret
    end
    def initialize(_name, _enclosure)
      @name = _name || ""
      @rubyname = self.class.mk_rubyname(@name, _enclosure.nil? ? false : _enclosure.scopes.size>0 )
      @intern = (_name || " ").downcase.intern
      @enclosure = _enclosure

      @scopes = if @enclosure.nil? then [] else @enclosure.scopes + [self] end
      ##@scoped_name = "::" + @scopes.collect{|s| s.name}.join("::")
      ##@scoped_rubyname = "::" + @scopes.collect{|s| s.rubyname}.join("::")
      @scoped_name = @scopes.collect{|s| s.name}.join("::")
      @scoped_rubyname = @scopes.collect{|s| s.rubyname}.join("::")
      @prefix = nil
      @repo_id = nil
      @repo_ver = nil
    end

    def marshal_dump
      [@name, @rubyname, @intern, @scopes, @scoped_name, @scoped_rubyname, @prefix, @repo_id, @repo_ver]
    end

    def marshal_load(vars)
      @name, @rubyname, @intern, @scopes, @scoped_name, @scoped_rubyname, @prefix, @repo_id, @repo_ver = vars
    end

    def set_repo_id(id)
      if not @repo_id.nil?
        if id != @repo_id
          raise RuntimeError,
            "#{self.scoped_name} already has a different repository ID assigned: #{@repo_id}"
        end
      end
      if not @repo_ver.nil?
        l = id.split(':')
        if l.last != @repo_ver
          raise RuntimeError,
            "supplied repository ID (#{id}) does not match previously assigned repository version for #{self.scoped_name} = #{@repo_ver}"
        end
      end
      @repo_id = id
    end

    def set_repo_version(ma, mi)
      ver = "#{ma}.#{mi}"
      if not @repo_ver.nil?
        if ver != @repo_ver
          raise RuntimeError,
            "#{self.scoped_name} already has a repository version assigned: #{@repo_ver}"
        end
      end
      if not @repo_id.nil?
        l = @repo_id.split(':')
        if l.last != ver
          raise RuntimeError,
            "supplied repository version (#{ver}) does not match previously assigned repository ID for #{self.scoped_name}: #{@repo_id}"
        end
      end
      @repo_ver = ver
    end

    def replace_prefix(pfx)
      @prefix = pfx
    end

    def repository_id
      if @repo_id.nil?
        @repo_ver = "1.0" if @repo_ver.nil?
        format("IDL:%s%s:%s",
                if @prefix.nil? then "" else @prefix+"/" end,
                scopes.collect{|s| s.name}.join("/"),
                @repo_ver)
      else
        @repo_id
      end
    end
  end

  class Node < Leaf
    def initialize(name, enclosure)
      super
      @introduced = Hash.new
      @children = []
    end

    def marshal_dump
      super() << @children << @introduced
    end

    def marshal_load(vars)
      @introduced = vars.pop
      @children = vars.pop
      super(vars)
    end

    def introduce(node)
      n = @introduced[node.intern]
      if n.nil?
        @introduced[node.intern] = node
      elsif n != node
        raise RuntimeError,
          "#{node.name} is already introduced as a #{n.scoped_name} of #{n.typename}."
      end
    end
    def undo_introduction(node)
      n = @introduced[node.intern]
      if !n.nil?
        @introduced.delete(node.intern)
      end
    end
    def redefine(node, params)
      raise RuntimeError, "\"#{node.name}\" is already defined."
    end
    def is_definable?(_type)
      not self.class::DEFINABLE.detect do |target|
        _type.ancestors.include? target
      end.nil?
    end
    def define(_type, _name, params = Hash.new)
      if not is_definable?(_type)
        raise RuntimeError,
          "#{_type.to_s} is not definable in #{self.typename}."
      end
      node = search_self(_name)
      if node.nil?
        node = _type.new(_name, self, params)
        node.prefix = @prefix
        introduce(node)
        @children << node
      else
        if _type != node.class
          raise RuntimeError,
            "#{_name} is already defined as a type of #{node.typename}"
        end
        node = redefine(node, params)
      end
      node
    end
    def resolve(_name)
      node = search_enclosure(_name)
      @introduced[node.intern] = node unless node.nil?
      node
    end

    def walk_members(&block)
      @children.each { |c| yield(c) }
    end

    def replace_prefix(pfx)
      @prefix = pfx
      walk_members { |m| m.replace_prefix(pfx) }
    end

    protected
    def search_self(_name)
      key = _name.downcase.intern
      node = @introduced[key]
      if not node.nil? and node.name != _name
        raise RuntimeError, "\"#{_name}\" clashed with \"#{node.name}\"."
      end
      node
    end
    def search_enclosure(_name)
      node = search_self(_name)
      if node.nil? and not @enclosure.nil?
        node = @enclosure.search_enclosure(_name)
      end
      node
    end
  end

  class Module < Node; end
  class Include < Module; end
  class Interface < Node; end
  class Valuetype < Node; end
  class Typedef < Leaf; end
  class Const < Leaf; end
  class Operation < Node; end
  class Attribute < Leaf; end
  class Parameter < Leaf; end
  class Struct < Node; end
  class Member < Leaf; end
  class Union < Node; end
  class UnionMember < Member; end
  class Enum < Leaf; end

  class Module < Node
    RUBYNAMETYPE = "const"
    DEFINABLE = [
      IDL::Module, IDL::Interface, IDL::Valuetype, IDL::Const, IDL::Struct,
      IDL::Union, IDL::Enum, IDL::Typedef, IDL::Include
    ]
    attr_reader :anchor
    def initialize(_name, _enclosure, params)
      super(_name, _enclosure)
      introduce(self)
      @anchor = params[:anchor]
      @next = nil
    end
    def is_anchor?
      @anchor.nil?
    end
    def marshal_dump
      super() << @anchor << @next
    end

    def marshal_load(vars)
      @next = vars.pop
      @anchor = vars.pop
      super(vars)
    end
    def redefine(node, params)
      case node
      when IDL::Include
        if node.enclosure == self
          return node
        else
          _inc = IDL::Include.new(node.name, self, params)
          @children << _inc
          return _inc
        end
      when IDL::Module
        if node.enclosure == self
          return node
        else
          _anchor = node.is_anchor? ? node : node.anchor
          _last = _anchor.find_last
          _params = { :anchor => _anchor }
          _next = IDL::Module.new(node.name, self, _params)
          _next.prefix = node.prefix
          _last.set_next(_next)
          @children << _next
          return _next
        end
      when IDL::Interface
        if params[:forward]
          @children << node
          return node
        elsif node.is_forward?
          if (node.is_abstract? != params[:abstract]) || (node.is_local? != params[:local])
            raise RuntimeError, "\"attributes are not a same: \"#{node.name}\"."
          end

          _intf = IDL::Interface.new(node.name, self, params)
          _intf.prefix = node.prefix
          @children << _intf
          # replace forward node registration
          node.enclosure.undo_introduction(node)
          @introduced[_intf.intern] = _intf 

          return _intf
        end
      when IDL::Struct, IDL::Union
        if node.is_defined?
          raise StandardError, "#{node.typename} \"#{node.name}\" is already defined."
        end
        node.switchtype = params[:switchtype] if node.is_a? IDL::Union
        # reposition childnode
        @children.delete(node)
        @children << node
        return node
      end
      raise RuntimeError,
	           "#{node.name} is already introduced as #{node.typename} #{node.scoped_name}."
    end

    def replace_prefix(pfx)
      if @anchor.nil?
        self.replace_prefix_(pfx)
      else
        @anchor.replace_prefix_(pfx)
      end
    end

    protected
    def replace_prefix_(pfx)
      @prefix = pfx
      walk_members { |m| m.replace_prefix(pfx) }
      @next.replace_prefix_(pfx) unless @next.nil?
    end
    def search_self(_name)
      if @anchor.nil?
        node = self.search_links(_name)
      else
        node = @anchor.search_links(_name)
      end
      node
    end
    def search_links(_name)
      _key = _name.downcase.intern
      node = @introduced[_key]
      if not node.nil? and node.name != _name
        raise RuntimeError, "\"#{_name}\" clashed with \"#{node.name}\"."
      end
      if node.nil? and not @next.nil?
        node = @next.search_links(_name)
      end
      node
    end
    def set_next(mod)
      @next = mod
    end
    def find_last
      if @next.nil?
        self
      else
        @next.find_last
      end
    end
  end

  class Include < Module
    attr_reader :filename
    def initialize(_name, _enclosure, params)
      super(_name, _enclosure, params)
      @filename = params[:filename]
      @defined = params[:defined] || false
      @preprocessed = params[:preprocessed] || false
      #overrule
      @scopes = @enclosure.scopes
      @scoped_name = @scopes.collect{|s| s.name}.join("::")
      @scoped_rubyname = @scopes.collect{|s| s.rubyname}.join("::")
    end
    def marshal_dump
      super() << @filename << @defined << @preprocessed
    end

    def marshal_load(vars)
      @preprocessed = vars.pop
      @defined = vars.pop
      @filename = vars.pop
      super(vars)
    end

    def is_defined?; @defined; end
    def is_preprocessed?; @preprocessed; end

    def introduce(node)
      @enclosure.introduce(node) unless node == self
    end
    def resolve(_name)
      @enclosure.resolve(_name)
    end
    protected
    def search_self(_name)
      @enclosure.search_self(_name)
    end
  end

  class Interface < Node
    RUBYNAMETYPE = "const"
    DEFINABLE = [IDL::Include, IDL::Const, IDL::Operation, IDL::Attribute,
                 IDL::Struct, IDL::Union, IDL::Typedef, IDL::Enum]
    attr_reader :bases
    attr_reader :idltype

    def initialize(_name, _enclosure, params)
      super(_name, _enclosure)
      @bases = []
      @defined = !params[:forward]
      @abstract = params[:abstract]
      @local = params[:local]
      add_bases(params[:inherits] || [])
      @idltype = IDL::Type::Interface.new(self)
    end
    def marshal_dump
      super() << @bases << @defined << @abstract << @local << @idltype
    end

    def marshal_load(vars)
      @idltype = vars.pop
      @local = vars.pop
      @abstract = vars.pop
      @defined = vars.pop
      @bases = vars.pop
      super(vars)
    end
    def is_abstract?; @abstract; end
    def is_local?; @local; end
    def is_defined?; @defined; end
    def is_forward?; not @defined; end

    def add_bases(inherits_)
      inherits_.each do |tc|
        if not (tc.is_a?(IDL::Type::ScopedName) && tc.node.is_a?(IDL::Interface))
          raise RuntimeError,
                "invalid inheritance identifier for #{typename} #{scoped_rubyname}: #{tc.typename}"
        end
        if tc.node.has_ancestor?(self)
          raise RuntimeError,
                "circular inheritance detected for #{typename} #{scoped_rubyname}: #{tc.node.scoped_rubyname} is descendant"
        end
        if not tc.node.is_defined?
          raise RuntimeError,
                "#{typename} #{scoped_rubyname} cannot inherit from forward declared #{tc.node.typename} #{tc.node.scoped_rubyname}"
        end
        if tc.node.is_local? and not self.is_local?
          raise RuntimeError,
                "#{typename} #{scoped_rubyname} cannot inherit from 'local' #{tc.node.typename} #{tc.node.scoped_rubyname}"
        end
        if self.is_abstract? and not tc.node.is_abstract?
          raise RuntimeError,
                "'abstract' #{typename} #{scoped_rubyname} cannot inherit from non-'abstract' #{tc.node.typename} #{tc.node.scoped_rubyname}"
        end
        @bases << tc.node
      end
    end

    def has_ancestor?(n)
      @bases.include?(n) || @bases.any? { |b| b.has_ancestor?(n) }
    end

    def redefine(node, params)
      if node.enclosure == self
        case node
        when IDL::Struct, IDL::Union
          if node.is_defined?
            raise RuntimeError, "#{node.typename} \"#{node.name}\" is already defined."
          end
          node.switchtype = params[:switchtype] if node.is_a? IDL::Union
          # reposition childnode
          @children.delete(node)
          @children << node
          return node
        else
          raise RuntimeError, "#{node.typename} \"#{node.name}\" is already defined."
        end
      end

      case node
      when IDL::Operation, IDL::Attribute
        raise RuntimeError, "#{node.typename} '#{node.scoped_rubyname}' cannot be overridden."
      else
        newnode = node.type.new(node.name, self, params)
        introduce(newnode)
        return newnode
      end
    end

    alias search_self0 search_self
    def search_self(_name)
      node = search_self0(_name)
      node = search_ancestors(_name) if node.nil?
      node
    end

    protected
    def each_ancestors(visited = [], &block)
      @bases.each do |p|
        next if visited.include? p
        yield(p)
        visited.push p
        p.each_ancestors(visited, &block)
      end
    end

    # search inherited interfaces.
    def search_ancestors(_name)
      results = []
      self.each_ancestors do |interface|
        node = interface.search_self(_name)
        results.push(node) unless node.nil?
      end
      if 1 < results.size
        s = results.collect{ |n| n.name }.join(", ")
        raise RuntimeError, "\"#{_name}\" is ambiguous. " + s
      end
      results[0]
    end
  end

  class Valuetype < Node
    RUBYNAMETYPE = "const"
    DEFINABLE = [IDL::Include, IDL::Const, IDL::Operation, IDL::Attribute,
                 IDL::Struct, IDL::Union, IDL::Enum]
    attr_reader :bases, :interfaces
    attr_reader :idltype

    def initialize(_name, _enclosure, params)
      super(_name, _enclosure)
      @bases = []
      @interfaces = []
      @defined = !params[:forward]
      @abstract = params[:abstract]
      @custom = params[:custom]
      _base = params[:inherits][:base] || {}
      @truncatable = _base[:truncatable] || false
      if @custom && @truncatable
          raise RuntimeError,
                "'truncatable' attribute *not* allowed for 'custom' #{typename} #{scoped_rubyname}"
      end
      add_bases(_base[:list] || [])
      add_interfaces(params[:inherits][:supports] || [])
      @idltype = IDL::Type::Valuetype.new(self)
    end
    def marshal_dump
      super() << @bases << @defined << @abstract << @custom << @truncatable << @idltype
    end

    def marshal_load(vars)
      @idltype = vars.pop
      @truncatable = vars.pop
      @custom = vars.pop
      @abstract = vars.pop
      @defined = vars.pop
      @bases = vars.pop
      super(vars)
    end
    def is_abstract?; @abstract; end
    def is_custom?; @custom; end
    def is_truncatable?; @truncatable; end
    def is_defined?; @defined; end
    def is_forward?; not @defined; end

    def add_bases(inherits_)
      inherits_.each do |tc|
        if not (tc.is_a?(IDL::Type::ScopedName) && tc.node.is_a?(IDL::Valuetype))
          raise RuntimeError,
                "invalid inheritance identifier for #{typename} #{scoped_rubyname}: #{tc.typename}"
        end
        if tc.node.has_ancestor?(self)
          raise RuntimeError,
                "circular inheritance detected for #{typename} #{scoped_rubyname}: #{tc.node.scoped_rubyname} is descendant"
        end
        if not tc.node.is_defined?
          raise RuntimeError,
                "#{typename} #{scoped_rubyname} cannot inherit from forward declared #{tc.node.typename} #{tc.node.scoped_rubyname}"
        end
        if self.is_abstract? and not tc.node.is_abstract?
          raise RuntimeError,
                "'abstract' #{typename} #{scoped_rubyname} cannot inherit from non-'abstract' #{tc.node.typename} #{tc.node.scoped_rubyname}"
        end
        ### @@TODO@@ further validation

        #if not tc.node.is_abstract? and @bases.size > 0
        #  raise RuntimeError,
        #        "concrete basevalue #{tc.node.typename} #{tc.node.scoped_rubyname} MUST be first in inheritance list for #{typename} #{scoped_rubyname}"
        #end
        @bases << tc.node
      end
    end

    def add_interfaces(iflist_)
      iflist_.each do |if_|
        if not (if_.is_a?(IDL::Type::ScopedName) && if_.node.is_a?(IDL::Interface))
          raise RuntimeError,
                "invalid support identifier for #{typename} #{scoped_rubyname}: #{if_.typename}"
        end

        ### @@TODO@@ further validation

        @interfaces << if_.node
      end
    end

    def has_ancestor?(n)
      @bases.include?(n) || @bases.any? { |b| b.has_ancestor?(n) }
    end

    def redefine(node, params)
      if node.enclosure == self
        case node
        when IDL::Struct, IDL::Union
          if node.is_defined?
            raise RuntimeError, "#{node.typename} \"#{node.name}\" is already defined."
          end
          node.switchtype = params[:switchtype] if node.is_a? IDL::Union
          # reposition childnode
          @children.delete(node)
          @children << node
          return node
        else
          raise RuntimeError, "#{node.typename} \"#{node.name}\" is already defined."
        end
      end

      case node
      when IDL::Operation, IDL::Attribute
        raise RuntimeError, "#{node.typename} '#{node.scoped_rubyname}' cannot be overridden."
      else
        newnode = node.type.new(node.name, self, params)
        introduce(newnode)
        return newnode
      end
    end

    alias search_self0 search_self
    def search_self(_name)
      node = search_self0(_name)
      node = search_ancestors(_name) if node.nil?
      node
    end

    protected
    def each_ancestors(visited = [], &block)
      @bases.each do |p|
        next if visited.include? p
        yield(p)
        visited.push p
        p.each_ancestors(visited, &block)
      end
    end

    # search inherited interfaces.
    def search_ancestors(_name)
      results = []
      self.each_ancestors do |interface|
        node = interface.search_self(_name)
        results.push(node) unless node.nil?
      end
      if 1 < results.size
        s = results.collect{ |n| n.name }.join(", ")
        raise RuntimeError, "\"#{_name}\" is ambiguous. " + s
      end
      results[0]
    end
  end

  class Const < Leaf
    RUBYNAMETYPE = "const"
    attr_reader :idltype, :expression, :value
    def initialize(_name, _enclosure, params)
      super(_name, _enclosure)
      @idltype  = params[:type]
      raise RuntimeError,
            "Incomplete type #{@idltype.typename} not allowed here!" if !@idltype.is_complete?
      @expression = params[:expression]
      @value = @idltype.narrow(@expression.value)
    end
    def marshal_dump
      super() << @idltype << @expression
    end

    def marshal_load(vars)
      @expression = vars.pop
      @idltype = vars.pop
      super(vars)
      @value = @idltype.narrow(@expression.value)
    end
  end

  class Parameter < Leaf
    RUBYNAMETYPE = "variable"
    IN, OUT, INOUT = 0,1,2
    attr_reader :idltype, :attribute
    def initialize(_name, _enclosure, params)
      super(_name, _enclosure)
      @idltype  = params[:type]
      raise RuntimeError,
            "Incomplete type #{@idltype.typename} not allowed here!" if !@idltype.is_complete?
      @attribute = case params[:attribute]
		   when :in;    IN
		   when :out;   OUT
		   when :inout; INOUT
		   else
		     raise RuntimeError,
		       "invalid attribute for parameter: #{params[:attribute]}"
		   end
    end
    def marshal_dump
      super() << @idltype << @attribute
    end

    def marshal_load(vars)
      @attribute = vars.pop
      @idltype = vars.pop
      super(vars)
    end
  end
  class Operation < Node
    RUBYNAMETYPE = "variable"
    DEFINABLE = [IDL::Parameter]
    attr_reader :idltype, :oneway
    attr_accessor :raises, :context
    def initialize(_name, _enclosure, params)
      super(_name, _enclosure)
      @idltype  = params[:type]
      raise RuntimeError,
            "Incomplete type #{@idltype.typename} not allowed here!" if !@idltype.is_complete?
      @oneway = (params[:oneway] == true)
      @params = []
      @in = []
      @out = []
    end
    def marshal_dump
      super() << @idltype << @oneway << @params << @in << @out
    end

    def marshal_load(vars)
      @out = vars.pop
      @in = vars.pop
      @params = vars.pop
      @oneway = vars.pop
      @idltype = vars.pop
      super(vars)
    end

    alias define0 define
    def define(*args)
      param = define0(*args)
      @params << param
      case param.attribute
      when Parameter::IN
        @in << param
      when Parameter::OUT
        @out << param
      when Parameter::INOUT
        @in << param
        @out << param
      end
      param
    end

    def in_params
      @in
    end
    def out_params
      @out
    end
    def params
      @params
    end
  end

  class Attribute < Leaf
    attr_reader :idltype, :readonly
    RUBYNAMETYPE = "variable"
    def initialize(_name, _enclosure, params)
      super(_name, _enclosure)
      @idltype  = params[:type]
      raise RuntimeError,
            "Incomplete type #{@idltype.typename} not allowed here!" if !@idltype.is_complete?
      @readonly = params[:readonly]
    end
    def marshal_dump
      super() << @idltype << @readonly
    end

    def marshal_load(vars)
      @readonly = vars.pop
      @idltype = vars.pop
      super(vars)
    end
  end

  class Struct < Node
    RUBYNAMETYPE = "const"
    DEFINABLE = [IDL::Member, IDL::Struct, IDL::Union]
    attr_reader :idltype
    def initialize(_name, _enclosure, params)
      @defined = false
      super(_name, _enclosure)
      @idltype = IDL::Type::Struct.new(self)
    end
    def is_defined?; @defined; end
    def defined=(f); @defined = f; end
    def walk_members(&block)
      @children.each { |m| yield(m) if not m.is_a? IDL::Member }
    end
    def members
      @children.find_all { |c| c.is_a? IDL::Member }
    end
    def marshal_dump
      super() << @idltype 
    end

    def marshal_load(vars)
      @idltype = vars.pop
      super(vars)
    end
  end
  class Exception < IDL::Struct
    DEFINABLE = [IDL::Member]
  end
  class Member < Leaf
    attr_reader :idltype
    RUBYNAMETYPE = "variable"
    def initialize(_name, _enclosure, params)
      super(_name, _enclosure)
      @idltype  = params[:type]
      ## check for use of incomplete types
      if !@idltype.is_complete?
        ## verify type is used in sequence
        if @idltype.resolved_type.is_a? IDL::Type::Sequence
          ## find the (non-sequence) elementtype
          seq_ = @idltype.resolved_type
          mtype = seq_.basetype
          while mtype.resolved_type.is_a? IDL::Type::Sequence
            seq_ = mtype.resolved_type
            mtype = seq_.basetype
          end
          ## is it an incomplete struct or union?
          if mtype.is_a? IDL::Type::ScopedName
            case mtype.resolved_type
            when IDL::Type::Struct, IDL::Type::Union
              if !mtype.node.is_defined?
                ## check if incomplete struct/union is contained within definition of self
                enc = _enclosure
                while enc.is_a?(IDL::Struct) || enc.is_a?(IDL::Union)
                  if enc == mtype.node
                    ## mark sequence as recursive type
                    seq_.recursive = true
                    return
                  end
                  enc = enc.enclosure
                end
              end
            end
          end
        end
        raise RuntimeError, "Incomplete type #{@idltype.typename} not allowed here!"
      end
    end
    def marshal_dump
      super() << @idltype 
    end

    def marshal_load(vars)
      @idltype = vars.pop
      super(vars)
    end
  end
  class Union < Node
    RUBYNAMETYPE = "const"
    DEFINABLE = [IDL::UnionMember, IDL::Struct, IDL::Union]
    attr_reader :idltype
    attr_accessor :switchtype
    def initialize(_name, _enclosure, params)
      @defined = false
      @switchtype = params[:switchtype]
      super(_name, _enclosure)
      @idltype = IDL::Type::Union.new(self)
    end
    def is_defined?; @defined; end
    def defined=(f); @defined = f; end
    def walk_members(&block)
      @children.each { |m| yield(m) if not m.is_a? IDL::UnionMember }
    end
    def members
      @children.find_all { |c| c.is_a? IDL::UnionMember }
    end

    def validate_labels
      labelvals = []
      default_ = false
      members.each { |m|
        ## check union case labels for validity
        m.labels.each { |lbl|
          if lbl == :default
            raise RuntimeError,
                  "duplicate case label 'default' for #{typename} #{rubyname}" if default_
            default_ = true
          else
            # correct type
            lv = @switchtype.resolved_type.narrow(lbl.value)
            # doubles
            if labelvals.include? lv
              raise RuntimeError,
                    "duplicate case label #{lv.to_s} for #{typename} #{rubyname}"
            end
            labelvals << lv
          end
        }
      }
      ## check if default allowed if defined
      if default_
        if @switchtype.resolved_type.range_length == labelvals.size
          raise RuntimeError,
                "'default' case label superfluous for #{typename} #{rubyname}"
        end
      end
    end

    def marshal_dump
      super() << @idltype << @switchtype
    end

    def marshal_load(vars)
      @switchtype = vars.pop
      @idltype = vars.pop
      super(vars)
    end
  end
  class UnionMember < Member
    attr_reader :labels
    RUBYNAMETYPE = "variable"
    def initialize(_name, _enclosure, params)
      super(_name, _enclosure, params)
      ## if any of the labels is 'default' forget about the others
      if params[:labels].include?(:default)
        @labels = [ :default ]
      else
        @labels  = params[:labels]
      end
    end
    def marshal_dump
      super() << @labels 
    end

    def marshal_load(vars)
      @labels = vars.pop
      super(vars)
    end
  end

  class Enum < Leaf
    RUBYNAMETYPE = "const"
    attr_reader :idltype
    def initialize(_name, _enclosure, params)
      super(_name, _enclosure)
      @enums = []
      @idltype = IDL::Type::Enum.new(self)
    end
    def marshal_dump
      super() << @enums << @idltype
    end

    def marshal_load(vars)
      @idltype = vars.pop
      @enums = vars.pop
      super(vars)
    end
    def enumerators
      @enums
    end
    def add_enumerator(c)
      @enums << c
    end
  end

  class Typedef < Leaf
    attr_reader :idltype
    RUBYNAMETYPE = "const"
    def initialize(_name, _enclosure, params)
      super(_name, _enclosure)
      @idltype  = params[:type]
    end
    def marshal_dump
      super() << @idltype 
    end

    def marshal_load(vars)
      @idltype = vars.pop
      super(vars)
    end
  end
end

