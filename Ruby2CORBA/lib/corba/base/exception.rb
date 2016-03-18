#--------------------------------------------------------------------
# exception.rb - basic CORBA Exception definitions
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
    class Exception < StandardError
      def Exception.define_exceptions(mod)
        mod.module_eval %Q{
          class UserException < CORBA::Exception; end

          class InternalError < StandardError; end

          class SystemException < CORBA::Exception
            @@exception_types = {}
            def SystemException.register_type(klass)
              @@exception_types[klass::Id] = klass
            end
            def SystemException.raise(id, reason, minor, completed)
              if @@exception_types[id.to_s].nil?
                Kernel.raise InternalError,
                      "Unknown SystemException raised: " +
                      id.to_s+' ['+reason.to_s+']'
              else
                Kernel.raise @@exception_types[id.to_s].new(reason,minor,completed)
              end
            end
            def initialize(reason="", minor=0, completed=nil)
              super(reason)
              @reason, @minor, @completed = reason, minor, completed
              @ids = [self.class::Id]
            end
            attr_accessor :reason, :minor, :completed, :ids
            def _ids; @ids; end
            def _interface_repository_id
              self.class::Id
            end
          end
        COMPLETED_YES, COMPLETED_NO, COMPLETED_MAYBE = (0..2).to_a
        }
        [
          'UNKNOWN', 'BAD_PARAM', 'NO_MEMORY', 'IMP_LIMIT', 'COMM_FAILURE', 'INV_OBJREF', 'OBJECT_NOT_EXIST', 'NO_PERMISSION', 'INTERNAL', 'MARSHAL', 'INITIALIZE', 'NO_IMPLEMENT',
          'BAD_TYPECODE', 'BAD_OPERATION', 'NO_RESOURCES', 'NO_RESPONSE', 'PERSIST_STORE', 'BAD_INV_ORDER', 'TRANSIENT', 'FREE_MEM', 'INV_IDENT', 'INV_FLAG', 'INTF_REPOS', 'BAD_CONTEXT',
          'OBJ_ADAPTER', 'DATA_CONVERSION', 'INV_POLICY', 'REBIND', 'TIMEOUT', 'TRANSACTION_UNAVAILABLE', 'TRANSACTION_MODE', 'TRANSACTION_REQUIRED', 'TRANSACTION_ROLLEDBACK',
          'INVALID_TRANSACTION', 'CODESET_INCOMPATIBLE', 'BAD_QOS', 'INVALID_ACTIVITY', 'ACTIVITY_COMPLETED', 'ACTIVITY_REQUIRED', 'THREAD_CANCELLED'
        ].each do |s| mod.module_eval %Q{
            class #{s} < SystemException
              def initialize(*args)
                super
              end
              Id = "IDL:omg.org/CORBA/#{s}:1.0"
              SystemException.register_type(self)
            end}
          end
      end
    end # Exception

    # create all CORBA exception definitions
    Exception.define_exceptions(self)

  end # CORBA
end # R2CORBA
