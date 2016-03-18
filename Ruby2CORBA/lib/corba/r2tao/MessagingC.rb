# -*- Ruby -*-
#
# ****  Code generated by the R2CORBA IDL Compiler ****
# R2CORBA has been developed by:
#        Remedy IT
#        Nijkerk, GLD
#        The Netherlands
#        http://www.remedy.nl  http://www.theaceorb.nl
#

module R2CORBA

  CORBA.implement('tao/Messaging/Messaging.pidl', {}, CORBA::IDL::CLIENT_STUB) {

  ## include
  CORBA.implement('tao/Messaging/Messaging_SyncScope_Policy.pidl', {}, CORBA::IDL::CLIENT_STUB) {

  ## include
  CORBA.implement('tao/Messaging_SyncScope.pidl', {}, CORBA::IDL::CLIENT_STUB) {

  module Messaging

    class SyncScope < CORBA::_tc_short.get_type
      def SyncScope._tc; @@tc_SyncScope ||= CORBA::TypeCode::Alias.new('IDL:omg.org/Messaging/SyncScope:1.0', 'SyncScope', self, CORBA::_tc_short); end
    end # typedef SyncScope
    SYNC_NONE = 0
    SYNC_WITH_TRANSPORT = 1
    SYNC_WITH_SERVER = 2
    SYNC_WITH_TARGET = 3
  end #of module Messaging


  } ## end of include 'tao/Messaging_SyncScope.pidl'

  ## include
  CORBA.implement('tao/Messaging/Messaging_Types.pidl', {}, CORBA::IDL::CLIENT_STUB) {

  module Messaging

    REBIND_POLICY_TYPE = 23
    SYNC_SCOPE_POLICY_TYPE = 24
    REQUEST_PRIORITY_POLICY_TYPE = 25
    REPLY_PRIORITY_POLICY_TYPE = 26
    REQUEST_START_TIME_POLICY_TYPE = 27
    REQUEST_END_TIME_POLICY_TYPE = 28
    REPLY_START_TIME_POLICY_TYPE = 29
    REPLY_END_TIME_POLICY_TYPE = 30
    RELATIVE_REQ_TIMEOUT_POLICY_TYPE = 31
    RELATIVE_RT_TIMEOUT_POLICY_TYPE = 32
    ROUTING_POLICY_TYPE = 33
    MAX_HOPS_POLICY_TYPE = 34
    QUEUE_ORDER_POLICY_TYPE = 35
  end #of module Messaging


  } ## end of include 'tao/Messaging/Messaging_Types.pidl'

  module Messaging


    module SyncScopePolicy  ## interface

      include CORBA::Policy

      Id = 'IDL:omg.org/Messaging/SyncScopePolicy:1.0'.freeze
      Ids = [ Id,
              CORBA::Policy::Id ].freeze

      def SyncScopePolicy._tc; @@tc_SyncScopePolicy ||= CORBA::TypeCode::ObjectRef.new(Id, 'SyncScopePolicy', self); end
      self._tc  # register typecode

      def SyncScopePolicy._narrow(obj)
        return CORBA::Stub.create_stub(obj)._unchecked_narrow!(self)
      end

      def SyncScopePolicy._duplicate(obj)
        obj
      end

      def _interface_repository_id
        self.class::Id
      end


      def synchronization()
        raise ::CORBA::NO_IMPLEMENT.new(
                 'unimplemented attribute on local interface',
                 1, ::CORBA::COMPLETED_NO)
      end #of attribute get_synchronization
    end #of interface SyncScopePolicy
  end #of module Messaging


  } ## end of include 'tao/Messaging/Messaging_SyncScope_Policy.pidl'

  ## include
  CORBA.implement('tao/Messaging/Messaging_RT_Policy.pidl', {}, CORBA::IDL::CLIENT_STUB) {

  ## include
  CORBA.implement('tao/TimeBase.pidl', {}, CORBA::IDL::CLIENT_STUB) {

  module TimeBase

    class TimeT < CORBA::_tc_ulonglong.get_type
      def TimeT._tc; @@tc_TimeT ||= CORBA::TypeCode::Alias.new('IDL:omg.org/TimeBase/TimeT:1.0', 'TimeT', self, CORBA::_tc_ulonglong); end
    end # typedef TimeT
    class InaccuracyT < TimeBase::TimeT
      def InaccuracyT._tc; @@tc_InaccuracyT ||= CORBA::TypeCode::Alias.new('IDL:omg.org/TimeBase/InaccuracyT:1.0', 'InaccuracyT', self,TimeBase::TimeT._tc); end
    end # typedef InaccuracyT
    class TdfT < CORBA::_tc_short.get_type
      def TdfT._tc; @@tc_TdfT ||= CORBA::TypeCode::Alias.new('IDL:omg.org/TimeBase/TdfT:1.0', 'TdfT', self, CORBA::_tc_short); end
    end # typedef TdfT

    class UtcT < CORBA::Portable::Struct

      def UtcT._tc
        @@tc_UtcT ||= CORBA::TypeCode::Struct.new('IDL:omg.org/TimeBase/UtcT:1.0'.freeze, 'UtcT', self,
           [['time', TimeBase::TimeT._tc],
            ['inacclo', CORBA._tc_ulong],
            ['inacchi', CORBA._tc_ushort],
            ['tdf', TimeBase::TdfT._tc]])
      end
      self._tc  # register typecode
      attr_accessor :time
      attr_accessor :inacclo
      attr_accessor :inacchi
      attr_accessor :tdf
      def initialize(*param_)
        @time,
        @inacclo,
        @inacchi,
        @tdf = param_
      end

    end #of struct UtcT

    class IntervalT < CORBA::Portable::Struct

      def IntervalT._tc
        @@tc_IntervalT ||= CORBA::TypeCode::Struct.new('IDL:omg.org/TimeBase/IntervalT:1.0'.freeze, 'IntervalT', self,
           [['lower_bound', TimeBase::TimeT._tc],
            ['upper_bound', TimeBase::TimeT._tc]])
      end
      self._tc  # register typecode
      attr_accessor :lower_bound
      attr_accessor :upper_bound
      def initialize(*param_)
        @lower_bound,
        @upper_bound = param_
      end

    end #of struct IntervalT
  end #of module TimeBase


  } ## end of include 'tao/TimeBase.pidl'

  module Messaging

    class Timeout < TimeBase::TimeT
      def Timeout._tc; @@tc_Timeout ||= CORBA::TypeCode::Alias.new('IDL:omg.org/Messaging/Timeout:1.0', 'Timeout', self,TimeBase::TimeT._tc); end
    end # typedef Timeout

    module RelativeRoundtripTimeoutPolicy  ## interface

      include CORBA::Policy

      Id = 'IDL:omg.org/Messaging/RelativeRoundtripTimeoutPolicy:1.0'.freeze
      Ids = [ Id,
              CORBA::Policy::Id ].freeze

      def RelativeRoundtripTimeoutPolicy._tc; @@tc_RelativeRoundtripTimeoutPolicy ||= CORBA::TypeCode::ObjectRef.new(Id, 'RelativeRoundtripTimeoutPolicy', self); end
      self._tc  # register typecode

      def RelativeRoundtripTimeoutPolicy._narrow(obj)
        return CORBA::Stub.create_stub(obj)._unchecked_narrow!(self)
      end

      def RelativeRoundtripTimeoutPolicy._duplicate(obj)
        obj
      end

      def _interface_repository_id
        self.class::Id
      end


      def relative_expiry()
        raise ::CORBA::NO_IMPLEMENT.new(
                 'unimplemented attribute on local interface',
                 1, ::CORBA::COMPLETED_NO)
      end #of attribute get_relative_expiry
    end #of interface RelativeRoundtripTimeoutPolicy
  end #of module Messaging


  } ## end of include 'tao/Messaging/Messaging_RT_Policy.pidl'

  ## include
  CORBA.implement('tao/Messaging/Messaging_No_Impl.pidl', {}, CORBA::IDL::CLIENT_STUB) {

  module Messaging

    class Priority < CORBA::_tc_short.get_type
      def Priority._tc; @@tc_Priority ||= CORBA::TypeCode::Alias.new('IDL:omg.org/Messaging/Priority:1.0', 'Priority', self, CORBA::_tc_short); end
    end # typedef Priority
    class RebindMode < CORBA::_tc_short.get_type
      def RebindMode._tc; @@tc_RebindMode ||= CORBA::TypeCode::Alias.new('IDL:omg.org/Messaging/RebindMode:1.0', 'RebindMode', self, CORBA::_tc_short); end
    end # typedef RebindMode
    TRANSPARENT = 0
    NO_REBIND = 1
    NO_RECONNECT = 2
    class RoutingType < CORBA::_tc_short.get_type
      def RoutingType._tc; @@tc_RoutingType ||= CORBA::TypeCode::Alias.new('IDL:omg.org/Messaging/RoutingType:1.0', 'RoutingType', self, CORBA::_tc_short); end
    end # typedef RoutingType
    ROUTE_NONE = 0
    ROUTE_FORWARD = 1
    ROUTE_STORE_AND_FORWARD = 2
    class Ordering < CORBA::_tc_ushort.get_type
      def Ordering._tc; @@tc_Ordering ||= CORBA::TypeCode::Alias.new('IDL:omg.org/Messaging/Ordering:1.0', 'Ordering', self, CORBA::_tc_ushort); end
    end # typedef Ordering
    ORDER_ANY = 1
    ORDER_TEMPORAL = 2
    ORDER_PRIORITY = 4
    ORDER_DEADLINE = 8

    module RebindPolicy  ## interface

      include CORBA::Policy

      Id = 'IDL:omg.org/Messaging/RebindPolicy:1.0'.freeze
      Ids = [ Id,
              CORBA::Policy::Id ].freeze

      def RebindPolicy._tc; @@tc_RebindPolicy ||= CORBA::TypeCode::ObjectRef.new(Id, 'RebindPolicy', self); end
      self._tc  # register typecode

      def RebindPolicy._narrow(obj)
        return CORBA::Stub.create_stub(obj)._unchecked_narrow!(self)
      end

      def RebindPolicy._duplicate(obj)
        obj
      end

      def _interface_repository_id
        self.class::Id
      end


      def rebind_mode()
        raise ::CORBA::NO_IMPLEMENT.new(
                 'unimplemented attribute on local interface',
                 1, ::CORBA::COMPLETED_NO)
      end #of attribute get_rebind_mode
    end #of interface RebindPolicy

    class PriorityRange < CORBA::Portable::Struct

      def PriorityRange._tc
        @@tc_PriorityRange ||= CORBA::TypeCode::Struct.new('IDL:omg.org/Messaging/PriorityRange:1.0'.freeze, 'PriorityRange', self,
           [['min', Messaging::Priority._tc],
            ['max', Messaging::Priority._tc]])
      end
      self._tc  # register typecode
      attr_accessor :min
      attr_accessor :max
      def initialize(*param_)
        @min,
        @max = param_
      end

    end #of struct PriorityRange

    module RequestPriorityPolicy  ## interface

      include CORBA::Policy

      Id = 'IDL:omg.org/Messaging/RequestPriorityPolicy:1.0'.freeze
      Ids = [ Id,
              CORBA::Policy::Id ].freeze

      def RequestPriorityPolicy._tc; @@tc_RequestPriorityPolicy ||= CORBA::TypeCode::ObjectRef.new(Id, 'RequestPriorityPolicy', self); end
      self._tc  # register typecode

      def RequestPriorityPolicy._narrow(obj)
        return CORBA::Stub.create_stub(obj)._unchecked_narrow!(self)
      end

      def RequestPriorityPolicy._duplicate(obj)
        obj
      end

      def _interface_repository_id
        self.class::Id
      end


      def priority_range()
        raise ::CORBA::NO_IMPLEMENT.new(
                 'unimplemented attribute on local interface',
                 1, ::CORBA::COMPLETED_NO)
      end #of attribute get_priority_range
    end #of interface RequestPriorityPolicy

    module ReplyPriorityPolicy  ## interface

      include CORBA::Policy

      Id = 'IDL:omg.org/Messaging/ReplyPriorityPolicy:1.0'.freeze
      Ids = [ Id,
              CORBA::Policy::Id ].freeze

      def ReplyPriorityPolicy._tc; @@tc_ReplyPriorityPolicy ||= CORBA::TypeCode::ObjectRef.new(Id, 'ReplyPriorityPolicy', self); end
      self._tc  # register typecode

      def ReplyPriorityPolicy._narrow(obj)
        return CORBA::Stub.create_stub(obj)._unchecked_narrow!(self)
      end

      def ReplyPriorityPolicy._duplicate(obj)
        obj
      end

      def _interface_repository_id
        self.class::Id
      end


      def priority_range()
        raise ::CORBA::NO_IMPLEMENT.new(
                 'unimplemented attribute on local interface',
                 1, ::CORBA::COMPLETED_NO)
      end #of attribute get_priority_range
    end #of interface ReplyPriorityPolicy

    module RequestStartTimePolicy  ## interface

      include CORBA::Policy

      Id = 'IDL:omg.org/Messaging/RequestStartTimePolicy:1.0'.freeze
      Ids = [ Id,
              CORBA::Policy::Id ].freeze

      def RequestStartTimePolicy._tc; @@tc_RequestStartTimePolicy ||= CORBA::TypeCode::ObjectRef.new(Id, 'RequestStartTimePolicy', self); end
      self._tc  # register typecode

      def RequestStartTimePolicy._narrow(obj)
        return CORBA::Stub.create_stub(obj)._unchecked_narrow!(self)
      end

      def RequestStartTimePolicy._duplicate(obj)
        obj
      end

      def _interface_repository_id
        self.class::Id
      end


      def start_time()
        raise ::CORBA::NO_IMPLEMENT.new(
                 'unimplemented attribute on local interface',
                 1, ::CORBA::COMPLETED_NO)
      end #of attribute get_start_time
    end #of interface RequestStartTimePolicy

    module RequestEndTimePolicy  ## interface

      include CORBA::Policy

      Id = 'IDL:omg.org/Messaging/RequestEndTimePolicy:1.0'.freeze
      Ids = [ Id,
              CORBA::Policy::Id ].freeze

      def RequestEndTimePolicy._tc; @@tc_RequestEndTimePolicy ||= CORBA::TypeCode::ObjectRef.new(Id, 'RequestEndTimePolicy', self); end
      self._tc  # register typecode

      def RequestEndTimePolicy._narrow(obj)
        return CORBA::Stub.create_stub(obj)._unchecked_narrow!(self)
      end

      def RequestEndTimePolicy._duplicate(obj)
        obj
      end

      def _interface_repository_id
        self.class::Id
      end


      def end_time()
        raise ::CORBA::NO_IMPLEMENT.new(
                 'unimplemented attribute on local interface',
                 1, ::CORBA::COMPLETED_NO)
      end #of attribute get_end_time
    end #of interface RequestEndTimePolicy

    module ReplyStartTimePolicy  ## interface

      include CORBA::Policy

      Id = 'IDL:omg.org/Messaging/ReplyStartTimePolicy:1.0'.freeze
      Ids = [ Id,
              CORBA::Policy::Id ].freeze

      def ReplyStartTimePolicy._tc; @@tc_ReplyStartTimePolicy ||= CORBA::TypeCode::ObjectRef.new(Id, 'ReplyStartTimePolicy', self); end
      self._tc  # register typecode

      def ReplyStartTimePolicy._narrow(obj)
        return CORBA::Stub.create_stub(obj)._unchecked_narrow!(self)
      end

      def ReplyStartTimePolicy._duplicate(obj)
        obj
      end

      def _interface_repository_id
        self.class::Id
      end


      def start_time()
        raise ::CORBA::NO_IMPLEMENT.new(
                 'unimplemented attribute on local interface',
                 1, ::CORBA::COMPLETED_NO)
      end #of attribute get_start_time
    end #of interface ReplyStartTimePolicy

    module ReplyEndTimePolicy  ## interface

      include CORBA::Policy

      Id = 'IDL:omg.org/Messaging/ReplyEndTimePolicy:1.0'.freeze
      Ids = [ Id,
              CORBA::Policy::Id ].freeze

      def ReplyEndTimePolicy._tc; @@tc_ReplyEndTimePolicy ||= CORBA::TypeCode::ObjectRef.new(Id, 'ReplyEndTimePolicy', self); end
      self._tc  # register typecode

      def ReplyEndTimePolicy._narrow(obj)
        return CORBA::Stub.create_stub(obj)._unchecked_narrow!(self)
      end

      def ReplyEndTimePolicy._duplicate(obj)
        obj
      end

      def _interface_repository_id
        self.class::Id
      end


      def end_time()
        raise ::CORBA::NO_IMPLEMENT.new(
                 'unimplemented attribute on local interface',
                 1, ::CORBA::COMPLETED_NO)
      end #of attribute get_end_time
    end #of interface ReplyEndTimePolicy

    module RelativeRequestTimeoutPolicy  ## interface

      include CORBA::Policy

      Id = 'IDL:omg.org/Messaging/RelativeRequestTimeoutPolicy:1.0'.freeze
      Ids = [ Id,
              CORBA::Policy::Id ].freeze

      def RelativeRequestTimeoutPolicy._tc; @@tc_RelativeRequestTimeoutPolicy ||= CORBA::TypeCode::ObjectRef.new(Id, 'RelativeRequestTimeoutPolicy', self); end
      self._tc  # register typecode

      def RelativeRequestTimeoutPolicy._narrow(obj)
        return CORBA::Stub.create_stub(obj)._unchecked_narrow!(self)
      end

      def RelativeRequestTimeoutPolicy._duplicate(obj)
        obj
      end

      def _interface_repository_id
        self.class::Id
      end


      def relative_expiry()
        raise ::CORBA::NO_IMPLEMENT.new(
                 'unimplemented attribute on local interface',
                 1, ::CORBA::COMPLETED_NO)
      end #of attribute get_relative_expiry
    end #of interface RelativeRequestTimeoutPolicy

    class RoutingTypeRange < CORBA::Portable::Struct

      def RoutingTypeRange._tc
        @@tc_RoutingTypeRange ||= CORBA::TypeCode::Struct.new('IDL:omg.org/Messaging/RoutingTypeRange:1.0'.freeze, 'RoutingTypeRange', self,
           [['min', Messaging::RoutingType._tc],
            ['max', Messaging::RoutingType._tc]])
      end
      self._tc  # register typecode
      attr_accessor :min
      attr_accessor :max
      def initialize(*param_)
        @min,
        @max = param_
      end

    end #of struct RoutingTypeRange

    module RoutingPolicy  ## interface

      include CORBA::Policy

      Id = 'IDL:omg.org/Messaging/RoutingPolicy:1.0'.freeze
      Ids = [ Id,
              CORBA::Policy::Id ].freeze

      def RoutingPolicy._tc; @@tc_RoutingPolicy ||= CORBA::TypeCode::ObjectRef.new(Id, 'RoutingPolicy', self); end
      self._tc  # register typecode

      def RoutingPolicy._narrow(obj)
        return CORBA::Stub.create_stub(obj)._unchecked_narrow!(self)
      end

      def RoutingPolicy._duplicate(obj)
        obj
      end

      def _interface_repository_id
        self.class::Id
      end


      def routing_range()
        raise ::CORBA::NO_IMPLEMENT.new(
                 'unimplemented attribute on local interface',
                 1, ::CORBA::COMPLETED_NO)
      end #of attribute get_routing_range
    end #of interface RoutingPolicy

    module MaxHopsPolicy  ## interface

      include CORBA::Policy

      Id = 'IDL:omg.org/Messaging/MaxHopsPolicy:1.0'.freeze
      Ids = [ Id,
              CORBA::Policy::Id ].freeze

      def MaxHopsPolicy._tc; @@tc_MaxHopsPolicy ||= CORBA::TypeCode::ObjectRef.new(Id, 'MaxHopsPolicy', self); end
      self._tc  # register typecode

      def MaxHopsPolicy._narrow(obj)
        return CORBA::Stub.create_stub(obj)._unchecked_narrow!(self)
      end

      def MaxHopsPolicy._duplicate(obj)
        obj
      end

      def _interface_repository_id
        self.class::Id
      end


      def max_hops()
        raise ::CORBA::NO_IMPLEMENT.new(
                 'unimplemented attribute on local interface',
                 1, ::CORBA::COMPLETED_NO)
      end #of attribute get_max_hops
    end #of interface MaxHopsPolicy

    module QueueOrderPolicy  ## interface

      include CORBA::Policy

      Id = 'IDL:omg.org/Messaging/QueueOrderPolicy:1.0'.freeze
      Ids = [ Id,
              CORBA::Policy::Id ].freeze

      def QueueOrderPolicy._tc; @@tc_QueueOrderPolicy ||= CORBA::TypeCode::ObjectRef.new(Id, 'QueueOrderPolicy', self); end
      self._tc  # register typecode

      def QueueOrderPolicy._narrow(obj)
        return CORBA::Stub.create_stub(obj)._unchecked_narrow!(self)
      end

      def QueueOrderPolicy._duplicate(obj)
        obj
      end

      def _interface_repository_id
        self.class::Id
      end


      def allowed_orders()
        raise ::CORBA::NO_IMPLEMENT.new(
                 'unimplemented attribute on local interface',
                 1, ::CORBA::COMPLETED_NO)
      end #of attribute get_allowed_orders
    end #of interface QueueOrderPolicy
  end #of module Messaging


  } ## end of include 'tao/Messaging/Messaging_No_Impl.pidl'

  ## include
  CORBA.implement('tao/Messaging/TAO_Ext.pidl', {}, CORBA::IDL::CLIENT_STUB) {

  module TAO

    CONNECTION_TIMEOUT_POLICY_TYPE = 1413545992

    module ConnectionTimeoutPolicy  ## interface

      include CORBA::Policy

      Id = 'IDL:tao/TAO/ConnectionTimeoutPolicy:1.0'.freeze
      Ids = [ Id,
              CORBA::Policy::Id ].freeze

      def ConnectionTimeoutPolicy._tc; @@tc_ConnectionTimeoutPolicy ||= CORBA::TypeCode::ObjectRef.new(Id, 'ConnectionTimeoutPolicy', self); end
      self._tc  # register typecode

      def ConnectionTimeoutPolicy._narrow(obj)
        return CORBA::Stub.create_stub(obj)._unchecked_narrow!(self)
      end

      def ConnectionTimeoutPolicy._duplicate(obj)
        obj
      end

      def _interface_repository_id
        self.class::Id
      end


      def relative_expiry()
        raise ::CORBA::NO_IMPLEMENT.new(
                 'unimplemented attribute on local interface',
                 1, ::CORBA::COMPLETED_NO)
      end #of attribute get_relative_expiry
    end #of interface ConnectionTimeoutPolicy
    class BufferingConstraintMode < CORBA::_tc_ushort.get_type
      def BufferingConstraintMode._tc; @@tc_BufferingConstraintMode ||= CORBA::TypeCode::Alias.new('IDL:tao/TAO/BufferingConstraintMode:1.0', 'BufferingConstraintMode', self, CORBA::_tc_ushort); end
    end # typedef BufferingConstraintMode
    BUFFER_FLUSH = 0
    BUFFER_TIMEOUT = 1
    BUFFER_MESSAGE_COUNT = 2
    BUFFER_MESSAGE_BYTES = 4

    class BufferingConstraint < CORBA::Portable::Struct

      def BufferingConstraint._tc
        @@tc_BufferingConstraint ||= CORBA::TypeCode::Struct.new('IDL:tao/TAO/BufferingConstraint:1.0'.freeze, 'BufferingConstraint', self,
           [['mode', TAO::BufferingConstraintMode._tc],
            ['timeout', TimeBase::TimeT._tc],
            ['message_count', CORBA._tc_ulong],
            ['message_bytes', CORBA._tc_ulong]])
      end
      self._tc  # register typecode
      attr_accessor :mode
      attr_accessor :timeout
      attr_accessor :message_count
      attr_accessor :message_bytes
      def initialize(*param_)
        @mode,
        @timeout,
        @message_count,
        @message_bytes = param_
      end

    end #of struct BufferingConstraint
    BUFFERING_CONSTRAINT_POLICY_TYPE = 1413545985

    module BufferingConstraintPolicy  ## interface

      include CORBA::Policy

      Id = 'IDL:tao/TAO/BufferingConstraintPolicy:1.0'.freeze
      Ids = [ Id,
              CORBA::Policy::Id ].freeze

      def BufferingConstraintPolicy._tc; @@tc_BufferingConstraintPolicy ||= CORBA::TypeCode::ObjectRef.new(Id, 'BufferingConstraintPolicy', self); end
      self._tc  # register typecode

      def BufferingConstraintPolicy._narrow(obj)
        return CORBA::Stub.create_stub(obj)._unchecked_narrow!(self)
      end

      def BufferingConstraintPolicy._duplicate(obj)
        obj
      end

      def _interface_repository_id
        self.class::Id
      end


      def buffering_constraint()
        raise ::CORBA::NO_IMPLEMENT.new(
                 'unimplemented attribute on local interface',
                 1, ::CORBA::COMPLETED_NO)
      end #of attribute get_buffering_constraint
    end #of interface BufferingConstraintPolicy
  end #of module TAO


  } ## end of include 'tao/Messaging/TAO_Ext.pidl'

  ## include
  CORBA.implement('tao/Messaging/Pollable.pidl', {}, CORBA::IDL::CLIENT_STUB) {

  module CORBA

    module PollableSet; end  ## interface forward

    module Pollable  ## interface


      Id = 'IDL:omg.org/CORBA/Pollable:1.0'.freeze
      Ids = [ Id ].freeze

      def Pollable._tc; @@tc_Pollable ||= CORBA::TypeCode::ObjectRef.new(Id, 'Pollable', self); end
      self._tc  # register typecode

      def Pollable._narrow(obj)
        return CORBA::Stub.create_stub(obj)._unchecked_narrow!(self)
      end

      def Pollable._duplicate(obj)
        obj
      end

      def _interface_repository_id
        self.class::Id
      end


      def is_ready(timeout)
        raise ::CORBA::NO_IMPLEMENT.new(
                 'unimplemented operation on local interface',
                 1, ::CORBA::COMPLETED_NO)
      end #of operation is_ready

      def create_pollable_set()
        raise ::CORBA::NO_IMPLEMENT.new(
                 'unimplemented operation on local interface',
                 1, ::CORBA::COMPLETED_NO)
      end #of operation create_pollable_set
    end #of interface Pollable

    module DIIPollable  ## interface

      include CORBA::Pollable

      Id = 'IDL:omg.org/CORBA/DIIPollable:1.0'.freeze
      Ids = [ Id,
              CORBA::Pollable::Id ].freeze

      def DIIPollable._tc; @@tc_DIIPollable ||= CORBA::TypeCode::ObjectRef.new(Id, 'DIIPollable', self); end
      self._tc  # register typecode

      def DIIPollable._narrow(obj)
        return CORBA::Stub.create_stub(obj)._unchecked_narrow!(self)
      end

      def DIIPollable._duplicate(obj)
        obj
      end

      def _interface_repository_id
        self.class::Id
      end

    end #of interface DIIPollable

    module PollableSet  ## interface


      Id = 'IDL:omg.org/CORBA/PollableSet:1.0'.freeze
      Ids = [ Id ].freeze

      def PollableSet._tc; @@tc_PollableSet ||= CORBA::TypeCode::ObjectRef.new(Id, 'PollableSet', self); end
      self._tc  # register typecode

      def PollableSet._narrow(obj)
        return CORBA::Stub.create_stub(obj)._unchecked_narrow!(self)
      end

      def PollableSet._duplicate(obj)
        obj
      end

      def _interface_repository_id
        self.class::Id
      end


      class NoPossiblePollable < CORBA::UserException

        def NoPossiblePollable._tc
          @@tc_NoPossiblePollable ||= CORBA::TypeCode::Except.new('IDL:omg.org/CORBA/PollableSet/NoPossiblePollable:1.0'.freeze, 'NoPossiblePollable', self)
        end
        self._tc  # register typecode
      end #of exception NoPossiblePollable

      class UnknownPollable < CORBA::UserException

        def UnknownPollable._tc
          @@tc_UnknownPollable ||= CORBA::TypeCode::Except.new('IDL:omg.org/CORBA/PollableSet/UnknownPollable:1.0'.freeze, 'UnknownPollable', self)
        end
        self._tc  # register typecode
      end #of exception UnknownPollable

      def create_dii_pollable()
        raise ::CORBA::NO_IMPLEMENT.new(
                 'unimplemented operation on local interface',
                 1, ::CORBA::COMPLETED_NO)
      end #of operation create_dii_pollable

      def add_pollable(potential)
        raise ::CORBA::NO_IMPLEMENT.new(
                 'unimplemented operation on local interface',
                 1, ::CORBA::COMPLETED_NO)
      end #of operation add_pollable

      def get_ready_pollable(timeout)
        raise ::CORBA::NO_IMPLEMENT.new(
                 'unimplemented operation on local interface',
                 1, ::CORBA::COMPLETED_NO)
      end #of operation get_ready_pollable

      def remove(potential)
        raise ::CORBA::NO_IMPLEMENT.new(
                 'unimplemented operation on local interface',
                 1, ::CORBA::COMPLETED_NO)
      end #of operation remove

      def number_left()
        raise ::CORBA::NO_IMPLEMENT.new(
                 'unimplemented operation on local interface',
                 1, ::CORBA::COMPLETED_NO)
      end #of operation number_left
    end #of interface PollableSet
  end #of module CORBA


  } ## end of include 'tao/Messaging/Pollable.pidl'

  ## include
  CORBA.implement('tao/Messaging/ExceptionHolder.pidl', {}, CORBA::IDL::CLIENT_STUB) {

  ## include
  CORBA.implement('tao/AnyTypeCode/Dynamic.pidl', {}, CORBA::IDL::CLIENT_STUB) {

  ## include
  CORBA.implement('tao/AnyTypeCode/Dynamic_Parameter.pidl', {}, CORBA::IDL::CLIENT_STUB) {

  module Dynamic


    class Parameter < CORBA::Portable::Struct

      def Parameter._tc
        @@tc_Parameter ||= CORBA::TypeCode::Struct.new('IDL:omg.org/Dynamic/Parameter:1.0'.freeze, 'Parameter', self,
           [['argument', CORBA._tc_any],
            ['mode', CORBA::ParameterMode._tc]])
      end
      self._tc  # register typecode
      attr_accessor :argument
      attr_accessor :mode
      def initialize(*param_)
        @argument,
        @mode = param_
      end

    end #of struct Parameter
  end #of module Dynamic


  } ## end of include 'tao/AnyTypeCode/Dynamic_Parameter.pidl'

  module Dynamic

    class ParameterList < Array
      def ParameterList._tc
        @@tc_ParameterList ||= CORBA::TypeCode::Alias.new('IDL:omg.org/Dynamic/ParameterList:1.0', 'ParameterList', self,
          CORBA::TypeCode::Sequence.new(Dynamic::Parameter._tc).freeze)
      end
    end # typedef ParameterList
    class ContextList < CORBA::StringSeq
      def ContextList._tc; @@tc_ContextList ||= CORBA::TypeCode::Alias.new('IDL:omg.org/Dynamic/ContextList:1.0', 'ContextList', self,CORBA::StringSeq._tc); end
    end # typedef ContextList
    class ExceptionList < Array
      def ExceptionList._tc
        @@tc_ExceptionList ||= CORBA::TypeCode::Alias.new('IDL:omg.org/Dynamic/ExceptionList:1.0', 'ExceptionList', self,
          CORBA::TypeCode::Sequence.new(CORBA::TypeCode._tc).freeze)
      end
    end # typedef ExceptionList
    class RequestContext < CORBA::StringSeq
      def RequestContext._tc; @@tc_RequestContext ||= CORBA::TypeCode::Alias.new('IDL:omg.org/Dynamic/RequestContext:1.0', 'RequestContext', self,CORBA::StringSeq._tc); end
    end # typedef RequestContext
  end #of module Dynamic


  } ## end of include 'tao/AnyTypeCode/Dynamic.pidl'

  module Messaging

    class UserExceptionBase; end  ## 'native' type
  end #of module Messaging

  module Messaging


    module ReplyHandler  ## interface


      Id = 'IDL:omg.org/Messaging/ReplyHandler:1.0'.freeze
      Ids = [ Id ].freeze

      def ReplyHandler._tc; @@tc_ReplyHandler ||= CORBA::TypeCode::ObjectRef.new(Id, 'ReplyHandler', self); end
      self._tc  # register typecode

      def ReplyHandler._narrow(obj)
        return CORBA::Stub.create_stub(obj)._narrow!(self)
      end

      def ReplyHandler._duplicate(obj)
        return CORBA::Stub.create_stub(super(obj))._narrow!(self)
      end

      def _interface_repository_id
        self.class::Id
      end

    end #of interface ReplyHandler
  end #of module Messaging


  } ## end of include 'tao/Messaging/ExceptionHolder.pidl'

  } ## end of 'tao/Messaging/Messaging.pidl'
end #of module R2CORBA

# -*- END -*-
