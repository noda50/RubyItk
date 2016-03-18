#--------------------------------------------------------------------
# Typecode.rb - R2TAO CORBA TypeCode support
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
module R2CORBA
  module CORBA
    class TypeCode
      def TypeCode.typecode_for_id(id)
        ::R2CORBA::CORBA::Portable::TypeCode.typecode_for_id(id)
      end

      def TypeCode._tc
        CORBA::_tc_TypeCode
      end

      def initialize(kind)
        super(kind)
        _init(kind)
      end

      class Bounds < CORBA::UserException
        def Bounds._tc
          @@tc_Bounds ||= CORBA::TypeCode::Except.new('IDL:omg.org/CORBA/TypeCode/Bounds:1.0'.freeze, 'Bounds', self,[])
        end
      end

      class BadKind < CORBA::UserException
        def BadKind._tc
          @@tc_BadKind ||= CORBA::TypeCode::Except.new('IDL:omg.org/CORBA/TypeCode/BadKind:1.0'.freeze, 'BadKind', self,[])
        end
      end

      class Recursive < TypeCode
        include R2CORBA::CORBA::Portable::TypeCode::Recursive
      end
      class String < TypeCode
        include R2CORBA::CORBA::Portable::TypeCode::String
      end
      class WString < TypeCode
        include R2CORBA::CORBA::Portable::TypeCode::WString
      end
      class Sequence < TypeCode
        include R2CORBA::CORBA::Portable::TypeCode::Sequence
      end
      class Array < TypeCode
        include R2CORBA::CORBA::Portable::TypeCode::Array
      end
      class Struct < TypeCode
        include R2CORBA::CORBA::Portable::TypeCode::Struct
      end
      class Except < TypeCode
        include R2CORBA::CORBA::Portable::TypeCode::Except
      end
      class Union < TypeCode
        include R2CORBA::CORBA::Portable::TypeCode::Union
      end
      class ObjectRef < TypeCode
        include R2CORBA::CORBA::Portable::TypeCode::ObjectRef
      end
      class Component < TypeCode
        include R2CORBA::CORBA::Portable::TypeCode::Component
      end
      class Home < TypeCode
        include R2CORBA::CORBA::Portable::TypeCode::Home
      end
      class Alias < TypeCode
        include R2CORBA::CORBA::Portable::TypeCode::Alias
      end
      class Enum < TypeCode
        include R2CORBA::CORBA::Portable::TypeCode::Enum
      end
    end

    [ 'null', 'void',
      'short', 'long', 'ushort', 'ulong', 'longlong', 'ulonglong',
      'float', 'double', 'longdouble',
      'boolean',
      'char', 'octet',
      'wchar',
      'any',
    ].each do |tck|
      eval %Q{
        def CORBA._tc_#{tck}
          @@tc_#{tck} ||= TypeCode.new(TypeCode::TK_#{tck.upcase}).freeze
        end}
    end

    def CORBA._tc_string
      @@tc_TypeCode ||= TypeCode::String.new().freeze
    end

    def CORBA._tc_wstring
      @@tc_TypeCode ||= TypeCode::WString.new().freeze
    end

    def CORBA._tc_TypeCode
      @@tc_TypeCode ||= TypeCode.new(TypeCode::TK_TYPECODE).freeze
    end

    def CORBA._tc_Principal
      @@tc_Principal ||= TypeCode.new(TypeCode::TK_PRINCIPAL).freeze
    end

    def CORBA._tc_Object
      @@tc_Object ||= TypeCode::ObjectRef.new("IDL:omg.org/CORBA/Object:1.0", "Object", CORBA::Object).freeze
    end

    def CORBA._tc_CCMObject
      @@tc_CCMObject ||= TypeCode::Component.new("IDL:omg.org/CORBA/CCMObject:1.0", "CCMObject", ::Object).freeze
    end

    def CORBA._tc_CCHome
      @@tc_CCHome ||= TypeCode::Home.new("IDL:omg.org/CORBA/CCHome:1.0", "CCHome", ::Object).freeze
    end
  end # class Typecode

  class LongDouble
    def to_d(precision)
      BigDecimal.new(self.to_s(precision))
    end
    def _tc
      CORBA._tc_longdouble
    end
  end
end
