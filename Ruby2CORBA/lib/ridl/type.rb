#--------------------------------------------------------------------
# type.rb - IDL types
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
  class Type
    def typename
      self.class.name
    end
    def typeerror(val)
      raise RuntimeError, "#{val.inspect} cannot narrow to #{self.typename}"
    end
    def narrow(obj)
      obj
    end
    def resolved_type
      self
    end
    def is_complete?
      true
    end

    class UndefinedType
      def initialize(*args)
        raise RuntimeError, "#{self.class.name}'s not implemented yet."
      end
    end

    class Void < Type
      def narrow(obj)
        typeerror(obj) unless obj.nil?
        obj
      end
    end

    class ScopedName < Type
      attr_reader :node
      def initialize(node)
        @node = node
      end
      def typename
        @node.name
      end
      def narrow(obj)
        @node.idltype.narrow(obj)
      end
      def resolved_type
        node.idltype.resolved_type
      end
      def is_complete?
        resolved_type.is_complete?
      end
    end

    class Integer < Type
      def narrow(obj)
        typeerror(obj) unless ::Integer === obj
        typeerror(obj) unless self.class::Range === obj
        obj
      end

      def range_length
        1 + (self.class::Range.last - self.class::Range.first)
      end

      def Integer.newclass(range)
        k = Class.new(self)
        k.const_set("Range", range)
        k
      end
    end
    Octet     = Integer.newclass(0..0xFF)
    UShort    = Integer.newclass(0..0xFFFF)
    ULong     = Integer.newclass(0..0xFFFFFFFF)
    ULongLong = Integer.newclass(0..0xFFFFFFFFFFFFFFFF)
    Short     = Integer.newclass(-0x8000...0x8000)
    Long      = Integer.newclass(-0x80000000...0x80000000)
    LongLong  = Integer.newclass(-0x8000000000000000...0x8000000000000000)

    class Boolean < Type
      Range = [true, false]
      def narrow(obj)
        typeerror(obj) unless [TrueClass, FalseClass].include? obj.class
        obj
      end
      def range_length
        2
      end
    end
    class Char < Type
      def narrow(obj)
        typeerror(obj) unless ::Integer === obj
        typeerror(obj) unless (0..255) === obj
        obj
      end
      def range_length
        256
      end
    end
    class Float < Type
      def narrow(obj)
        typeerror(obj) unless ::Float === obj
        obj
      end
    end
    class Double < Float; end
    class LongDouble < Float; end
    class Fixed < Type
      def narrow(obj)
        typeerror(obj)
        obj
      end
    end

    class String < Type
      attr_reader :size
      def length; @size; end

      def initialize(size = nil)
        @size = size
      end
      def narrow(obj)
        typeerror(obj) unless ::String === obj
        if @size.nil?
          obj
        elsif @size < obj.size
          typeerror(obj)
        elsif @size > obj.size
          obj + (" " * (@size - obj.size))
        else
          obj
        end
      end
    end

    class Sequence < Type
      attr_reader :node, :size, :basetype
      attr_accessor :recursive
      def length; @size; end
      def initialize(t, size)
        @basetype = t
        @size = size
        @typename = format("sequence<%s%s>", t.typename,
			                     if @size.nil? then "" else ", #{size.to_s}" end)
        @recursive = false
      end
      def typename
        @typename
      end
      def narrow(obj)
        typeerror(obj)
      end
      def is_complete?
        @basetype.resolved_type.is_complete?
      end
      def incomplete_type_node
        if @recursive
          mtype = @basetype
          while mtype.resolved_type.is_a? IDL::Type::Sequence
            mtype = mtype.resolved_type.basetype
          end
          while mtype.is_a? IDL::Type::ScopedName
            case mtype.node.idltype
            when IDL::Type::Struct, IDL::Type::Union
              return mtype.node
            end
            mtype = mtype.node.idltype
          end
        end
        nil
      end
    end

    class Array < Type
      attr_reader :node, :basetype
      attr_reader :sizes
      def initialize(t, sizes)
        @basetype = t
        if sizes.nil?
          @sizes = []
          @typename = t.typename + "[]"
        else
          @sizes = sizes
          @typename = t.typename + sizes.collect{ |s| "[#{s.to_s}]"}.join
        end
      end
      def typename
        @typename
      end
      def narrow(obj)
        typeerror(obj)
      end
      def is_complete?
        @basetype.resolved_type.is_complete?
      end
    end

    class WString < Type
      attr_reader :size
      def length; @size; end

      def initialize(size = nil)
        @size = size
      end
      def narrow(obj)
        typeerror(obj) unless ::Array === obj
        if @size.nil?
          obj
        elsif @size < obj.size
          typeerror(obj)
        elsif @size > obj.size
          obj + (" " * (@size - obj.size))
        else
          obj
        end
      end
    end

    WChar    = Integer.newclass(0..0xFFFF)

    class Any < Type
    end

    class Object < Type
    end

    class Native < Type
    end

    class Interface < Type
      attr_reader :node
      def initialize(node)
        @node = node
      end
    end

    class Valuetype < Type
      attr_reader :node
      def initialize(node)
        @node = node
      end
    end

    class Struct < Type
      attr_reader :node
      def initialize(node)
        @node = node
      end
      def is_complete?
        node.is_defined?
      end
    end

    class Union < Type
      attr_reader :node
      def initialize(node)
        @node = node
      end
      def is_complete?
        node.is_defined?
      end
    end

    class Enum < Type
      attr_reader :node
      def initialize(node)
        @node = node
      end
      def narrow(obj)
        typeerror(obj) unless ::Integer === obj
        typeerror(obj) unless (0...@node.enumerators.length) === obj
        obj
      end
      def range_length
        @node.enumerators.length
      end
    end

  end
end
