#--------------------------------------------------------------------
# Object.rb - basic CORBA Object definitions
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

    def CORBA.is_nil(obj)
      if obj.nil?
        return true
      elsif obj.is_a?(R2CORBA::CORBA::Object) || obj.respond_to?(:_is_nil?)
        return obj._is_nil?()
      end
      true
    end

    module Portable
      module Object
      #-------------------  4.3 "Object Reference Operations"
        #ret InterfaceDef
        def _get_interface()
          raise ::CORBA::NO_IMPLEMENT
        end
      
        #ret boolean
        def _is_nil?()
          raise ::CORBA::NO_IMPLEMENT
        end
      
        #ret ::CORBA::Object
        def _duplicate()
          raise ::CORBA::NO_IMPLEMENT
        end
      
        # ret void
        def _release()
          raise ::CORBA::NO_IMPLEMENT
        end
      
        # ::String logical_type_id
        # ret boolean
        def _is_a?(logical_type_id)
          raise ::CORBA::NO_IMPLEMENT
        end
      
        # ret boolean
        def _non_existent?()
          raise ::CORBA::NO_IMPLEMENT
        end
      
        # ::CORBA::Object other_object
        # ret boolean
        def _is_equivalent?(other_object)
          raise ::CORBA::NO_IMPLEMENT
        end
      
        # Integer(ulong) maximum
        # ret unsigned long
        def _hash(maximum)
          raise ::CORBA::NO_IMPLEMENT
        end

        # ret ::String
        def _repository_id()
          raise ::CORBA::NO_IMPLEMENT
        end

        # ret ::String
        def _interface_repository_id()
          raise ::CORBA::NO_IMPLEMENT
        end

        #def PolicyType policy_type
        # ret Policy
        def _get_policy(policy_type)
          raise ::CORBA::NO_IMPLEMENT
        end
      
        #PolicyList policies
        #SetOverrideType set_add
        #ret ::CORBA::Object
        def _set_policy_overrides(policies, set_add )
          raise ::CORBA::NO_IMPLEMENT
        end

        # ret CORBA::ORB
        def _get_orb()
          raise ::CORBA::NO_IMPLEMENT
        end
      
      end # Object
    end # Portable
  end # CORBA
end # R2CORBA

