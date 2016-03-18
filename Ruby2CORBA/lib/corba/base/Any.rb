#--------------------------------------------------------------------
# Any.rb - CORBA Any support
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
    class Any
      ## This code is not allowed to raise a Ruby exception since
      ## it used deep inside C++ plugin code and a Ruby exception
      ## would disrupt memory management there.
      ## Make sure to just return 'nil' if no typecode can be found.
      def Any.typecode_for_any(any)
        case any
          when ::CORBA::Any
            return any._tc
          when ::NilClass
            return ::CORBA._tc_null
          when ::Bignum
            return ::CORBA._tc_longlong
          when ::Integer
            return ::CORBA._tc_long
          when ::Float
            return ::CORBA._tc_double
          when ::TrueClass, ::FalseClass
            return ::CORBA._tc_boolean
          when ::String
            return ::CORBA._tc_string
          else
            if any.class.respond_to?(:_tc)
              begin
                tc = any.class._tc
                if tc.is_a? ::CORBA::TypeCode
                  return tc
                end
              rescue
              end
            else
              if any.is_a? ::CORBA::Object
                return ::CORBA._tc_Object
              elsif any.is_a? ::CORBA::TypeCode
                return ::CORBA._tc_TypeCode
              end
            end
        end
        return nil
      end

      def Any.value_for_any(any)
        case any
          when ::CORBA::Any
            return any._value
          else
            return any
        end
      end

      def Any.to_any(o, tc)
        if o.class.respond_to?(:_tc)
          begin
            tc = any.class._tc
            if tc.is_a? ::CORBA::TypeCode
              return o
            end
          rescue
          end
        end
        return self.new(o, tc)
      end

      def _tc
        @__tc
      end
      def _value
        @__value
      end
    protected
      def initialize(o, tc)
        @__tc = tc
        @__value = o
      end
    end
  end
end
