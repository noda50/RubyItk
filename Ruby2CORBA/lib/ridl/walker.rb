#--------------------------------------------------------------------
# walker.rb - IDL typecode and client stubs backend walker
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
class StrOStream
  def initialize()
    @str = ""
  end
  def clear
    @str = ""
  end
  def to_s
    @str
  end
  def puts(s)
    @str << s + "\n"
  end
  def print(s)
    @str << s
  end
end

class RubyStubWriter
  def initialize(output = STDOUT, params = {}, indent = "  ")
    @output = output
    @params = params
    @indent = indent
    @nest = 0
  end

  def print(str);       @output.print(str); end
  def println(str="");  @output.puts(str); end
  def printi(str="");   @output.print(indent + str); end
  def printiln(str=""); @output.puts(indent + str); end
  def indent()
    @indent * @nest
  end
  def nest
    @nest += 1
    begin
      yield
    ensure
      @nest -= 1
    end
  end

  def pre_parse(root)
    print(
%Q{# -*- Ruby -*-
#
# ****  Code generated by the R2CORBA IDL Compiler ****
# R2CORBA has been developed by:
#        Remedy IT
#        Nijkerk, GLD
#        The Netherlands
#        http://www.remedy.nl \ http://www.theaceorb.nl
#
})
    println("require 'corba'") if @params[:libinit]
    println()
    enter_module(root) unless root.nil?
    idleval = @params[:idl_eval] || false
    if !idleval
      printiln("CORBA.implement('#{@params[:idlfile]}', {}, CORBA::IDL::CLIENT_STUB) {")
      println()
    end
   end

  def post_parse(root)
    idleval = @params[:idl_eval] || false
    if !idleval
      printiln("} ## end of '#{@params[:idlfile]}'")
    end
    leave_module(root) unless root.nil?
    println("# -*- END -*-")
  end

  def visit_include(node)
    printiln(format("require '%s'", node.filename.sub(/\.[^\.]*$/,@params[:stub_ext])))
    println()
  end

  def enter_include(node)
    printiln("## include")
    printiln("CORBA.implement('#{node.filename}', {}, CORBA::IDL::CLIENT_STUB) {")
    println()
  end

  def leave_include(node)
    println()
    printiln("} ## end of include '#{node.filename}'")
    println()
  end

  def enter_module(node)
    printiln("module " + node.rubyname)
    println()
    @nest += 1
  end
  def leave_module(node)
    @nest -= 1
    printiln("end #of module #{node.rubyname}")
    println()
  end

  def declare_interface(node)
    name = node.rubyname
    if not @params[:class_interfaces].nil? and @params[:class_interfaces].include?(name)
      printiln("class #{name}; end  ## interface forward")
    else
      printiln("module #{name}; end  ## interface forward")
    end
  end
  def enter_interface(node)
    println
    name = node.rubyname
    if not @params[:class_interfaces].nil? and @params[:class_interfaces].include?(name)
      printiln("class #{node.rubyname}  ## interface")
    else
      printiln("module #{node.rubyname}  ## interface")
    end
    println()
    @nest += 1

    if node.bases.size>0
      node.bases.each do |n|
        printiln("include #{n.scoped_rubyname}")
      end
    end
    println()

    printiln(format("Id = '%s'.freeze", node.repository_id))
    printi("Ids = [ Id")
    if node.bases.size>0
      node.bases.each do |n|
        println(",")
        printi("        #{n.scoped_rubyname}::Id")
      end
    end
    println(" ].freeze")

    println
    printiln(format("def %s._tc; @@tc_%s ||= CORBA::TypeCode::ObjectRef.new(Id, '%s', self); end",
                    node.rubyname, node.rubyname, node.rubyname))
    printiln("self._tc  # register typecode");

    println
    printiln("def #{name}._narrow(obj)")
    nest {
      if node.is_local?
        printiln("return CORBA::Stub.create_stub(obj)._unchecked_narrow!(self)")
      else
        printiln("return CORBA::Stub.create_stub(obj)._narrow!(self)")
      end
    }
    printiln("end")
    println
    printiln("def #{name}._duplicate(obj)")
    nest {
      if node.is_local?
        printiln("obj");
      else
        printiln("return CORBA::Stub.create_stub(super(obj))._narrow!(self)")
      end
    }
    printiln("end")
    println
    printiln("def _interface_repository_id")
    nest {
      printiln("self.class::Id")
    }
    printiln("end")
    println
  end
  def leave_interface(node)
    name = node.rubyname
    @nest -= 1
    printiln("end #of interface #{name}")
  end

  def visit_const(node)
    v = Expression::Value.new(node.idltype, node.value)
    s = node.rubyname + " = " + expression_to_s(v)
    printiln(s)
  end

  def visit_operation(node)
    _parm = node.params
    _in = node.in_params
    _out = node.out_params
    _intf = node.enclosure

    println()
    printi("def #{node.rubyname}(")
    print( _in.collect{ |p| p.rubyname }.join(", ") )
    if node.oneway
      println(")    # oneway")
    else
      println(")")
    end

    nest do
      if _intf.is_local?
        printiln("raise ::CORBA::NO_IMPLEMENT.new(")
        printiln("         'unimplemented operation on local interface',")
        printiln("         1, ::CORBA::COMPLETED_NO)")
      else
        ##  validate data for IN/INOUT args
        ##
        if _parm.size>0
          _parm.each do |p|
            if p.attribute != IDL::Parameter::OUT
              printiln("#{p.rubyname} = #{get_typecode(p.idltype)}.validate(#{p.rubyname})")
            end
          end
        end
        
        ##  invoke operation
        ##
        if not node.oneway
          printi("_ret = self._invoke('#{node.name}', {")
        else
          printi("self._invoke('#{node.name}', {")
        end

        newln = ""
        if _parm.size>0
          println(newln)
          nest do
            printi(":arg_list => [")
            nest {
              pfx = ""
              _parm.each do |p|
                println(pfx)
                printi("['#{p.rubyname}', #{get_arg_type(p.attribute)}, ");
                print(get_typecode(p.idltype))
                if p.attribute != IDL::Parameter::OUT
                  print(", #{p.rubyname}]")
                else
                  print("]")
                end
                pfx = ","
              end
              print("]")
            }
          end
          newln = ","
        end

        if not node.oneway
          println(newln)
          nest { printi(":result_type => #{get_typecode(node.idltype)}") }
          newln = ","
        end

        if node.raises.size>0
          println(newln)
          nest {
            printi(":exc_list => [")
            pfx = ""
            nest {
              node.raises.each { |ex|
                println(pfx)
                pfx = ","
                printi(get_typecode(ex))
              }
              print("]")
            }
          }
        end

        println("})")

        if not node.oneway
          returns_void = (node.idltype.is_a? Type::Void)
          size = _out.size
          size += 1 unless returns_void
          printiln('_ret')
        end
      end
    end

    printiln("end #of operation #{node.rubyname}")
  end

  def visit_attribute(node)
    _intf = node.enclosure
    println()
    printiln("def #{node.rubyname}()")
    nest do
      if _intf.is_local?
        printiln("raise ::CORBA::NO_IMPLEMENT.new(")
        printiln("         'unimplemented attribute on local interface',")
        printiln("         1, ::CORBA::COMPLETED_NO)")
      else
        printiln("_ret = self._invoke('_get_#{node.name}', {")
        nest { printiln(":result_type => #{get_typecode(node.idltype)}})") }

        printiln('_ret')
      end
    end
    printiln("end #of attribute get_#{node.name}")
    if not node.readonly
      printiln("def #{node.rubyname}=(val)")
      nest do
        if _intf.is_local?
          printiln("raise ::CORBA::NO_IMPLEMENT.new(")
          printiln("         'unimplemented attribute on local interface',")
          printiln("         1, ::CORBA::COMPLETED_NO)")
        else
          ## validate IN arg
          printiln("val = #{get_typecode(node.idltype)}.validate(val)")
          ## invoke operation
          printiln("self._invoke('_set_#{node.name}', {")
          nest {
            printiln(":arg_list => [")
            nest {
              printiln("['val', CORBA::ARG_IN, #{get_typecode(node.idltype)}, val]],");
            }
            printiln(":result_type => CORBA._tc_void})")
          }
        end
      end
      printiln("end #of attribute set_#{node.name}")
    end
  end

  def get_typecode(_type)
    case _type
    when Type::Octet,
         Type::UShort, Type::Short,
         Type::ULong, Type::Long,
         Type::ULongLong, Type::LongLong,
         Type::Boolean, Type::Char, Type::WChar,
         Type::Float, Type::Double, Type::LongDouble,
         Type::Void, Type::Any
      s = _type.class.name.split("::") # IDL::Type::Octet -> [IDL, Type, Octet]
      s = s[s.length - 1]
      s.downcase!
      format("CORBA._tc_%s",s)

    when Type::Object
      "CORBA._tc_Object"

    when Type::String
      if not _type.length.nil?
        format("CORBA::TypeCode::String.new(%d)", _type.length)
      else
        "CORBA._tc_string"
      end

    when Type::WString
      if not _type.length.nil?
        format("CORBA::TypeCode::WString.new(%d)", _type.length)
      else
        "CORBA._tc_wstring"
      end

    when Type::ScopedName
      _type.node.scoped_rubyname + '._tc'

    when Type::Array
      sep = ""
      tc = "CORBA::TypeCode::Array.new(" +
          get_typecode(_type.basetype) + ", "
      _type.sizes.each do |sz|
        tc += "#{sep}#{sz.to_s}"
        sep = ", "
      end
      tc + ")"

    when Type::Sequence
      if _type.recursive
        "CORBA::TypeCode::Sequence.new(CORBA::TypeCode::Recursive.new('#{_type.basetype.resolved_type.node.repository_id}'))"
      else
        "CORBA::TypeCode::Sequence.new(" +
              get_typecode(_type.basetype) +
              if not _type.length.nil? then format(", %d)", _type.length) else ")" end +
              ".freeze"
      end

    else
      raise RuntimeError, "invalid type for (un)marshalling: #{_type.typename}"
    end
  end

  def get_arg_type(_idl_argtype)
    case _idl_argtype
    when IDL::Parameter::IN
      "CORBA::ARG_IN"
    when IDL::Parameter::OUT
      "CORBA::ARG_OUT"
    else
      "CORBA::ARG_INOUT"
    end
  end

  def expression_to_s(exp)
    case exp
    when Expression::Value
      value_to_s(exp)
    when Expression::Operation
      operation_to_s(exp)
    when Expression::ScopedName
      exp.node.scoped_rubyname
    else
      raise RuntimeError, "unknown expression type: #{exp.class.name}"
    end
  end

  def value_to_s(exp)
    s = nil
    v = exp.value
    case exp.idltype
    when Type::Void
      s = "nil"
    when Type::Char
      s = "'#{v.chr}'"
    when Type::Integer,
      Type::Boolean,
      Type::Octet,
      Type::Float,
      Type::WChar
      s = v.to_s
    when Type::Enum
      s = v.to_s
    when Type::String
      s = "'#{v.to_s}'"
    when Type::WString
      s = "[#{v.join(',')}]"
    #when Type::Fixed
    #when Type::Any
    #when Type::Object
    when Type::ScopedName
      s = value_to_s(Expression::Value.new(exp.idltype.node.idltype, v))
    else
      raise RuntimeError, "#{exp.typename}'s not been supported yet."
    end
    s
  end

  def operation_to_s(exp)
    s = nil
    op = exp.operands
    case exp
    when Expression::UnaryPlus
      s = expression_to_s(op[0])
    when Expression::UnaryMinus
      s = "-" + expression_to_s(op[0])
    when Expression::UnaryNot
      s = "~" + expression_to_s(op[0])
    when Expression::Or
      s = expression_to_s(op[0]) + " | " + expression_to_s(op[1])
    when Expression::And
      s = expression_to_s(op[0]) + " & " + expression_to_s(op[1])
    when Expression::LShift
      s = expression_to_s(op[0]) + " << " + expression_to_s(op[1])
    when Expression::RShift
      s = expression_to_s(op[0]) + " >> " + expression_to_s(op[1])
    when Expression::Add
      s = expression_to_s(op[0]) + " + " + expression_to_s(op[1])
    when Expression::Minus
      s = expression_to_s(op[0]) + " - " + expression_to_s(op[1])
    when Expression::Mult
      s = expression_to_s(op[0]) + " * " + expression_to_s(op[1])
    when Expression::Div
      s = expression_to_s(op[0]) + " / " + expression_to_s(op[1])
    when Expression::Mod
      s = expression_to_s(op[0]) + " % " + expression_to_s(op[1])
    else
      raise RuntimeError, "unknown operation: #{exp.type.name}"
    end
    "(" + s + ")"
  end

  def enter_struct(node)
    println()
    name = node.rubyname
    printiln("class #{name} < CORBA::Portable::Struct")
    @nest += 1
  end
  def leave_struct(node)
    tc_ = if node.is_a? IDL::Exception then "Except" else "Struct" end
    println()
    printiln(format("def %s._tc", node.rubyname))
    nest {
      printi(format("@@tc_%s ||= CORBA::TypeCode::%s.new('%s'.freeze, '%s', self",
                    node.rubyname, tc_, node.repository_id, node.rubyname))
      if node.members.size>0
        pfx = "   ["
        node.members.each do |m|
          println(",")
          printi(pfx)
          pfx = "    "
          print(format("['%s', %s]", m.rubyname, get_typecode(m.idltype)))
        end
        println("])")
      else
        println(")")
      end
    }
    printiln("end")
    printiln("self._tc  # register typecode");
    node.members.each do |m|
      printiln(format("attr_accessor :%s", m.rubyname))
    end

    if node.members.size>0
      printiln('def initialize(*param_)')
      nest {
        pfx = ''
        node.members.each do |m|
          print(pfx)
          printi('@'+m.rubyname)
          pfx = ",\n"
        end
        println(' = param_')
      }
      printiln('end')
      println()
    end

    name = node.rubyname
    @nest -= 1
    printiln("end #of #{if node.is_a? IDL::Exception then "exception" else "struct" end} #{name}")
  end

  def enter_exception(node)
    println()
    name = node.rubyname
    printiln("class #{name} < CORBA::UserException")
    @nest += 1
  end
  def leave_exception(node)
    leave_struct(node)
  end

  def enter_union(node)
    println()
    name = node.rubyname
    printiln("class #{name} < CORBA::Portable::Union")
    @nest += 1
  end
  def leave_union(node)
    println()
    printiln(format("def %s._tc", node.rubyname))
    nest {
      printiln(format("@@tc_%s ||= CORBA::TypeCode::Union.new('%s'.freeze, '%s', self,",
                    node.rubyname, node.repository_id, node.rubyname))
      printi("    #{get_typecode(node.switchtype)}")
      if node.members.size>0
        pfx = "   ["
        node.members.each do |m|
          m.labels.each do |lbl|
            println(",")
            printi(pfx)
            pfx = "    "
            labeltxt = if lbl == :default then ':default'; else expression_to_s(lbl); end
            print(format("[%s, '%s', %s]", labeltxt, m.rubyname, get_typecode(m.idltype)))
          end
        end
        println("])")
      else
        println(")")
      end
    }
    printiln("end")
    printiln("self._tc  # register typecode");
    ix = 0
    if node.members.size>0
      node.members.each do |m|
        printiln(format("def %s; @value; end", m.rubyname))
        printiln(format("def %s=(val); _set_value(%d, val); end", m.rubyname, ix))
        ix += m.labels.size
      end
    end

    name = node.rubyname
    @nest -= 1
    printiln("end #of union #{name}")
  end

  def visit_enum(node)
    printiln(format("class %s < ::Fixnum", node.rubyname))
    nest {
      printiln(format("def %s._tc", node.rubyname))
      nest {
        printi(format("@@tc_%s ||= CORBA::TypeCode::Enum.new('%s'.freeze, '%s', [",
                      node.rubyname, node.repository_id, node.rubyname))
        pfx = ""
        node.enumerators.each { |e|
          println(pfx)
          pfx = ","
          printi("    '#{e.rubyname}'")
        }
        println("])")
      }
      printiln("end")
      printiln("self._tc  # register typecode");
    }
    printiln(format("end # enum %s", node.rubyname))
  end

  def visit_typedef(node)
    #tc_ = node.enclosure.rubyname + '._tc_' + node.rubyname
    #typ_ = node.enclosure.rubyname + '.' + node.rubyname
    case t = node.idltype
    when Type::ScopedName
      if Type::Interface === t.resolved_type
        printiln(format("%s = %s # typedef %s", node.rubyname, t.node.scoped_rubyname, node.rubyname))
      else
        printiln(format("class %s < %s", node.rubyname, t.node.scoped_rubyname))
        nest {
          printi(format("def %s._tc; ", node.rubyname))
          print(format("@@tc_%s ||= CORBA::TypeCode::Alias.new('%s', '%s', self,", node.rubyname, node.repository_id, node.rubyname))
          println(format("%s); end", get_typecode(t)))
        }
        printiln(format("end # typedef %s", node.rubyname))
      end

    when IDL::Type::Native
      printiln("class #{node.rubyname}; end  ## 'native' type");

    when Type::Any, Type::Octet,
        Type::UShort, Type::Short,
        Type::ULong, Type::Long,
        Type::ULongLong, Type::LongLong,
        Type::Boolean, Type::Char, Type::WChar,
        Type::Float, Type::Double, Type::LongDouble
      s = t.class.name.split("::") # IDL::Type::Octet -> [IDL, Type, Octet]
      s = s[s.length - 1]
      s.downcase!
      printiln(format("class %s < CORBA::_tc_%s.get_type", node.rubyname, s))
      nest {
        printiln(format("def %s._tc; @@tc_%s ||= CORBA::TypeCode::Alias.new('%s', '%s', self, CORBA::_tc_%s); end",
                        node.rubyname, node.rubyname, node.repository_id, node.rubyname, s))
      }
      printiln(format("end # typedef %s", node.rubyname))

    when Type::String
      printiln(format("class %s < String", node.rubyname))
      nest {
        if not t.length.nil?
          printiln(format("def %s._tc; @@tc_%s ||= CORBA::TypeCode::Alias.new('%s', '%s', self, CORBA::TypeCode::String.new(%d)); end",
                          node.rubyname, node.rubyname, node.repository_id, node.rubyname, t.length))
        else
          printiln(format("def %s._tc; @@tc_%s ||= CORBA::TypeCode::Alias.new('%s', '%s', self, CORBA::_tc_string); end",
                          node.rubyname, node.rubyname, node.repository_id, node.rubyname))
        end
      }
      printiln(format("end # typedef %s", node.rubyname))

    when Type::WString
      printiln(format("class %s < Array", node.rubyname))
      nest {
        if not t.length.nil?
          printiln(format("def %s._tc; @@tc_%s ||= CORBA::TypeCode::Alias.new('%s', '%s', self, CORBA::TypeCode::WString.new(%d)); end",
                          node.rubyname, node.rubyname, node.repository_id, node.rubyname, t.length))
        else
          printiln(format("def %s._tc; @@tc_%s ||= CORBA::TypeCode::Alias.new('%s', '%s', self, CORBA::_tc_wstring); end",
                          node.rubyname, node.rubyname, node.repository_id, node.rubyname))
        end
      }
      printiln(format("end # typedef %s", node.rubyname))

    when IDL::Type::Array
      printiln(format("class %s < Array", node.rubyname))
      nest {
        printiln(format("def %s._tc", node.rubyname))
        nest {
          printiln(format("@@tc_%s ||= CORBA::TypeCode::Alias.new('%s', '%s', self,", node.rubyname, node.repository_id, node.rubyname))
          nest { printiln(format("%s)", get_typecode(t))) }
        }
        printiln("end")
      }
      printiln(format("end # typedef %s", node.rubyname))

    when IDL::Type::Sequence
      case t.basetype.resolved_type
      when IDL::Type::Char, IDL::Type::Octet
        printiln(format("class %s < String", node.rubyname))
      else
        printiln(format("class %s < Array", node.rubyname))
      end
      nest {
        printiln(format("def %s._tc", node.rubyname))
        nest {
          printiln(format("@@tc_%s ||= CORBA::TypeCode::Alias.new('%s', '%s', self,", node.rubyname, node.repository_id, node.rubyname))
          nest { printiln(format("%s)", get_typecode(t))) }
        }
        printiln("end")
      }
      printiln(format("end # typedef %s", node.rubyname))

    else
      raise RuntimeError, "unsupported typedef for #{t.class.name}."
    end
  end
