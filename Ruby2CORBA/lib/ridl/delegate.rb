#--------------------------------------------------------------------
# delegate.rb - IDL delegator
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
require 'ridl/node.rb'
require 'ridl/expression.rb'

module IDL

ORB_PIDL = 'orb.pidl'

class Delegator
  def initialize(params = {})
    @walkers = []
    @includes = {}
    @expand_includes = params[:expand_includes] || false
    @preprocess = params[:preprocess] || false
    @preprocout = params[:output] if @preprocess
    @ignore_pidl = params[:ignore_pidl] || false
    if not params[:namespace].nil?
      @root_namespace = IDL::Module.new(params[:namespace], nil, {})
    end
  end
  def add_walker(w)
    @walkers.push w
  end

  def pre_parse
    pidl_file = File.dirname(__FILE__)+'/'+ORB_PIDL unless @preprocess || @ignore_pidl
    if !@preprocess && !@ignore_pidl && File.file?(pidl_file) && File.readable?(pidl_file)
      f = File.open(pidl_file, 'r')
      begin
        @root, @includes = Marshal.load(f)
        @cur = @root
      ensure
        f.close
      end
    else
      @root = @cur = IDL::Module.new(nil, nil, {}) # global root
    end
  end
  def post_parse
    if @preprocess
      Marshal.dump([@root, @includes], @preprocout)
    else
      @walkers.each { |w|
        w.pre_parse(@root_namespace)

        @root.walk_members { |m| walk_member(m, w) }

        w.post_parse(@root_namespace)
      }
    end
  end

  def walk_member(m, w)
      case m
      when IDL::Include
        if !m.is_preprocessed?
          if @expand_includes
            if m.is_defined?
              w.enter_include(m)
              m.walk_members { |cm| walk_member(cm, w) }
              w.leave_include(m)
            end
          else
            w.visit_include(m)
          end
        end
      when IDL::Module
        w.enter_module(m)
        m.walk_members { |cm| walk_member(cm, w) }
        w.leave_module(m)
      when IDL::Interface
        if m.is_forward?
          w.declare_interface(m)
        else
          w.enter_interface(m)
          m.walk_members { |cm| walk_member(cm, w) }
          w.leave_interface(m)
        end
      when IDL::Valuetype
        ## nothing yet
      when IDL::Const
        w.visit_const(m) 
      when IDL::Operation
        w.visit_operation(m)
      when IDL::Attribute
        w.visit_attribute(m)
      when IDL::Exception
        w.enter_exception(m)
        m.walk_members { |cm| walk_member(cm, w) }
        w.leave_exception(m)
      when IDL::Struct
        w.enter_struct(m)
        m.walk_members { |cm| walk_member(cm, w) }
        w.leave_struct(m)
      when IDL::Union
        w.enter_union(m)
        m.walk_members { |cm| walk_member(cm, w) }
        w.leave_union(m)
      when IDL::Typedef
        w.visit_typedef(m)
      when IDL::Enum
        w.visit_enum(m)
      else
        raise RuntimeError, "Invalid IDL member type for walkthrough: #{m.class.name}"
      end
  end

  def is_included?(s)
    @includes.has_key?(s)
  end

  def enter_include(s)
    params = { :filename => s }
    params[:defined] = true
    params[:preprocessed] = @preprocess
    @cur = @cur.define(IDL::Include, "$INC:"+s, params)
    @includes[s] = @cur
    @cur
  end

  def leave_include()
    @cur = @cur.enclosure
  end

  def declare_include(s)
    params = { :filename => s }
    params[:defined] = false
    params[:preprocessed] = @includes[s].is_preprocessed?
    @cur.define(IDL::Include, "$INC:"+s, params)
  end

  def pragma_prefix(s)
    @cur.prefix = s
  end

  def pragma_version(id, major, minor)
    t = parse_scopedname(false, id.split('::'))
    t.node.set_repo_version(major, minor)
  end

  def pragma_id(id, repo_id)
    t = parse_scopedname(false, id.split('::'))
    t.node.set_repo_id(repo_id)
  end

  def define_typeprefix(type, pfx)
    type.node.replace_prefix(pfx.to_s)
  end

  def define_typeid(type, tid)
    type.node.set_repo_id(tid.to_s)
  end

  def define_module(name)
    @cur = @cur.define(IDL::Module, name)
    @cur
  end
  def end_module(node)
    @cur = @cur.enclosure # must equals to argument mod
  end

  def declare_interface(name, attrib=nil)
    params = {}
    params[:abstract] = attrib == :abstract
    params[:local] = attrib == :local
    params[:forward] = true
    @cur.define(IDL::Interface, name, params)
  end

  def define_interface(name, attrib, inherits = [])
    params = {}
    params[:abstract] = attrib == :abstract
    params[:local] = attrib == :local
    params[:forward] = false
    params[:inherits] = inherits
    @cur = @cur.define(IDL::Interface, name, params)
  end
  def end_interface(node)
    @cur = @cur.enclosure # must equals to argument mod
  end

  def declare_valuetype(name, attrib=nil)
    params = {}
    params[:abstract] = attrib == :abstract
    params[:forward] = true
    @cur.define(IDL::Valuetype, name, params)
  end

  def define_valuetype(name, attrib, inherits={})
    params = {}
    params[:abstract] = attrib == :abstract
    params[:custom] = attrib == :custom
    params[:forward] = false
    params[:inherits] = inherits
    @cur = @cur.define(IDL::Valuetype, name, params)
  end
  def end_valuetype(node)
    @cur = @cur.enclosure # must equals to argument mod
  end

  def define_valuebox(name, type)
  end

  def parse_scopedname(global, namelist)
    node = root = if global then @root else @cur end
    first = nil
    namelist.each do |nm|
      n = node.resolve(nm)
      if n.nil?
        raise RuntimeError,
          "cannot find #{nm} in #{node.scoped_name}"
      end
      node = n
      first = node if first.nil?
    end
    root.introduce(first)
    case node
    when IDL::Module, IDL::Interface, IDL::Struct, IDL::Union, IDL::Typedef, IDL::Exception, IDL::Enum
      Type::ScopedName.new(node)
    when IDL::Const
      Expression::ScopedName.new(node)
    else
      raise RuntimeError,
	       "invalid reference to #{node.class.name}: #{node.scoped_name}"
    end
  end

  def parse_literal(_typestring, _value)
    k = Expression::Value
    case _typestring
    when :boolean
      k.new(Type::Boolean.new, _value)
    when :integer
      _type = [
        Type::Octet,
        Type::UShort, Type::Short,
        Type::ULong, Type::Long,
        Type::ULongLong, Type::LongLong,
      ].detect {|t| t::Range === _value }
      if _type.nil?
        raise RuntimeError,
          "it's not a valid integer: #{v.to_s}"
      end
      k.new(_type.new, _value)
    when :string
      k.new(Type::String.new, _value)
    when :wstring
      k.new(Type::WString.new, _value)
    when :char
      k.new(Type::Char.new, _value)
    when :wchar
      k.new(Type::WChar.new, _value)
    when :fixed
      raise ParseError, "fixed literal's supported yet: #{lit}"
    when :float
      k.new(Type::Float.new, _value)
    else
      raise ParseError, "unknown literal type: #{type}"
    end
  end

  def parse_positive_int(_expression)
    if false
    #elsif not Type::Integer === _expression.idltype
      #  raise RuntimeError, "must be integer: #{_expression.to_s}"
    elsif not ::Integer === _expression.value
      raise RuntimeError, "must be integer: #{_expression.value.inspect}"
    elsif _expression.value < 0
      raise RuntimeError, "must be positive integer: #{_expression.value.to_s}"
    end
    _expression.value
  end

  def define_const(_type, _name, _expression)
    params = { :type => _type, :expression => _expression }
    node = @cur.define(IDL::Const, _name, params)
    @cur
  end

  def declare_op_header(_oneway, _type, _name)
    params = Hash.new
    params[:oneway] = (_oneway == :oneway)
    params[:type]   = _type
    @cur = @cur.define(IDL::Operation, _name, params)
  end
  def declare_op_parameter(_attribute, _type, _name)
    params = Hash.new
    params[:attribute] = _attribute
    params[:type] = _type
    @cur.define(IDL::Parameter, _name, params)
  end
  def declare_op_footer(_raises, _context)
    @cur.raises = _raises
    @cur.context = _context
    if @cur.raises.nil?
      @cur.raises = []
    elsif not @cur.context.nil?
      raise RuntimeError, "context phrase's not supported"
    end
    @cur = @cur.enclosure
  end

  def declare_attribute(_type, _name, _readonly=false)
    params = Hash.new
    params[:type] = _type
    params[:readonly] = _readonly
    @cur.define(IDL::Attribute, _name, params)
  end

  def declare_struct(_name)
    params = { :forward => true }
    @cur.define(IDL::Struct, _name, params)
    @cur
  end
  def define_struct(_name)
    params = { :forward => false }
    @cur = @cur.define(IDL::Struct, _name, params)
  end
  def declare_member(_type, _name)
    params = Hash.new
    params[:type] = _type
    @cur.define(IDL::Member, _name, params)
  end
  def end_struct(node)
    node.defined = true
    ret = IDL::Type::ScopedName.new(@cur)
    @cur = @cur.enclosure
    ret
  end
  def define_exception(_name)
    params = { :forward => false }
    @cur = @cur.define(IDL::Exception, _name, params)
  end
  def end_exception(node)
    ret = IDL::Type::ScopedName.new(@cur)
    @cur = @cur.enclosure
    ret
  end

  def declare_union(_name)
    params = { :forward => true }
    @cur.define(IDL::Union, _name, params)
    @cur
  end
  def define_union(_name, _switchtype)
    params = { :forward => false, :switchtype => _switchtype }
    @cur = @cur.define(IDL::Union, _name, params)
  end
  def define_case(_labels, _type, _name)
    params = Hash.new
    params[:type] = _type
    params[:labels] = _labels
    @cur.define(IDL::UnionMember, _name, params)
  end
  def end_union(node)
    node.validate_labels
    node.defined = true
    ret = IDL::Type::ScopedName.new(@cur)
    @cur = @cur.enclosure
    ret
  end

  def define_enum(_name)
    @cur = @cur.define(IDL::Enum, _name, nil)
  end
  def declare_enumerator(_name)
    n = @cur.enumerators.length
    params = {
      :type => IDL::Type::ULong.new,
      :expression => IDL::Expression::Value.new(IDL::Type::ULong.new, n)
    }
    n = @cur.enclosure.define(IDL::Const, _name, params)
    @cur.add_enumerator(n)
    n
  end
  def end_enum(node)
    @cur = @cur.enclosure
  end

  def declare_typedef(_type, _name)
    params = Hash.new
    params[:type] = _type
    @cur.define(IDL::Typedef, _name, params)
  end
end
end
