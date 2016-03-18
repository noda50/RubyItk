#--------------------------------------------------------------------
# expression.rb - IDL Expression classes
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

module IDL
  class Expression
    attr_reader :idltype
    attr_reader :value
    def typename; @idltype.typename; end

    class Value < Expression
      def initialize(type, val)
        @idltype = type
        @value = @idltype.narrow(val)
      end
    end
    class ScopedName < Expression
      attr_reader :node
      def initialize(node)
        if $DEBUG
          if not IDL::Const === node
            raise RuntimeError,
              "#{node.scoped_name} must be constant: #{node.type.name}."
          end
        end
        @node = node
        @idltype = node.idltype
        @value = @idltype.narrow(node.value)
      end
    end

    class Operation < Expression
      NUMBER_OF_OPERANDS = nil
      
      attr_reader :operands
      def initialize(*operands)
        n = self.type::NUMBER_OF_OPERANDS

        if operands.size != n
          raise RuntimeError,
            format("%s must receive %d operand%s.",
            self.typename, n, if (n>1) then "s" else "" end)
        end

        @idltype = self.type.suite_type(*(operands.collect{|o| o.idltype}))
        @value = calculate(*(operands.collect{|o| o.value}))
        @operands = operands
        self.set_type
      end

      def Operation.suite_type(*types)
        types.each do |t|
          if not self::Applicable.include? t.type
            raise RuntimeError,
              "#{self.name} cannot be applicable for #{t.typename}"
          end
        end

        ret = nil
        self::Applicable.each do |t|
          if types.include? t
            ret = t
            break
          end
        end
        ret
      end
      def set_type
      end

      class Unary < Operation
        NUMBER_OF_OPERANDS = 1
        Applicable = nil
      end #of class Unary

      class Integer2 < Operation
        NUMBER_OF_OPERANDS = 2
        Applicable = [
          IDL::Type::LongLong, IDL::Type::ULongLong,
          IDL::Type::Long, IDL::Type::ULong,
          IDL::Type::Short, IDL::Type::UShort,
          IDL::Type::Octet
        ]

        def Integer2.suite_sign(_t, _v)
          [ [IDL::Type::LongLong, IDL::Type::ULongLong],
            [IDL::Type::Long,     IDL::Type::ULong],
            [IDL::Type::Short,    IDL::Type::UShort]
          ].each do |t|
            next unless t.include? _t
            return (if v < 0 then t[0] else t[1] end)
          end
        end

        def set_type
          if Integer2::Applicable.include? @idltype
            @idltype = self.type.suite_sign(@idltype, @value)
          end
        end
      end

      class Boolean2 < Integer2
        Applicable = [
          IDL::Type::Boolean
        ] + Integer2::Applicable

        def Boolean2.checktype(t1, t2)
          superclass.checktype(*types)

          t = IDL::Type::Boolean
          if (t1 == t && t2 != t) or (t1 != t && t2 == t)
            raise RuntimeError,
              "#{self.name} about #{t1.typename} and #{t2.typename} is illegal."
          end
        end
      end

      class Float2 < Integer2
        Applicable = [
          IDL::Type::LongDouble, IDL::Type::Double, IDL::Type::Float,
          IDL::Type::Fixed
        ] + Integer2::Applicable

        def Float2.checktype(t1, t2)
          superclass.checktype(*types)

          # it's expected that Double, LongDouble is a Float.
          s1,s2 = IDL::Type::Float, IDL::Type::Fixed
          if (t1 === s1 && t2 === s2) or (t1 === s2 && t2 === s1)
            raise RuntimeError,
              "#{self.name} about #{t1.typename} and #{t2.typename} is illegal."
          end
        end
      end

      class UnaryPlus < Unary
        Applicable = Float2::Applicable
        def calculate(op)
          op
        end
      end
      class UnaryMinus < Unary
        Applicable = Float2::Applicable
        def calculate(op)
          -op
        end
        def set_type
          @idltype = Integer2.suite_sign(@idltype, @value)
        end
            end
            class UnaryNot < Unary
        Applicable = Integer2::Applicable
        def calculate(op)
          ~op
        end
      end

      class Or < Boolean2
        def calculate(lop,rop); lop | rop; end
      end
      class And < Boolean2
        def calculate(lop,rop); lop & rop; end
      end
      class Xor < Boolean2
        def calculate(lop,rop); lop ^ rop; end
      end

      class Shift < Integer2
        def Shift.suite_type(lop, rop)
          ret = Integer2.suite_type(lop, rop)
          if not (0...64) === rop
            raise RuntimeError,
              "right operand for shift must be in the range 0 <= right operand < 64: #{rop}."
          end
          ret
        end
      end
      class LShift < Shift
        def calculate(lop,rop); lop << rop; end
      end
      class RShift < Shift
        def calculate(lop,rop); lop >> rop; end
      end

      class Add < Float2
        def calculate(lop,rop); lop + rop; end
      end
      class Minus < Float2
        def calculate(lop,rop); lop - rop; end
      end
      class Mult < Float2
        def calculate(lop,rop); lop * rop; end
      end
      class Div < Float2
        def calculate(lop,rop); lop / rop; end
      end
      class Mod < Integer2
        def calculate(lop,rop); lop % rop; end
      end
    end #of class Operation
  end #of class Expression
end
