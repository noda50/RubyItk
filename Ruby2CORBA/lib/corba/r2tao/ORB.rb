#--------------------------------------------------------------------
# ORB.rb - R2CORBA CORBA orb.idl support
#          (loads precompiled orb.idl)
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
include R2CORBA

require 'corba/r2tao/tao_orb.rb'

## fake Ruby into believing 'orb.rb' has already been loaded
## which is what the IDL compiler will generate for
## '#include "orb.idl"'
$" << 'orb.rb'

module R2CORBA::CORBA

  class ORB
    # String id
    # String name
    # [] members
    # ret TypeCode
    def create_struct_tc(id, name, *members)
      return CORBA::TypeCode::Struct.new(id.to_s.freeze, name.to_s, nil, members)
    end

    # String id
    # String name
    # [] members
    # ret TypeCode
    def create_exception_tc(id, name, *members)
      return CORBA::TypeCode::Except.new(id.to_s.freeze, name.to_s, nil, members)
    end

    # String id
    # String name
    # TypeCode discriminator_type
    # [] members
    # ret TypeCode
    def create_union_tc(id, name, discriminator_type, *members)
      return CORBA::TypeCode::Union.new(id.to_s.freeze, name.to_s, nil, discriminator_type, members)
    end

    # String id
    # String name
    # [] members
    # ret TypeCode
    def create_enum_tc(id, name, *members)
      return CORBA::TypeCode::Enum.new(id.to_s.freeze, name.to_s, members)
    end

    # String id
    # String name
    # TypeCode original_type
    # ret TypeCode
    def create_alias_tc(id, name, original_type)
      return CORBA::TypeCode::Alias.new(id.to_s.freeze, name.to_s, nil, original_type)
    end

    # String id
    # String name
    # ret TypeCode
    def create_interface_tc(id, name)
      return CORBA::TypeCode::ObjectRef.new(id.to_s.freeze, name.to_s, nil)
    end

    # Integer bound
    # ret TypeCode
    def create_string_tc(bound=nil)
      return CORBA::TypeCode::String.new(bound)
    end

    # Integer bound
    # ret TypeCode
    def create_wstring_tc(bound=nil)
      return CORBA::TypeCode::WString.new(bound)
    end

    # Integer bound
    # TypeCode element_type
    # ret TypeCode
    def create_sequence_tc(bound, element_type)
      return CORBA::TypeCode::Sequence.new(element_type, bound)
    end

    # Integer length
    # TypeCode element_type
    # ret TypeCode
    def create_array_tc(length, element_type)
      return CORBA::TypeCode::Array.new(element_type, length)
    end

    # String id
    # ret TypeCode
    def create_recursive_tc(id)
      return CORBA::TypeCode::Recursive.new(id.to_s.freeze)
    end
  end

end