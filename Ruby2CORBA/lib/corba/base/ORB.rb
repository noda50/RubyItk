#--------------------------------------------------------------------
# ORB.rb - basic CORBA ORB definitions
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
require 'corba/base/Object.rb'

module R2CORBA
  module CORBA

    def CORBA.ORB_init(*args)
      # actual CORBA wrapper implementation implements
      # the ORB.init method
      self::ORB.init(*args)
    end

    module Portable
      module ORB
        #obj ::CORBA::Object
        #ret ::String
        def object_to_string(obj)
          raise CORBA::NO_IMPLEMENT
        end

        #str ::String
        #ret ::CORBA::Object
        def string_to_object(str)
          raise CORBA::NO_IMPLEMENT
        end

        #str ::Integer
        #ret ::CORBA::NVList
        def create_list(count)
          raise CORBA::NO_IMPLEMENT
        end

        #str OperationDef
        #ret ::CORBA::NVList
        def create_operation_list(oper)
          raise CORBA::NO_IMPLEMENT
        end

        #ret Context
        def get_default_context()
          raise CORBA::NO_IMPLEMENT
        end

        #req RequestSeq
        #ret void
        def send_multiple_request_oneway(req)
          raise CORBA::NO_IMPLEMENT
        end

        #req RequestSeq
        #ret void
        def send_multiple_request_deferred(req)
          raise CORBA::NO_IMPLEMENT
        end

        #ret boolean
        def poll_next_response()
          raise CORBA::NO_IMPLEMENT
        end

        #ret Request
        def get_next_response()
          raise CORBA::NO_IMPLEMENT
        end

#  Service information operations
        # ServiceType service_type
        # ret [boolean, ServiceInformation]
        def get_service_information(service_type)
          raise CORBA::NO_IMPLEMENT
        end

        # ret [::String, ...]
        def list_initial_services()
          raise CORBA::NO_IMPLEMENT
        end

=begin
// Initial reference operation
=end
        # ::String identifier
        # ret Object
        # raises InvalidName
        def resolve_initial_references(identifier)
          raise ::CORBA::NO_IMPLEMENT
        end

        # ::String identifier
        # CORBA::Object obj
        # ret void
        # raises InvalidName
        def register_initial_reference(identifier, obj)
          raise ::CORBA::NO_IMPLEMENT
        end

=begin
// Type code creation operations
=end
        # RepositoryId id
        # Identifier name
        # StructMemberSeq members
        # ret TypeCode
        def create_struct_tc(id, name, members)
          raise ::CORBA::NO_IMPLEMENT
        end

        # RepositoryId id
        # Identifier name
        # TypeCode discriminator_type
        # UnionMemberSeq members
        # ret TypeCode
        def create_union_tc(id, name, discriminator_type, members)
          raise ::CORBA::NO_IMPLEMENT
        end

        # RepositoryId id
        # Identifier name
        # EnumMemberSeq members
        # ret TypeCode
        def create_enum_tc(id, name, members)
          raise ::CORBA::NO_IMPLEMENT
        end

        # RepositoryId id
        # Identifier name
        # TypeCode original_type
        # ret TypeCode
        def create_alias_tc(id, name, original_type)
          raise ::CORBA::NO_IMPLEMENT
        end

        # RepositoryId id
        # Identifier name
        # StructMemberSeq members
        # ret TypeCode
        def create_exception_tc(id, name, members)
          raise ::CORBA::NO_IMPLEMENT
        end

        # RepositoryId id
        # Identifier name
        # ret TypeCode
        def create_interface_tc(id, name)
          raise ::CORBA::NO_IMPLEMENT
        end

        # Integer bound
        # ret TypeCode
        def create_string_tc(bound)
          raise ::CORBA::NO_IMPLEMENT
        end

        # Integer(ulong) bound
        # ret TypeCode
        def create_wstring_tc(bound)
          raise ::CORBA::NO_IMPLEMENT
        end

        # Integer(ushort) digits
        # Integer(short) scale
        # ret TypeCode
        def create_fixed_tc(digits, scale)
          raise ::CORBA::NO_IMPLEMENT
        end

        # Integer(ulong) bound
        # TypeCode element_type
        # ret TypeCode
        def create_sequence_tc(bound, element_type)
          raise ::CORBA::NO_IMPLEMENT
        end

        # Integer(ulong) length
        # TypeCode element_type
        # ret TypeCode
        def create_array_tc(length, element_type)
          raise ::CORBA::NO_IMPLEMENT
        end

        # RepositoryId id
        # Identifier name
        # ValueModifier type_modifier
        # TypeCode concrete_base
        # ValueMemberSeq members
        # ret TypeCode
        def create_value_tc(id, name, type_modifier, concrete_base, members)
          raise ::CORBA::NO_IMPLEMENT
        end

        # RepositoryId id
        # Identifier name
        # TypeCode boxed_type
        # ret TypeCode
        def create_value_box_tc (id, name, boxed_type)
          raise ::CORBA::NO_IMPLEMENT
        end

        # RepositoryId id
        # Identifier name
        # ret TypeCode
        def create_native_tc(id, name)
          raise ::CORBA::NO_IMPLEMENT
        end

        # RepositoryId id
        # ret TypeCode
        def create_recursive_tc(id)
          raise ::CORBA::NO_IMPLEMENT
        end

        # RepositoryId id
        # Identifier name
        # ret TypeCode
        def create_abstract_interface_tc(id, name)
          raise ::CORBA::NO_IMPLEMENT
        end