end ## RubyStubWriter

class RubyServantWriter
  def initialize(output = STDOUT, params = {}, indent = "  ")
    @output = output
    @params = params
    @indent = indent
    @nest = 0
    @stub_root = '::'
  end

  def print(str);       @output.print(str); end
  def println(str="");  @output.puts(str); end
  def printi(str="");   @output.print(indent + str); end
  def printiln(str=""); @output.puts(indent + str); end
  def indent()
    @indent * @nest
  end
  def nest
    @nest += 1
    begin
      yield
    ensure
      @nest -= 1
    end
  end

  def pre_parse(root)
    print(
%Q{# -*- Ruby -*-
#
# ****  Code generated by the R2CORBA IDL Compiler ****
# R2CORBA has been developed by:
#        Remedy IT
#        Nijkerk, GLD
#        The Netherlands
#        http://www.remedy.nl \ http://www.theaceorb.nl
#
})
    idleval = @params[:idl_eval] || false
    println("require 'corba/poa.rb'") if @params[:libinit]
    if !@params[:expand_includes]
      println("require '"+@params[:idlfile].sub(/\.[^\.]*$/,@params[:stub_ext])+"'")
    end
    println()
    printiln("module POA")
    @nest += 1
    if !idleval
      printiln("CORBA.implement('#{@params[:idlfile]}', {}, CORBA::IDL::SERVANT_INTF) {")
      println()
    end
    ## register explicit (*not* IDL derived) rootnamespace used for client stubs
    @stub_root = "#{root.rubyname}::" unless root.nil?
  end

  def post_parse(root)
    idleval = @params[:idl_eval] || false
    if !idleval
      printiln("} ## end of '#{@params[:idlfile]}'")
    end
    @nest -= 1
    printiln("end #of module POA")
    println("# -*- END -*-")
  end

  def visit_include(node)
    printiln(format("require '%s'", node.filename.sub(/\.[^\.]*$/,@params[:srv_ext])))
    println()
  end

  def enter_include(node)
    printiln("## include")
    printiln("CORBA.implement('#{node.filename}', {}, CORBA::IDL::SERVANT_INTF) {")
    println()
  end

  def leave_include(node)
    println()
    printiln("} ## end of include '#{node.filename}'")
    println()
  end

  def enter_module(node)
    printiln("module " + node.rubyname)
    println()
    @nest += 1
  end
  def leave_module(node)
    @nest -= 1
    printiln("end #of module #{node.rubyname}")
    println()
  end

  def declare_interface(node)
    printiln("class #{node.rubyname} < PortableServer::Servant; end  ## servant forward")
  end
  def enter_interface(node)
    if !node.is_local?
      println
      name = node.rubyname
      printiln("class #{node.rubyname} < PortableServer::Servant ## servant")
      println()
      @nest += 1

      printiln("module Intf")
      @nest += 1
      printiln(format("Id = '%s'.freeze", node.repository_id))
      printiln("Ids = [ Id ]")
      printiln("Operations = {}")
      println()
    end
  end
  def leave_interface(node)
    if !node.is_local?
      name = node.rubyname

      @nest -= 1
      printiln("end #of Intf")

      println()
      printiln("Id = Intf::Id")
      println()

      if node.bases.size>0
        node.bases.each do |n|
          printiln("include_interface(#{n.scoped_rubyname}::Intf)")
        end
      else
        printiln("include_interface(PortableServer::Servant::Intf)")
      end
      println()

      printiln("include Intf")
      println()

      printiln("def _this; #{@stub_root}#{node.scoped_rubyname}._narrow(super); end")

      @nest -= 1
      printiln("end #of servant #{name}")
    end
  end

  def visit_const(node)
  end

  def visit_operation(node)
    _parm = node.params
    _in = node.in_params
    _out = node.out_params
    _intf = node.enclosure

    ## do nothing for local interfaces
    return nil if _intf.is_local?

    printi("Operations.store(:#{node.name}, {")
    newln = ""
    if _parm.size>0
      println(newln)
      nest do
        printi(":arg_list => [")
        nest {
          pfx = ""
          _parm.each do |p|
            println(pfx)
            printi("['#{p.rubyname}', #{get_arg_type(p.attribute)}, ");
            print(get_typecode(p.idltype))
            print("]")
            pfx = ","
          end
          print("]")
        }
      end
      newln = ","
    end

    if not node.oneway
      println(newln)
      nest { printi(":result_type => #{get_typecode(node.idltype)}") }
      newln = ","
    end

    if node.raises.size>0
      println(newln)
      nest {
        printi(":exc_list => [")
        pfx = ""
        nest {
          node.raises.each { |ex|
            println(pfx)
            pfx = ","
            printi(get_typecode(ex))
          }
          print("]")
        }
      }
      newln = ","
    end

    if node.rubyname != node.name
      println(newln)
      nest { printi(":op_sym => :#{node.rubyname}") }
    end
    println("})")
    println()

    printi("def #{node.rubyname}(")
    print( _in.collect{ |p| p.rubyname }.join(", ") )
    if node.oneway
      println(")    # oneway")
    else
      println(")")
    end
    nest {
      printiln("raise ::CORBA::NO_IMPLEMENT.new(")
      printiln("         'unimplemented servant operation',")
      printiln("         1, ::CORBA::COMPLETED_NO)")
    }
    printiln("end")
    println()
  end

  def visit_attribute(node)
    _intf = node.enclosure

    ## do nothing for local interfaces
    return nil if _intf.is_local?

    printiln("Operations.store(:_get_#{node.name}, {")
    nest {
      printiln("  :result_type => #{get_typecode(node.idltype)},")
      printiln("  :op_sym => :#{node.rubyname} })")
    }
    println()

    printiln("def #{node.rubyname}()")
    nest {
      printiln("raise ::CORBA::NO_IMPLEMENT.new(")
      printiln("         'unimplemented servant attribute get',")
      printiln("         1, ::CORBA::COMPLETED_NO)")
    }
    printiln("end #of attribute get_#{node.name}")
    println()

    if not node.readonly
      printiln("Operations.store(:_set_#{node.name}, {")
      nest {
        nest {
          printiln(":arg_list => [")
          nest {
            printiln("['val', CORBA::ARG_IN, #{get_typecode(node.idltype)}]],");
          }
          printiln(":result_type => CORBA._tc_void,")
          printiln(":op_sym => :#{node.rubyname}= })")
        }
      }
      println()

      printiln("def #{node.rubyname}=(val)")
      nest {
        printiln("raise ::CORBA::NO_IMPLEMENT.new(")
        printiln("         'unimplemented servant attribute set',")
        printiln("         1, ::CORBA::COMPLETED_NO)")
      }
      printiln("end #of attribute set_#{node.name}")
      println()
    end
  end

  def get_typecode(_type)
    case _type
    when Type::Octet,
         Type::UShort, Type::Short,
         Type::ULong, Type::Long,
         Type::ULongLong, Type::LongLong,
         Type::Boolean, Type::Char, Type::WChar,
         Type::Float, Type::Double, Type::LongDouble,
         Type::Void, Type::Any
      s = _type.class.name.split("::") # IDL::Type::Octet -> [IDL, Type, Octet]
      s = s[s.length - 1]
      s.downcase!
      format("CORBA._tc_%s",s)

    when Type::Object
      "CORBA._tc_Object"

    when Type::String
      if not _type.length.nil?
        format("CORBA::TypeCode::String.new(%d)", _type.length)
      else
        "CORBA._tc_string"
      end

    when Type::WString
      if not _type.length.nil?
        format("CORBA::TypeCode::WString.new(%d)", _type.length)
      else
        "CORBA._tc_wstring"
      end

    when Type::ScopedName
      @stub_root + _type.node.scoped_rubyname + '._tc'

    when Type::Array
      sep = ""
      tc = "CORBA::TypeCode::Array.new(" +
          get_typecode(_type.basetype) + ", "
      _type.sizes.each do |sz|
        tc += "#{sep}#{sz.to_s}"
        sep = ", "
      end
      tc + ")"

    when Type::Sequence
      if _type.recursive
        "CORBA::TypeCode::Sequence.new(CORBA::TypeCode::Recursive.new('#{_type.basetype.resolved_type.node.repository_id}'))"
      else
        "CORBA::TypeCode::Sequence.new(" +
              get_typecode(_type.basetype) +
              if not _type.length.nil? then format(", %d)", _type.length) else ")" end +
              ".freeze"
      end

    else
      raise RuntimeError, "invalid type for (un)marshalling: #{_type.typename}"
    end
  end

  def get_arg_type(_idl_argtype)
    case _idl_argtype
    when IDL::Parameter::IN
      "CORBA::ARG_IN"
    when IDL::Parameter::OUT
      "CORBA::ARG_OUT"
    else
      "CORBA::ARG_INOUT"
    end
  end

  def expression_to_s(exp)
    case exp
    when Expression::Value
      value_to_s(exp)
    when Expression::Operation
      operation_to_s(exp)
    when Expression::ScopedName
      @stub_root + exp.node.scoped_rubyname
    else
      raise RuntimeError, "unknown expression type: #{exp.class.name}"
    end
  end

  def value_to_s(exp)
    s = nil
    v = exp.value
    case exp.idltype
    when Type::Void
      s = "nil"
    when Type::Char
      s = "'#{v.chr}'"
    when Type::Integer,
      Type::Boolean,
      Type::Octet,
      Type::Float,
      Type::WChar
      s = v.to_s
    when Type::Enum
      s = v.to_s
    when Type::String
      s = "'#{v.to_s}'"
    when Type::WString
      s = "[#{v.join(',')}]"
    #when Type::Fixed
    #when Type::Any
    #when Type::Object
    when Type::ScopedName
      s = value_to_s(Expression::Value.new(exp.idltype.node.idltype, v))
    else
      raise RuntimeError, "#{exp.typename}'s not been supported yet."
    end
    s
  end

  def operation_to_s(exp)
    s = nil
    op = exp.operands
    case exp
    when Expression::UnaryPlus
      s = expression_to_s(op[0])
    when Expression::UnaryMinus
      s = "-" + expression_to_s(op[0])
    when Expression::UnaryNot
      s = "~" + expression_to_s(op[0])
    when Expression::Or
      s = expression_to_s(op[0]) + " | " + expression_to_s(op[1])
    when Expression::And
      s = expression_to_s(op[0]) + " & " + expression_to_s(op[1])
    when Expression::LShift
      s = expression_to_s(op[0]) + " << " + expression_to_s(op[1])
    when Expression::RShift
      s = expression_to_s(op[0]) + " >> " + expression_to_s(op[1])
    when Expression::Add
      s = expression_to_s(op[0]) + " + " + expression_to_s(op[1])
    when Expression::Minus
      s = expression_to_s(op[0]) + " - " + expression_to_s(op[1])
    when Expression::Mult
      s = expression_to_s(op[0]) + " * " + expression_to_s(op[1])
    when Expression::Div
      s = expression_to_s(op[0]) + " / " + expression_to_s(op[1])
    when Expression::Mod
      s = expression_to_s(op[0]) + " % " + expression_to_s(op[1])
    else
      raise RuntimeError, "unknown operation: #{exp.type.name}"
    end
    "(" + s + ")"
  end

  def enter_struct(node)
  end
  def leave_struct(node)
  end

  def enter_exception(node)
  end
  def leave_exception(node)
  end

  def enter_union(node)
  end
  def leave_union(node)
  end

  def visit_enum(node)
  end

  def visit_typedef(node)
  end
end ## RubyServantWriter

end ## module IDL
