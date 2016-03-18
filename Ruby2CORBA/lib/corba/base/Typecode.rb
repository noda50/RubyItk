#--------------------------------------------------------------------
# Typecode.rb - basic CORBA TypeCode definitions
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
require "corba/base/Struct.rb"

module R2CORBA
  module CORBA
    module Portable
      module TypeCode

        OctetRange     = (0..0xFF).freeze
        UShortRange    = (0..0xFFFF).freeze
        ULongRange     = (0..0xFFFFFFFF).freeze
        ULongLongRange = (0..0xFFFFFFFFFFFFFFFF).freeze
        ShortRange     = (-0x8000...0x8000).freeze
        LongRange      = (-0x80000000...0x80000000).freeze
        LongLongRange  = (-0x8000000000000000...0x8000000000000000).freeze

        @@id_types = {}

        def TypeCode.register_id_type(id, tc)
          @@id_types[id] = tc
        end

        def TypeCode.typecode_for_id(id)
          @@id_types[id]
        end

        def initialize(kind)
          @kind = kind
          get_type
        end

        def resolved_tc
          self
        end

        def is_recursive_tc?
          false
        end

        def kind
          @kind
        end

        def get_compact_typecode
          self
        end

        def equal?(tc)
          @kind == tc.kind
        end

        def equivalent?(tc)
          resolved_tc.kind == tc.resolved_tc.kind
        end

        def id
          raise ::CORBA::TypeCode::BadKind.new
        end

        def name
          raise ::CORBA::TypeCode::BadKind.new
        end

        def member_count
          raise ::CORBA::TypeCode::BadKind.new
        end

        def member_name(index)
          raise ::CORBA::TypeCode::BadKind.new
        end

        def member_type(index)
          raise ::CORBA::TypeCode::BadKind.new
        end

        def member_label(index)
          raise ::CORBA::TypeCode::BadKind.new
        end

        def discriminator_type
          raise ::CORBA::TypeCode::BadKind.new
        end

        def default_index
          raise ::CORBA::TypeCode::BadKind.new
        end

        def length
          raise ::CORBA::TypeCode::BadKind.new
        end

        def content_type
          raise ::CORBA::TypeCode::BadKind.new
        end

        def fixed_digits
          raise ::CORBA::TypeCode::BadKind.new
        end

        def fixed_scale
          raise ::CORBA::TypeCode::BadKind.new
        end

        def member_visibility
          raise ::CORBA::TypeCode::BadKind.new
        end

        def type_modifier
          raise ::CORBA::TypeCode::BadKind.new
        end

        def concrete_base_type
          raise ::CORBA::TypeCode::BadKind.new
        end

        def get_type
          @type ||= case @kind
            when TK_SHORT, TK_LONG, TK_USHORT, TK_ULONG
              ::Fixnum
            when TK_LONGLONG, TK_ULONGLONG
              ::Bignum
            when TK_FLOAT, TK_DOUBLE
              ::Float
            when TK_LONGDOUBLE
              ::CORBA::LongDouble
            when TK_BOOLEAN
              ::TrueClass
            when TK_CHAR, TK_STRING
              ::String
            when TK_WCHAR, TK_OCTET
              ::Fixnum
            when TK_VOID, TK_NULL
              ::NilClass
            when TK_ANY
              ::Object
            when TK_TYPECODE, TK_PRINCIPAL
              ::CORBA::TypeCode
            when TK_OBJREF
              ::CORBA::Object
            else
              nil
          end
        end

        def validate(val)
          case @kind
          when TK_ANY
            return val
          when TK_BOOLEAN
            return val if ((val.is_a? TrueClass) || (val.is_a? FalseClass))
          when TK_SHORT
            return val.to_int if val.respond_to?(:to_int) && ShortRange === val.to_int
          when TK_LONG
            return val.to_int if val.respond_to?(:to_int) && LongRange === val.to_int
          when TK_USHORT, TK_WCHAR
            return val.to_int if val.respond_to?(:to_int) && UShortRange === val.to_int
          when TK_ULONG
            return val.to_int if val.respond_to?(:to_int) && ULongRange === val.to_int
          when TK_LONGLONG
            return val.to_int if val.respond_to?(:to_int) && LongLongRange === val.to_int
          when TK_ULONGLONG
            return val.to_int if val.respond_to?(:to_int) && ULongLongRange === val.to_int
          when TK_OCTET
            return val.to_int if val.respond_to?(:to_int) && OctetRange === val.to_int
          when TK_FLOAT, TK_DOUBLE
            return val if val.is_a?(::Float)
          when TK_LONGDOUBLE
            return val if val.is_a?(::CORBA::LongDouble)
          when TK_CHAR
            if (val.respond_to?(:to_str) && (val.to_str.size == 1)) ||
               (val.respond_to?(:to_int) && OctetRange === val.to_int)
              return val.respond_to?(:to_str) ? val.to_str : val.to_int.chr
            end
          else
            return val if (val.nil? || val.is_a?(self.get_type))
          end
          raise ::CORBA::MARSHAL.new(
            "value does not match type: value == #{val.class.name}, type == #{get_type.name}",
            1, ::CORBA::COMPLETED_NO)
        end

        def needs_conversion(val)
          case @kind
          when TK_SHORT, TK_LONG,
               TK_USHORT, TK_WCHAR,
               TK_ULONG, TK_LONGLONG, TK_ULONGLONG,
               TK_OCTET
            return !(::Integer === val)
          when TK_CHAR
            return !(::String === val)
          end
          false
        end

        module Recursive
          def initialize(id)
            @id = id
            super(TK_NULL)
          end
          def recursed_tc
            @recursive_tc ||= TypeCode.typecode_for_id(@id)
            @recursive_tc || ::CORBA::TypeCode.new(TK_NULL)
          end
          def resolved_tc
            recursed_tc.resolved_tc
          end
          def is_recursive_tc?
            true
          end
          def get_type
            @recursive_tc ||= TypeCode.typecode_for_id(@id)
            if @recursive_tc.nil? then nil; else @recursive_tc.get_type; end
          end
          def validate(val)
            recursed_tc.validate(val)
          end
          def needs_conversion(val)
            recursed_tc.needs_conversion(val)
          end
          def kind
            recursed_tc.kind
          end

          def get_compact_typecode
            self
          end

          def equal?(tc)
            kind == tc.kind
          end

          def equivalent?(tc)
            resolved_tc.kind == tc.resolved_tc.kind
          end

          def id
            recursed_tc.id
          end

          def name
            recursed_tc.name
          end

          def member_count
            recursed_tc.member_count
          end

          def member_name(index)
            recursed_tc.member_name(index)
          end

          def member_type(index)
            recursed_tc.member_type(index)
          end

          def member_label(index)
            recursed_tc.member_label(index)
          end

          def discriminator_type
            recursed_tc.discriminator_type
          end

          def default_index
            recursed_tc.default_index
          end
        end

        module String
          attr_reader :length
          def initialize(length=nil)
            @length = length
            super(TK_STRING)
          end

          def validate(val)
            super(val) if !val.respond_to?(:to_str)
            val = ::String === val ? val : val.to_str
            raise ::CORBA::MARSHAL.new(
              "string size exceeds bound: #{@length.to_s}",
              1, ::CORBA::COMPLETED_NO) unless (@length.nil? || val.size<=@length)
            val
          end

          def needs_conversion(val)
            !(::String === val)
          end

          def equal?(tc)
            super(tc) && @length == tc.length
          end

          def equivalent?(tc)
            super(tc) && @length == resolved_tc.length
          end
        end

        module WString
          attr_reader :length
          def initialize(length=nil)
            @length = length
            super(TK_WSTRING)
          end
          def get_type
            ::Array
          end

          def validate(val)
            super(val) if !val.respond_to?(:to_str) && !val.respond_to?(:to_ary)
            val = if ::Array === val
              val
            elsif val.respond_to?(:to_ary)
              val.to_ary
            else
              a = []
              val.to_str.each_byte { |c| a << c }
              a
            end
            raise ::CORBA::MARSHAL.new(
              "widestring size exceeds bound: #{@length.to_s}",
              1, ::CORBA::COMPLETED_NO) unless (@length.nil? || val.size<=@length)
            raise ::CORBA::MARSHAL.new(
              "invalid widestring element(s)",
              1, ::CORBA::COMPLETED_NO) if val.any? { |el| !(UShortRange === (el.respond_to?(:to_int) ? el.to_int : el)) }
            val.any? { |el| !(::Integer === el) } ? val.collect { |el| el.to_int } : val
          end

          def needs_conversion(val)
            !(::Array === val) ? true : val.any? { |el| !(::Integer === el) }
          end

          def in_value(val)
            if val.respond_to?(:to_str)
              a = []
              val.to_str.each_byte { |c| a << c }
              a
            else
              ::Array === val ? val : val.to_ary
            end
          end

          def equal?(tc)
            super(tc) && @length == tc.length
          end

          def equivalent?(tc)
            super(tc) && @length == resolved_tc.length
          end
        end

        module Sequence
          attr_reader :content_tc, :length
          def initialize(content_tc, length=nil)
            raise ::CORBA::BAD_PARAM unless content_tc.is_a?(TypeCode)
            @content_tc = content_tc
            @length = length
            super(TK_SEQUENCE)
          end
          def get_type
            @content_tc.kind == TK_OCTET || @content_tc.kind == TK_CHAR ? ::String : ::Array
          end

          def validate(val)
            super(val) if !val.respond_to?(:to_str) && !val.respond_to?(:to_ary)
            val = if @content_tc.kind == TK_OCTET || @content_tc.kind == TK_CHAR
              if val.respond_to?(:to_str)
                ::String === val ? val : val.to_str
              else
                s = ''
                val.to_ary.each { |e| s << (e.respond_to?(:to_int) ? e.to_int.chr : e.to_str) }
                s
              end
            elsif val.respond_to?(:to_ary)
              ::Array === val ? val : val.to_ary
            else
                a = []
                val.to_str.each_byte { |c| a << c }
                a
            end
            raise ::CORBA::MARSHAL.new(
              "sequence size exceeds bound: #{@length.to_s}",
              1, ::CORBA::COMPLETED_NO) unless (@length.nil? || val.size<=@length)
            if ::Array === val
              if val.any? { |e| @content_tc.needs_conversion(e) }
                val.collect { |e| @content_tc.validate(e) }
              else
                val.each { |e| @content_tc.validate(e) }
              end
            else
              val
            end
          end

          def needs_conversion(val)
            if @content_tc.kind == TK_OCTET || @content_tc.kind == TK_CHAR
              !(::String === val)
            else
              !(::Array === val) ? true : val.any? { |el| @content_tc.needs_conversion(el) }
            end
          end

          def equal?(tc)
            super(tc) && @length == tc.length && @content_tc.equal?(tc.content_tc)
          end

          def equivalent?(tc)
            if super(tc)
              _tc = tc.resolved_tc
              @length == _tc.length && @content_tc.equivalent?(_tc.content_tc)
            else
              false
            end
          end
          def content_type
            @content_tc
          end
          def inspect
            "#{self.class.name}: "+
                "length=#{if @length.nil? then ""; else  @length.to_s; end}; "+
                "content=#{@content_tc.inspect}"
          end
        end

        module Array
          attr_reader :content_tc, :length
          def initialize(content_tc, *length)
            raise ::CORBA::BAD_PARAM unless content_tc.is_a?(TypeCode)
            if length.size>1
              @length = length.shift
              @content_tc = self.class.new(content_tc, *length)
            else
              @length = length.first
              @content_tc = content_tc
            end
            super(TK_ARRAY)
          end
          def get_type
            ::Array
          end

          def validate(val)
            super(val)
            raise ::CORBA::MARSHAL.new(
              "array size exceeds bound: #{@length.to_s}",
              1, ::CORBA::COMPLETED_NO) if val.size>@length
            raise ::CORBA::MARSHAL.new(
              "array size too small: #{@length.to_s}",
              1, ::CORBA::COMPLETED_NO) if val.size<@length
            val.any? { |e| @content_tc.needs_conversion(e) } ? val.collect { |e| @content_tc.validate(e) } : val.each { |e| @content_tc.validate(e) }
          end

          def equal?(tc)
            super(tc) && @length == tc.length && @content_tc.equal?(tc.content_tc)
          end

          def needs_conversion(val)
            val.any? { |e| @content_tc.needs_conversion(e) }
          end

          def equivalent?(tc)
            if super(tc)
              _tc = tc.resolved_tc
              @length == _tc.length && @content_tc.equivalent?(_tc.content_tc)
            else
              false
            end
          end
          def content_type
            @content_tc
          end
        end

        module IdentifiedTypeCode
          attr_reader :id, :name
          def initialize(kind, id, name)
            @id = id.to_s
            @name = name.to_s
            super(kind)
            ::R2CORBA::CORBA::Portable::TypeCode.register_id_type(@id, self)
          end
          def equal?(tc)
            super(tc) && @id == tc.id && @name == tc.name
          end

          def equivalent?(tc)
            super(tc) && @id == tc.resolved_tc.id
          end
        end

        module Alias
          include IdentifiedTypeCode
          attr_reader :aliased_tc
          def initialize(id, name, type_, aliased_tc)
            raise ::CORBA::BAD_PARAM unless aliased_tc.is_a?(TypeCode)
            @aliased_tc = aliased_tc
            @type = type_
            super(TK_ALIAS, id, name)
          end
          def get_type
            @type || @aliased_tc.get_type
          end
          def validate(val)
            @aliased_tc.validate(val)
          end

          def needs_conversion(val)
            @aliased_tc.needs_conversion(val)
          end

          def resolved_tc
            @aliased_tc.resolved_tc
          end
          def equal?(tc)
            super(tc) && @aliased_tc.equal?(tc.aliased_tc)
          end

          def equivalent?(tc)
            if super(tc)
              _tc = tc.resolved_tc
              @aliased_tc.equivalent?(_tc.aliased_tc)
            else
              false
            end
          end
          def content_type
            @aliased_tc
          end
        end

        module ObjectRef
          include IdentifiedTypeCode
          def initialize(id, name, type_ = CORBA::Object)
            @type = type_
            super(TK_OBJREF, id, name)
          end
          def get_type
            @type
          end
        end

        module Component
          include IdentifiedTypeCode
          def initialize(id, name, type_)
            @type = type_
            super(TK_COMPONENT, id, name)
          end
          def get_type
            @type
          end
        end

        module Home
          include IdentifiedTypeCode
          def initialize(id, name, type_)
            @type = type_
            super(TK_HOME, id, name)
          end
          def get_type
            @type
          end
        end

        module Struct
          include IdentifiedTypeCode
          attr_reader :members
          def initialize(id, name, type_, members_ = [])
            raise ::CORBA::BAD_PARAM unless members_.is_a? ::Array
            @type = type_
            @members = []
            members_.each { |n, tc| add_member(n, tc) }
            super(TK_STRUCT, id, name)
          end
          def add_member(name_, tc_)
            raise ::CORBA::BAD_PARAM unless tc_.is_a? ::CORBA::TypeCode
            @members << [name_.to_s, tc_]
          end

          def Struct.define_type(tc)
            struct_type = ::Object.module_eval(%Q{
              class #{tc.name} < ::CORBA::Portable::Struct
                def _tc
                  @@tc_#{tc.name} ||= TypeCode.typecode_for_id('#{tc.id}')
                end
              end
              #{tc.name}
            })
            tc.members.each do |mname, mtc|
              struct_type.module_eval(%Q{attr_accessor :#{mname}})
            end
            struct_type
          end

          def get_type
            @type ||= ::R2CORBA::CORBA::Portable::TypeCode::Struct.define_type(self)
          end

          def validate(val)
            super(val)
            if needs_conversion(val)
              vorg = val
              val = vorg.class.new
              @members.each { |name, tc| val.__send__((name+'=').intern, tc.validate(vorg.__send__(name.intern))) }
            else
              @members.each { |name, tc| tc.validate(val.__send__(name.intern)) }
            end
            val
          end

          def needs_conversion(val)
            @members.any? { |name,tc| tc.needs_conversion(val.__send__(name.intern)) }
          end

          def member_count
            @members.size
          end
          def member_name(index)
            raise ::CORBA::TypeCode::Bounds.new if (index<0) || (index>=@members.size)
            @members[index][0]
          end
          def member_type(index)
            raise ::CORBA::TypeCode::Bounds.new if (index<0) || (index>=@members.size)
            @members[index][1]
          end
          def equal?(tc)
            rc = false
            if super(tc) && @members.size == tc.members.size
              rc = true
              @members.each_index { |i|
                mnm, mtc = @members[i]
                _mnm, _mtc = tc.members[i]
                rc |= ((mnm == _mnm) && (mtc.equal?(_mtc)))
              }
            end
            rc
          end

          def equivalent?(tc)
            rc = false
            if super(tc) && @members.size == tc.resolved_tc.members.size
              rc = true
              _tc = tc.resolved_tc
              @members.each_index { |i|
                mnm, mtc = @members[i]
                _mnm, _mtc = _tc.members[i]
                rc |= ((mnm == _mnm) && (mtc.equivalent?(_mtc)))
              }
            end
            rc
          end

          def inspect
            s = "#{self.class.name}: #{name} - #{id}\n"
            @members.each { |n, t| s += "  #{n} = "+t.inspect+"\n" }
            s
          end
        end

        module Except
          include Struct
          def initialize(id, name, type_, members = [])
            super(id, name, type_, members)
            @kind = TK_EXCEPT  ## overrule
          end

          def Except.define_type(tc)
            except_type = ::Object.module_eval(%Q{
              class #{tc.name} < ::CORBA::Portable::Except
                def _tc
                  @@tc_#{tc.name} ||= TypeCode.typecode_for_id('#{tc.id}')
                end
              end
              #{tc.name}
            })
            tc.members.each do |mname, mtc|
              except_type.module_eval(%Q{attr_accessor :#{mname}})
            end
            except_type
          end

          def get_type
            @type ||= ::R2CORBA::CORBA::Portable::TypeCode::Except.define_type(self)
          end
        end

        module Union
          include IdentifiedTypeCode
          attr_reader :members
          attr_reader :switchtype
          def initialize(id, name, type_, switchtype_, members_ = [])
            raise ::CORBA::BAD_PARAM unless members_.is_a? ::Array
            raise ::CORBA::BAD_PARAM unless switchtype_.is_a? ::CORBA::TypeCode
            @type = type_
            @switchtype = switchtype_.resolved_tc
            @labels = {}
            @members = []
            members_.each { |mlabel, mname, mtc|
              add_member(mlabel, mname, mtc)
            }
            super(TK_UNION, id, name)
          end
          def add_member(label_, name_, tc_)
            raise ::CORBA::BAD_PARAM unless tc_.is_a? ::CORBA::TypeCode
            @switchtype.validate(label_) unless label_ == :default
            @labels[label_] = @members.size
            @members << [label_, name_.to_s, tc_]
          end

          def Union.define_type(tc)
            union_type = ::Object.module_eval(%Q{
              class #{tc.name} < ::CORBA::Portable::Union
                def _tc
                  @@tc_#{tc.name} ||= TypeCode.typecode_for_id('#{tc.id}')
                end
              end
              #{tc.name}
            })
            accessors = []
            ix = 0
            tc.members.each do |label, mname, mtc|
              accessors << [mname, ix] unless accessors.include?(mname)
              ix += 1
            end
            accessors.each do |mname, ix|
              union_type.module_eval(%Q{
                def #{mname}; @value; end
                def #{mname}=(val); _set_value(#{ix.to_s}, val); end
              })
            end
            union_type
          end

          def get_type
            @type ||= ::R2CORBA::CORBA::Portable::TypeCode::Union.define_type(self)
          end

          def validate(val)
            super(val)
            @switchtype.validate(val._disc) unless val._disc == :default
            raise ::CORBA::MARSHAL.new(
              "invalid discriminator value (#{val._disc.to_s}) for union #{name}",
              1, ::CORBA::COMPLETED_NO) unless @labels.has_key?(val._disc)
            if needs_conversion(val)
              vorg = val
              val = vorg.class.new
              val.__send__((@members[@labels[vorg._disc]][1]+'=').intern,
                           @members[@labels[vorg._disc]][2].validate(vorg._value))
            else
              @members[@labels[val._disc]][2].validate(val._value)
            end
            val
          end

          def needs_conversion(val)
            @members[@labels[val._disc]][2].needs_conversion(val._value)
          end

          def member_count
            @members.size
          end
          def member_name(index)
            raise ::CORBA::TypeCode::Bounds.new if (index<0) || (index>=@members.size)
            @members[index][1]
          end
          def member_type(index)
            raise ::CORBA::TypeCode::Bounds.new if (index<0) || (index>=@members.size)
            @members[index][2]
          end
          def member_label(index)
            raise ::CORBA::TypeCode::Bounds.new if (index<0) || (index>=@members.size)
            @members[index][0]
          end
          def discriminator_type
            @switchtype
          end
          def default_index
            if @labels.has_key? :default then @labels[:default]; else -1; end
          end

          def label_index(val)
            raise ::CORBA::MARSHAL.new(
              "invalid discriminator value (#{val}) for union #{name}",
              1, ::CORBA::COMPLETED_NO) unless @labels.has_key?(val)
            @labels[val]
          end

          def label_member(val)
            member_name(label_index(val))
          end

          def equal?(tc)
            rc = false
            if super(tc) && @members.size == tc.members.size
              rc = true
              @members.each_index { |i|
                lbl, mnm, mtc = @members[i]
                _lbl, _mnm, _mtc = tc.members[i]
                rc |= ((lbl == _lbl) && (mnm == _mnm) && (mtc.equal?(_mtc)))
              }
            end
            rc
          end

          def equivalent?(tc)
            rc = false
            if super(tc) && @members.size == tc.resolved_tc.members.size
              rc = true
              _tc = tc.resolved_tc
              @members.each_index { |i|
                lbl, mnm, mtc = @members[i]
                _lbl, _mnm, _mtc = _tc.members[i]
                rc |= ((lbl == _lbl) && (mnm == _mnm) && (mtc.equivalent?(_mtc)))
              }
            end
            rc
          end

          def inspect
            s = "#{self.class.name}: #{name} - #{id}\n"
            @members.each { |l, n, t| s += "  case #{l.to_s}: #{n} = "+t.inspect+"\n" }
            s
          end
        end

        module Enum
          include IdentifiedTypeCode
          attr_reader :members
          def initialize(id, name, members_)
            raise ::CORBA::BAD_PARAM unless members_.is_a? ::Array
            @members = members_
            @range = (0...@members.size).freeze
            super(TK_ENUM, id, name)
          end
          def get_type
            ::Integer
          end

          def validate(val)
            super(val) if !val.respond_to?(:to_int)
            raise ::CORBA::MARSHAL.new(
              "value (#{val}) out of range (#{@range}) for enum: #{name}",
              1, ::CORBA::COMPLETED_NO) unless @range === (::Integer === val ? val : val.to_int)
            (::Integer === val ? val : val.to_int)
          end

          def needs_conversion(val)
            !(::Integer === val)
          end

          def member_count
            @members.size
          end
          def member_name(index)
            raise ::CORBA::TypeCode::Bounds.new if (index<0) || (index>=@members.size)
            @members[index]
          end
          def equal?(tc)
            super(tc) && @members.size == tc.members.size
          end

          def equivalent?(tc)
            super(tc) && @members.size == tc.resolved_tc.members.size
          end
        end

      end ## module TypeCode
    end ## module Portable
  end ## module CORBA
end ## module R2CORBA