=begin
// Thread related operations
=end

        # ret boolean
        def work_pending()
          raise ::CORBA::NO_IMPLEMENT
        end

        # ret void
        def perform_work()
          raise ::CORBA::NO_IMPLEMENT
        end

        # ret void
        def run()
          raise ::CORBA::NO_IMPLEMENT
        end

        # boolean wait_for_completion
        # ret void
        def shutdown(wait_for_completion)
          raise ::CORBA::NO_IMPLEMENT
        end

        # ret void
        def destroy()
          raise ::CORBA::NO_IMPLEMENT
        end

=begin
// Policy related operations
=end

        # PolicyType type
        # any val
        #ret Policy
        #raises PolicyError
        def create_policy(type, val)
          raise ::CORBA::NO_IMPLEMENT
        end

=begin
// Value factory operations
=end
        # RepositoryId id
        # ValueFactory factory
        #ret ValueFactory
        def register_value_factory(id, factory)
          raise ::CORBA::NO_IMPLEMENT
        end

        # RepositoryId id
        # ret void
        def unregister_value_factory(id)
          raise ::CORBA::NO_IMPLEMENT
        end

        # RepositoryId id
        #ret ValueFactory
        def lookup_value_factory(id)
          raise ::CORBA::NO_IMPLEMENT
        end
      end # ORB
    end # Portable

=begin
 Signal trapping
=end
  private
    @@sigreg = {}
    def CORBA.signal_numbers
      [1, # HUP
       2, # INT
       3, # QUIT
       4, # ILL
       5, # TRAP
       6, # ABRT
       7, # BUS
       8, # FPE
       10, # USR1
       11, # SEGV
       12, # USR2
       13, # SIGPIPE
       14, # ALRM
       15, # TERM
       17, # CHLD
       18, # CONT
       19, # STOP
       ] + (RUBY_PLATFORM =~ /win32/ ?
              [] :
              [23, 30, 31]) # URG, PWR, SYS
    end

    def CORBA.handled_signals
      @@sigreg.clear
      sigs = self.signal_numbers.collect do |signum|
        sigcmd = Signal.trap(signum, 'DEFAULT')
        Signal.trap(signum, sigcmd)
        @@sigreg[signum] = sigcmd
        if sigcmd.respond_to?(:call) or ['IGNORE','SIG_IGN','EXIT'].include?(sigcmd.to_s)
          signum
        else
          nil
        end
      end.compact
      sigs
    end

    def CORBA.handle_signal(signum)
      if @@sigreg.has_key?(signum)
        if @@sigreg[signum].respond_to?(:call)
          @@sigreg[signum].call
        elsif @@sigreg[signum].to_s == 'EXIT'
          Kernel.exit!(signum)
        end
      end
    end
  end # CORBA
end # R2CORBA
