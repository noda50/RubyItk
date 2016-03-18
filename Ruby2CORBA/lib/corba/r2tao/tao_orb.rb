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

  CORBA.implement('orb.idl', {}, CORBA::IDL::CLIENT_STUB) {

  ## include
  CORBA.implement('tao/BooleanSeq.pidl', {}, CORBA::IDL::CLIENT_STUB) {

  module CORBA

    class BooleanSeq < Array
      def BooleanSeq._tc
        @@tc_BooleanSeq ||= CORBA::TypeCode::Alias.new('IDL:omg.org/CORBA/BooleanSeq:1.0', 'BooleanSeq', self,
          CORBA::TypeCode::Sequence.new(CORBA._tc_boolean).freeze)
      end
    end # typedef BooleanSeq
  end #of module CORBA


  } ## end of include 'tao/BooleanSeq.pidl'

  ## include
  CORBA.implement('tao/CharSeq.pidl', {}, CORBA::IDL::CLIENT_STUB) {

  module CORBA

    class CharSeq < String
      def CharSeq._tc
        @@tc_CharSeq ||= CORBA::TypeCode::Alias.new('IDL:omg.org/CORBA/CharSeq:1.0', 'CharSeq', self,
          CORBA::TypeCode::Sequence.new(CORBA._tc_char).freeze)
      end
    end # typedef CharSeq
  end #of module CORBA


  } ## end of include 'tao/CharSeq.pidl'

  ## include
  CORBA.implement('tao/DoubleSeq.pidl', {}, CORBA::IDL::CLIENT_STUB) {

  module CORBA

    class DoubleSeq < Array
      def DoubleSeq._tc
        @@tc_DoubleSeq ||= CORBA::TypeCode::Alias.new('IDL:omg.org/CORBA/DoubleSeq:1.0', 'DoubleSeq', self,
          CORBA::TypeCode::Sequence.new(CORBA._tc_double).freeze)
      end
    end # typedef DoubleSeq
  end #of module CORBA


  } ## end of include 'tao/DoubleSeq.pidl'

  ## include
  CORBA.implement('tao/FloatSeq.pidl', {}, CORBA::IDL::CLIENT_STUB) {

  module CORBA

    class FloatSeq < Array
      def FloatSeq._tc
        @@tc_FloatSeq ||= CORBA::TypeCode::Alias.new('IDL:omg.org/CORBA/FloatSeq:1.0', 'FloatSeq', self,
          CORBA::TypeCode::Sequence.new(CORBA._tc_float).freeze)
      end
    end # typedef FloatSeq
  end #of module CORBA


  } ## end of include 'tao/FloatSeq.pidl'

  ## include
  CORBA.implement('tao/LongDoubleSeq.pidl', {}, CORBA::IDL::CLIENT_STUB) {

  module CORBA

    class LongDoubleSeq < Array
      def LongDoubleSeq._tc
        @@tc_LongDoubleSeq ||= CORBA::TypeCode::Alias.new('IDL:omg.org/CORBA/LongDoubleSeq:1.0', 'LongDoubleSeq', self,
          CORBA::TypeCode::Sequence.new(CORBA._tc_longdouble).freeze)
      end
    end # typedef LongDoubleSeq
  end #of module CORBA


  } ## end of include 'tao/LongDoubleSeq.pidl'

  ## include
  CORBA.implement('tao/LongSeq.pidl', {}, CORBA::IDL::CLIENT_STUB) {

  module CORBA

    class LongSeq < Array
      def LongSeq._tc
        @@tc_LongSeq ||= CORBA::TypeCode::Alias.new('IDL:omg.org/CORBA/LongSeq:1.0', 'LongSeq', self,
          CORBA::TypeCode::Sequence.new(CORBA._tc_long).freeze)
      end
    end # typedef LongSeq
  end #of module CORBA


  } ## end of include 'tao/LongSeq.pidl'

  ## include
  CORBA.implement('tao/OctetSeq.pidl', {}, CORBA::IDL::CLIENT_STUB) {

  module CORBA

    class OctetSeq < String
      def OctetSeq._tc
        @@tc_OctetSeq ||= CORBA::TypeCode::Alias.new('IDL:omg.org/CORBA/OctetSeq:1.0', 'OctetSeq', self,
          CORBA::TypeCode::Sequence.new(CORBA._tc_octet).freeze)
      end
    end # typedef OctetSeq
  end #of module CORBA


  } ## end of include 'tao/OctetSeq.pidl'

  ## include
  CORBA.implement('tao/ShortSeq.pidl', {}, CORBA::IDL::CLIENT_STUB) {

  module CORBA

    class ShortSeq < Array
      def ShortSeq._tc
        @@tc_ShortSeq ||= CORBA::TypeCode::Alias.new('IDL:omg.org/CORBA/ShortSeq:1.0', 'ShortSeq', self,
          CORBA::TypeCode::Sequence.new(CORBA._tc_short).freeze)
      end
    end # typedef ShortSeq
  end #of module CORBA


  } ## end of include 'tao/ShortSeq.pidl'

  ## include
  CORBA.implement('tao/StringSeq.pidl', {}, CORBA::IDL::CLIENT_STUB) {

  module CORBA

    class StringSeq < Array
      def StringSeq._tc
        @@tc_StringSeq ||= CORBA::TypeCode::Alias.new('IDL:omg.org/CORBA/StringSeq:1.0', 'StringSeq', self,
          CORBA::TypeCode::Sequence.new(CORBA._tc_string).freeze)
      end
    end # typedef StringSeq
  end #of module CORBA


  } ## end of include 'tao/StringSeq.pidl'

  ## include
  CORBA.implement('tao/ULongSeq.pidl', {}, CORBA::IDL::CLIENT_STUB) {

  module CORBA

    class ULongSeq < Array
      def ULongSeq._tc
        @@tc_ULongSeq ||= CORBA::TypeCode::Alias.new('IDL:omg.org/CORBA/ULongSeq:1.0', 'ULongSeq', self,
          CORBA::TypeCode::Sequence.new(CORBA._tc_ulong).freeze)
      end
    end # typedef ULongSeq
  end #of module CORBA


  } ## end of include 'tao/ULongSeq.pidl'

  ## include
  CORBA.implement('tao/UShortSeq.pidl', {}, CORBA::IDL::CLIENT_STUB) {

  module CORBA

    class UShortSeq < Array
      def UShortSeq._tc
        @@tc_UShortSeq ||= CORBA::TypeCode::Alias.new('IDL:omg.org/CORBA/UShortSeq:1.0', 'UShortSeq', self,
          CORBA::TypeCode::Sequence.new(CORBA._tc_ushort).freeze)
      end
    end # typedef UShortSeq
  end #of module CORBA


  } ## end of include 'tao/UShortSeq.pidl'

  ## include
  CORBA.implement('tao/WCharSeq.pidl', {}, CORBA::IDL::CLIENT_STUB) {

  module CORBA

    class WCharSeq < Array
      def WCharSeq._tc
        @@tc_WCharSeq ||= CORBA::TypeCode::Alias.new('IDL:omg.org/CORBA/WCharSeq:1.0', 'WCharSeq', self,
          CORBA::TypeCode::Sequence.new(CORBA._tc_wchar).freeze)
      end
    end # typedef WCharSeq
  end #of module CORBA


  } ## end of include 'tao/WCharSeq.pidl'

  ## include
  CORBA.implement('tao/WStringSeq.pidl', {}, CORBA::IDL::CLIENT_STUB) {

  module CORBA

    class WStringSeq < Array
      def WStringSeq._tc
        @@tc_WStringSeq ||= CORBA::TypeCode::Alias.new('IDL:omg.org/CORBA/WStringSeq:1.0', 'WStringSeq', self,
          CORBA::TypeCode::Sequence.new(CORBA._tc_wstring).freeze)
      end
    end # typedef WStringSeq
  end #of module CORBA


  } ## end of include 'tao/WStringSeq.pidl'

  ## include
  CORBA.implement('tao/LongLongSeq.pidl', {}, CORBA::IDL::CLIENT_STUB) {

  module CORBA

    class LongLongSeq < Array
      def LongLongSeq._tc
        @@tc_LongLongSeq ||= CORBA::TypeCode::Alias.new('IDL:omg.org/CORBA/LongLongSeq:1.0', 'LongLongSeq', self,
          CORBA::TypeCode::Sequence.new(CORBA._tc_longlong).freeze)
      end
    end # typedef LongLongSeq
  end #of module CORBA


  } ## end of include 'tao/LongLongSeq.pidl'

  ## include
  CORBA.implement('tao/ULongLongSeq.pidl', {}, CORBA::IDL::CLIENT_STUB) {

  module CORBA

    class ULongLongSeq < Array
      def ULongLongSeq._tc
        @@tc_ULongLongSeq ||= CORBA::TypeCode::Alias.new('IDL:omg.org/CORBA/ULongLongSeq:1.0', 'ULongLongSeq', self,
          CORBA::TypeCode::Sequence.new(CORBA._tc_ulonglong).freeze)
      end
    end # typedef ULongLongSeq
  end #of module CORBA


  } ## end of include 'tao/ULongLongSeq.pidl'

  ## include
  CORBA.implement('tao/Policy.pidl', {}, CORBA::IDL::CLIENT_STUB) {

  ## include
  CORBA.implement('tao/Current.pidl', {}, CORBA::IDL::CLIENT_STUB) {

  module CORBA


    module Current  ## interface


      Id = 'IDL:omg.org/CORBA/Current:1.0'.freeze
      Ids = [ Id ].freeze

      def Current._tc; @@tc_Current ||= CORBA::TypeCode::ObjectRef.new(Id, 'Current', self); end
      self._tc  # register typecode

      def Current._narrow(obj)
        return CORBA::Stub.create_stub(obj)._unchecked_narrow!(self)
      end

      def Current._duplicate(obj)
        obj
      end

      def _interface_repository_id
        self.class::Id
      end

    end #of interface Current
  end #of module CORBA


  } ## end of include 'tao/Current.pidl'

  ## include
  CORBA.implement('tao/Policy_Forward.pidl', {}, CORBA::IDL::CLIENT_STUB) {

  module CORBA

    class PolicyType < CORBA::_tc_ulong.get_type
      def PolicyType._tc; @@tc_PolicyType ||= CORBA::TypeCode::Alias.new('IDL:omg.org/CORBA/PolicyType:1.0', 'PolicyType', self, CORBA::_tc_ulong); end
    end # typedef PolicyType
    module Policy; end  ## interface forward
    class PolicyList < Array
      def PolicyList._tc
        @@tc_PolicyList ||= CORBA::TypeCode::Alias.new('IDL:omg.org/CORBA/PolicyList:1.0', 'PolicyList', self,
          CORBA::TypeCode::Sequence.new(CORBA::Policy._tc).freeze)
      end
    end # typedef PolicyList
    class PolicyTypeSeq < Array
      def PolicyTypeSeq._tc
        @@tc_PolicyTypeSeq ||= CORBA::TypeCode::Alias.new('IDL:omg.org/CORBA/PolicyTypeSeq:1.0', 'PolicyTypeSeq', self,
          CORBA::TypeCode::Sequence.new(CORBA::PolicyType._tc).freeze)
      end
    end # typedef PolicyTypeSeq
    module PolicyCurrent; end  ## interface forward
    class SetOverrideType < ::Fixnum
      def SetOverrideType._tc
        @@tc_SetOverrideType ||= CORBA::TypeCode::Enum.new('IDL:omg.org/CORBA/SetOverrideType:1.0'.freeze, 'SetOverrideType', [
            'SET_OVERRIDE',
            'ADD_OVERRIDE'])
      end
      self._tc  # register typecode
    end # enum SetOverrideType
    SET_OVERRIDE = 0
    ADD_OVERRIDE = 1
  end #of module CORBA


  } ## end of include 'tao/Policy_Forward.pidl'

  module CORBA

    class PolicyErrorCode < CORBA::_tc_short.get_type
      def PolicyErrorCode._tc; @@tc_PolicyErrorCode ||= CORBA::TypeCode::Alias.new('IDL:omg.org/CORBA/PolicyErrorCode:1.0', 'PolicyErrorCode', self, CORBA::_tc_short); end
    end # typedef PolicyErrorCode
    BAD_POLICY = 0
    UNSUPPORTED_POLICY = 1
    BAD_POLICY_TYPE = 2
    BAD_POLICY_VALUE = 3
    UNSUPPORTED_POLICY_VALUE = 4

    class PolicyError < CORBA::UserException

      def PolicyError._tc
        @@tc_PolicyError ||= CORBA::TypeCode::Except.new('IDL:omg.org/CORBA/PolicyError:1.0'.freeze, 'PolicyError', self,
           [['reason', CORBA::PolicyErrorCode._tc]])
      end
      self._tc  # register typecode
      attr_accessor :reason
      def initialize(*param_)
        @reason = param_
      end

    end #of exception PolicyError

    class InvalidPolicies < CORBA::UserException

      def InvalidPolicies._tc
        @@tc_InvalidPolicies ||= CORBA::TypeCode::Except.new('IDL:omg.org/CORBA/InvalidPolicies:1.0'.freeze, 'InvalidPolicies', self,
           [['indices', CORBA::UShortSeq._tc]])
      end
      self._tc  # register typecode
      attr_accessor :indices
      def initialize(*param_)
        @indices = param_
      end

    end #of exception InvalidPolicies

    module Policy  ## interface


      Id = 'IDL:omg.org/CORBA/Policy:1.0'.freeze
      Ids = [ Id ].freeze

      def Policy._tc; @@tc_Policy ||= CORBA::TypeCode::ObjectRef.new(Id, 'Policy', self); end
      self._tc  # register typecode

      def Policy._narrow(obj)
        return CORBA::Stub.create_stub(obj)._narrow!(self)
      end

      def Policy._duplicate(obj)
        return CORBA::Stub.create_stub(super(obj))._narrow!(self)
      end

      def _interface_repository_id
        self.class::Id
      end


      def policy_type()
        _ret = self._invoke('_get_policy_type', {
          :result_type => CORBA::PolicyType._tc})
        _ret
      end #of attribute get_policy_type

      def copy()
        _ret = self._invoke('copy', {
          :result_type => CORBA::Policy._tc})
        _ret
      end #of operation copy

      def destroy()
        _ret = self._invoke('destroy', {
          :result_type => CORBA._tc_void})
        _ret
      end #of operation destroy
    end #of interface Policy
  end #of module CORBA


  } ## end of include 'tao/Policy.pidl'

  ## include
  CORBA.implement('tao/Policy_Manager.pidl', {}, CORBA::IDL::CLIENT_STUB) {

  module CORBA


    module PolicyManager  ## interface


      Id = 'IDL:omg.org/CORBA/PolicyManager:1.0'.freeze
      Ids = [ Id ].freeze

      def PolicyManager._tc; @@tc_PolicyManager ||= CORBA::TypeCode::ObjectRef.new(Id, 'PolicyManager', self); end
      self._tc  # register typecode

      def PolicyManager._narrow(obj)
        return CORBA::Stub.create_stub(obj)._unchecked_narrow!(self)
      end

      def PolicyManager._duplicate(obj)
        obj
      end

      def _interface_repository_id
        self.class::Id
      end


      def get_policy_overrides(ts)
        raise ::CORBA::NO_IMPLEMENT.new(
                 'unimplemented operation on local interface',
                 1, ::CORBA::COMPLETED_NO)
      end #of operation get_policy_overrides

      def set_policy_overrides(policies, set_add)
        raise ::CORBA::NO_IMPLEMENT.new(
                 'unimplemented operation on local interface',
                 1, ::CORBA::COMPLETED_NO)
      end #of operation set_policy_overrides
    end #of interface PolicyManager
  end #of module CORBA


  } ## end of include 'tao/Policy_Manager.pidl'

  ## include
  CORBA.implement('tao/Policy_Current.pidl', {}, CORBA::IDL::CLIENT_STUB) {

  module CORBA


    module PolicyCurrent  ## interface

      include CORBA::PolicyManager
      include CORBA::Current

      Id = 'IDL:omg.org/CORBA/PolicyCurrent:1.0'.freeze
      Ids = [ Id,
              CORBA::PolicyManager::Id,
              CORBA::Current::Id ].freeze

      def PolicyCurrent._tc; @@tc_PolicyCurrent ||= CORBA::TypeCode::ObjectRef.new(Id, 'PolicyCurrent', self); end
      self._tc  # register typecode

      def PolicyCurrent._narrow(obj)
        return CORBA::Stub.create_stub(obj)._unchecked_narrow!(self)
      end

      def PolicyCurrent._duplicate(obj)
        obj
      end

      def _interface_repository_id
        self.class::Id
      end

    end #of interface PolicyCurrent
  end #of module CORBA


  } ## end of include 'tao/Policy_Current.pidl'

  ## include
  CORBA.implement('tao/Services.pidl', {}, CORBA::IDL::CLIENT_STUB) {

  module CORBA

    class ServiceType < CORBA::_tc_ushort.get_type
      def ServiceType._tc; @@tc_ServiceType ||= CORBA::TypeCode::Alias.new('IDL:omg.org/CORBA/ServiceType:1.0', 'ServiceType', self, CORBA::_tc_ushort); end
    end # typedef ServiceType
    class ServiceOption < CORBA::_tc_ulong.get_type
      def ServiceOption._tc; @@tc_ServiceOption ||= CORBA::TypeCode::Alias.new('IDL:omg.org/CORBA/ServiceOption:1.0', 'ServiceOption', self, CORBA::_tc_ulong); end
    end # typedef ServiceOption
    class ServiceDetailType < CORBA::_tc_ulong.get_type
      def ServiceDetailType._tc; @@tc_ServiceDetailType ||= CORBA::TypeCode::Alias.new('IDL:omg.org/CORBA/ServiceDetailType:1.0', 'ServiceDetailType', self, CORBA::_tc_ulong); end
    end # typedef ServiceDetailType
    class ServiceDetailData < CORBA::OctetSeq
      def ServiceDetailData._tc; @@tc_ServiceDetailData ||= CORBA::TypeCode::Alias.new('IDL:omg.org/CORBA/ServiceDetailData:1.0', 'ServiceDetailData', self,CORBA::OctetSeq._tc); end
    end # typedef ServiceDetailData
    class ServiceOptionSeq < Array
      def ServiceOptionSeq._tc
        @@tc_ServiceOptionSeq ||= CORBA::TypeCode::Alias.new('IDL:omg.org/CORBA/ServiceOptionSeq:1.0', 'ServiceOptionSeq', self,
          CORBA::TypeCode::Sequence.new(CORBA::ServiceOption._tc).freeze)
      end
    end # typedef ServiceOptionSeq
    Security = 1

    class ServiceDetail < CORBA::Portable::Struct

      def ServiceDetail._tc
        @@tc_ServiceDetail ||= CORBA::TypeCode::Struct.new('IDL:omg.org/CORBA/ServiceDetail:1.0'.freeze, 'ServiceDetail', self,
           [['service_detail_type', CORBA::ServiceDetailType._tc],
            ['service_detail', CORBA::ServiceDetailData._tc]])
      end
      self._tc  # register typecode
      attr_accessor :service_detail_type
      attr_accessor :service_detail
      def initialize(*param_)
        @service_detail_type,
        @service_detail = param_
      end

    end #of struct ServiceDetail
    class ServiceDetailSeq < Array
      def ServiceDetailSeq._tc
        @@tc_ServiceDetailSeq ||= CORBA::TypeCode::Alias.new('IDL:omg.org/CORBA/ServiceDetailSeq:1.0', 'ServiceDetailSeq', self,
          CORBA::TypeCode::Sequence.new(CORBA::ServiceDetail._tc).freeze)
      end
    end # typedef ServiceDetailSeq

    class ServiceInformation < CORBA::Portable::Struct

      def ServiceInformation._tc
        @@tc_ServiceInformation ||= CORBA::TypeCode::Struct.new('IDL:omg.org/CORBA/ServiceInformation:1.0'.freeze, 'ServiceInformation', self,
           [['service_options', CORBA::ServiceOptionSeq._tc],
            ['service_details', CORBA::ServiceDetailSeq._tc]])
      end
      self._tc  # register typecode
      attr_accessor :service_options
      attr_accessor :service_details
      def initialize(*param_)
        @service_options,
        @service_details = param_
      end

    end #of struct ServiceInformation
  end #of module CORBA


  } ## end of include 'tao/Services.pidl'

  ## include
  CORBA.implement('tao/ParameterMode.pidl', {}, CORBA::IDL::CLIENT_STUB) {

  module CORBA

    class ParameterMode < ::Fixnum
      def ParameterMode._tc
        @@tc_ParameterMode ||= CORBA::TypeCode::Enum.new('IDL:omg.org/CORBA/ParameterMode:1.0'.freeze, 'ParameterMode', [
            'PARAM_IN',
            'PARAM_OUT',
            'PARAM_INOUT'])
      end
      self._tc  # register typecode
    end # enum ParameterMode
    PARAM_IN = 0
    PARAM_OUT = 1
    PARAM_INOUT = 2
  end #of module CORBA


  } ## end of include 'tao/ParameterMode.pidl'

  ## include
  CORBA.implement('tao/orb_types.pidl', {}, CORBA::IDL::CLIENT_STUB) {

  module CORBA

    class ORBid < String
      def ORBid._tc; @@tc_ORBid ||= CORBA::TypeCode::Alias.new('IDL:omg.org/CORBA/ORBid:1.0', 'ORBid', self, CORBA::_tc_string); end
    end # typedef ORBid
    class Flags < CORBA::_tc_ulong.get_type
      def Flags._tc; @@tc_Flags ||= CORBA::TypeCode::Alias.new('IDL:omg.org/CORBA/Flags:1.0', 'Flags', self, CORBA::_tc_ulong); end
    end # typedef Flags
    class Identifier < String
      def Identifier._tc; @@tc_Identifier ||= CORBA::TypeCode::Alias.new('IDL:omg.org/CORBA/Identifier:1.0', 'Identifier', self, CORBA::_tc_string); end
    end # typedef Identifier
    class RepositoryId < String
      def RepositoryId._tc; @@tc_RepositoryId ||= CORBA::TypeCode::Alias.new('IDL:omg.org/CORBA/RepositoryId:1.0', 'RepositoryId', self, CORBA::_tc_string); end
    end # typedef RepositoryId
  end #of module CORBA


  } ## end of include 'tao/orb_types.pidl'

  ## include
  CORBA.implement('tao/Typecode_types.pidl', {}, CORBA::IDL::CLIENT_STUB) {

  module CORBA

    class TypeCode; end  ## interface forward
    class TCKind < ::Fixnum
      def TCKind._tc
        @@tc_TCKind ||= CORBA::TypeCode::Enum.new('IDL:omg.org/CORBA/TCKind:1.0'.freeze, 'TCKind', [
            'Tk_null',
            'Tk_void',
            'Tk_short',
            'Tk_long',
            'Tk_ushort',
            'Tk_ulong',
            'Tk_float',
            'Tk_double',
            'Tk_boolean',
            'Tk_char',
            'Tk_octet',
            'Tk_any',
            'Tk_TypeCode',
            'Tk_Principal',
            'Tk_objref',
            'Tk_struct',
            'Tk_union',
            'Tk_enum',
            'Tk_string',
            'Tk_sequence',
            'Tk_array',
            'Tk_alias',
            'Tk_except',
            'Tk_longlong',
            'Tk_ulonglong',
            'Tk_longdouble',
            'Tk_wchar',
            'Tk_wstring',
            'Tk_fixed',
            'Tk_value',
            'Tk_value_box',
            'Tk_native',
            'Tk_abstract_interface',
            'Tk_local_interface',
            'Tk_component',
            'Tk_home',
            'Tk_event'])
      end
      self._tc  # register typecode
    end # enum TCKind
    Tk_null = 0
    Tk_void = 1
    Tk_short = 2
    Tk_long = 3
    Tk_ushort = 4
    Tk_ulong = 5
    Tk_float = 6
    Tk_double = 7
    Tk_boolean = 8
    Tk_char = 9
    Tk_octet = 10
    Tk_any = 11
    Tk_TypeCode = 12
    Tk_Principal = 13
    Tk_objref = 14
    Tk_struct = 15
    Tk_union = 16
    Tk_enum = 17
    Tk_string = 18
    Tk_sequence = 19
    Tk_array = 20
    Tk_alias = 21
    Tk_except = 22
    Tk_longlong = 23
    Tk_ulonglong = 24
    Tk_longdouble = 25
    Tk_wchar = 26
    Tk_wstring = 27
    Tk_fixed = 28
    Tk_value = 29
    Tk_value_box = 30
    Tk_native = 31
    Tk_abstract_interface = 32
    Tk_local_interface = 33
    Tk_component = 34
    Tk_home = 35
    Tk_event = 36
  end #of module CORBA


  } ## end of include 'tao/Typecode_types.pidl'

  ## include
  CORBA.implement('tao/WrongTransaction.pidl', {}, CORBA::IDL::CLIENT_STUB) {

  module CORBA


    class WrongTransaction < CORBA::UserException

      def WrongTransaction._tc
        @@tc_WrongTransaction ||= CORBA::TypeCode::Except.new('IDL:omg.org/CORBA/WrongTransaction:1.0'.freeze, 'WrongTransaction', self)
      end
      self._tc  # register typecode
    end #of exception WrongTransaction
  end #of module CORBA


  } ## end of include 'tao/WrongTransaction.pidl'

  module CORBA


    class NamedValue < CORBA::Portable::Struct

      def NamedValue._tc
        @@tc_NamedValue ||= CORBA::TypeCode::Struct.new('IDL:omg.org/CORBA/NamedValue:1.0'.freeze, 'NamedValue', self,
           [['name', CORBA::Identifier._tc],
            ['argument', CORBA._tc_any],
            ['len', CORBA._tc_long],
            ['arg_modes', CORBA::Flags._tc]])
      end
      self._tc  # register typecode
      attr_accessor :name
      attr_accessor :argument
      attr_accessor :len
      attr_accessor :arg_modes
      def initialize(*param_)
        @name,
        @argument,
        @len,
        @arg_modes = param_
      end

    end #of struct NamedValue
    class Exception_type < ::Fixnum
      def Exception_type._tc
        @@tc_Exception_type ||= CORBA::TypeCode::Enum.new('IDL:omg.org/CORBA/exception_type:1.0'.freeze, 'Exception_type', [
            'NO_EXCEPTION',
            'USER_EXCEPTION',
            'SYSTEM_EXCEPTION'])
      end
      self._tc  # register typecode
    end # enum Exception_type
    NO_EXCEPTION = 0
    USER_EXCEPTION = 1
    SYSTEM_EXCEPTION = 2
    class ValueFactory; end  ## 'native' type
  end #of module CORBA

  } ## end of 'orb.idl'
end #of module R2CORBA

# -*- END -*-
