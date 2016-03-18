# -*- Ruby -*-
#
# ****  Code generated by the R2CORBA IDL Compiler ****
# R2CORBA has been developed by:
#        Remedy IT
#        Nijkerk, GLD
#        The Netherlands
#        http://www.remedy.nl  http://www.theaceorb.nl
#
require 'corba'

CORBA.implement('CosNaming.idl', {}, CORBA::IDL::CLIENT_STUB) {

module CosNaming

  class Istring < String
    def Istring._tc; @@tc_Istring ||= CORBA::TypeCode::Alias.new('IDL:omg.org/CosNaming/Istring:1.0', 'Istring', self, CORBA::_tc_string); end
  end # typedef Istring

  class NameComponent < CORBA::Portable::Struct

    def NameComponent._tc
      @@tc_NameComponent ||= CORBA::TypeCode::Struct.new('IDL:omg.org/CosNaming/NameComponent:1.0'.freeze, 'NameComponent', self,
         [['r_id', CosNaming::Istring._tc],
          ['kind', CosNaming::Istring._tc]])
    end
    self._tc  # register typecode
    attr_accessor :r_id
    attr_accessor :kind
    def initialize(*param_)
      @r_id,
      @kind = param_
    end

  end #of struct NameComponent
  class Name < Array
    def Name._tc
      @@tc_Name ||= CORBA::TypeCode::Alias.new('IDL:omg.org/CosNaming/Name:1.0', 'Name', self,
        CORBA::TypeCode::Sequence.new(CosNaming::NameComponent._tc).freeze)
    end
  end # typedef Name
  class BindingType < ::Fixnum
    def BindingType._tc
      @@tc_BindingType ||= CORBA::TypeCode::Enum.new('IDL:omg.org/CosNaming/BindingType:1.0'.freeze, 'BindingType', [
          'Nobject',
          'Ncontext'])
    end
    self._tc  # register typecode
  end # enum BindingType
  Nobject = 0
  Ncontext = 1

  class Binding < CORBA::Portable::Struct

    def Binding._tc
      @@tc_Binding ||= CORBA::TypeCode::Struct.new('IDL:omg.org/CosNaming/Binding:1.0'.freeze, 'Binding', self,
         [['binding_name', CosNaming::Name._tc],
          ['binding_type', CosNaming::BindingType._tc]])
    end
    self._tc  # register typecode
    attr_accessor :binding_name
    attr_accessor :binding_type
    def initialize(*param_)
      @binding_name,
      @binding_type = param_
    end

  end #of struct Binding
  class BindingList < Array
    def BindingList._tc
      @@tc_BindingList ||= CORBA::TypeCode::Alias.new('IDL:omg.org/CosNaming/BindingList:1.0', 'BindingList', self,
        CORBA::TypeCode::Sequence.new(CosNaming::Binding._tc).freeze)
    end
  end # typedef BindingList
  module BindingIterator; end  ## interface forward

  module NamingContext  ## interface


    Id = 'IDL:omg.org/CosNaming/NamingContext:1.0'.freeze
    Ids = [ Id ].freeze

    def NamingContext._tc; @@tc_NamingContext ||= CORBA::TypeCode::ObjectRef.new(Id, 'NamingContext', self); end
    self._tc  # register typecode

    def NamingContext._narrow(obj)
      return CORBA::Stub.create_stub(obj)._narrow!(self)
    end

    def NamingContext._duplicate(obj)
      return CORBA::Stub.create_stub(super(obj))._narrow!(self)
    end

    def _interface_repository_id
      self.class::Id
    end

    class NotFoundReason < ::Fixnum
      def NotFoundReason._tc
        @@tc_NotFoundReason ||= CORBA::TypeCode::Enum.new('IDL:omg.org/CosNaming/NamingContext/NotFoundReason:1.0'.freeze, 'NotFoundReason', [
            'Missing_node',
            'Not_context',
            'Not_object'])
      end
      self._tc  # register typecode
    end # enum NotFoundReason
    Missing_node = 0
    Not_context = 1
    Not_object = 2

    class NotFound < CORBA::UserException

      def NotFound._tc
        @@tc_NotFound ||= CORBA::TypeCode::Except.new('IDL:omg.org/CosNaming/NamingContext/NotFound:1.0'.freeze, 'NotFound', self,
           [['why', CosNaming::NamingContext::NotFoundReason._tc],
            ['rest_of_name', CosNaming::Name._tc]])
      end
      self._tc  # register typecode
      attr_accessor :why
      attr_accessor :rest_of_name
      def initialize(*param_)
        @why,
        @rest_of_name = param_
      end

    end #of exception NotFound

    class CannotProceed < CORBA::UserException

      def CannotProceed._tc
        @@tc_CannotProceed ||= CORBA::TypeCode::Except.new('IDL:omg.org/CosNaming/NamingContext/CannotProceed:1.0'.freeze, 'CannotProceed', self,
           [['cxt', CosNaming::NamingContext._tc],
            ['rest_of_name', CosNaming::Name._tc]])
      end
      self._tc  # register typecode
      attr_accessor :cxt
      attr_accessor :rest_of_name
      def initialize(*param_)
        @cxt,
        @rest_of_name = param_
      end

    end #of exception CannotProceed

    class InvalidName < CORBA::UserException

      def InvalidName._tc
        @@tc_InvalidName ||= CORBA::TypeCode::Except.new('IDL:omg.org/CosNaming/NamingContext/InvalidName:1.0'.freeze, 'InvalidName', self)
      end
      self._tc  # register typecode
    end #of exception InvalidName

    class AlreadyBound < CORBA::UserException

      def AlreadyBound._tc
        @@tc_AlreadyBound ||= CORBA::TypeCode::Except.new('IDL:omg.org/CosNaming/NamingContext/AlreadyBound:1.0'.freeze, 'AlreadyBound', self)
      end
      self._tc  # register typecode
    end #of exception AlreadyBound

    class NotEmpty < CORBA::UserException

      def NotEmpty._tc
        @@tc_NotEmpty ||= CORBA::TypeCode::Except.new('IDL:omg.org/CosNaming/NamingContext/NotEmpty:1.0'.freeze, 'NotEmpty', self)
      end
      self._tc  # register typecode
    end #of exception NotEmpty

    def bind(n, obj)
      n = CosNaming::Name._tc.validate(n)
      obj = CORBA._tc_Object.validate(obj)
      _ret = self._invoke('bind', {
        :arg_list => [
          ['n', CORBA::ARG_IN, CosNaming::Name._tc, n],
          ['obj', CORBA::ARG_IN, CORBA._tc_Object, obj]],
        :result_type => CORBA._tc_void,
        :exc_list => [
          CosNaming::NamingContext::NotFound._tc,
          CosNaming::NamingContext::CannotProceed._tc,
          CosNaming::NamingContext::InvalidName._tc,
          CosNaming::NamingContext::AlreadyBound._tc]})
      _ret
    end #of operation bind

    def rebind(n, obj)
      n = CosNaming::Name._tc.validate(n)
      obj = CORBA._tc_Object.validate(obj)
      _ret = self._invoke('rebind', {
        :arg_list => [
          ['n', CORBA::ARG_IN, CosNaming::Name._tc, n],
          ['obj', CORBA::ARG_IN, CORBA._tc_Object, obj]],
        :result_type => CORBA._tc_void,
        :exc_list => [
          CosNaming::NamingContext::NotFound._tc,
          CosNaming::NamingContext::CannotProceed._tc,
          CosNaming::NamingContext::InvalidName._tc]})
      _ret
    end #of operation rebind

    def bind_context(n, nc)
      n = CosNaming::Name._tc.validate(n)
      nc = CosNaming::NamingContext._tc.validate(nc)
      _ret = self._invoke('bind_context', {
        :arg_list => [
          ['n', CORBA::ARG_IN, CosNaming::Name._tc, n],
          ['nc', CORBA::ARG_IN, CosNaming::NamingContext._tc, nc]],
        :result_type => CORBA._tc_void,
        :exc_list => [
          CosNaming::NamingContext::NotFound._tc,
          CosNaming::NamingContext::CannotProceed._tc,
          CosNaming::NamingContext::InvalidName._tc,
          CosNaming::NamingContext::AlreadyBound._tc]})
      _ret
    end #of operation bind_context

    def rebind_context(n, nc)
      n = CosNaming::Name._tc.validate(n)
      nc = CosNaming::NamingContext._tc.validate(nc)
      _ret = self._invoke('rebind_context', {
        :arg_list => [
          ['n', CORBA::ARG_IN, CosNaming::Name._tc, n],
          ['nc', CORBA::ARG_IN, CosNaming::NamingContext._tc, nc]],
        :result_type => CORBA._tc_void,
        :exc_list => [
          CosNaming::NamingContext::NotFound._tc,
          CosNaming::NamingContext::CannotProceed._tc,
          CosNaming::NamingContext::InvalidName._tc]})
      _ret
    end #of operation rebind_context

    def resolve(n)
      n = CosNaming::Name._tc.validate(n)
      _ret = self._invoke('resolve', {
        :arg_list => [
          ['n', CORBA::ARG_IN, CosNaming::Name._tc, n]],
        :result_type => CORBA._tc_Object,
        :exc_list => [
          CosNaming::NamingContext::NotFound._tc,
          CosNaming::NamingContext::CannotProceed._tc,
          CosNaming::NamingContext::InvalidName._tc]})
      _ret
    end #of operation resolve

    def unbind(n)
      n = CosNaming::Name._tc.validate(n)
      _ret = self._invoke('unbind', {
        :arg_list => [
          ['n', CORBA::ARG_IN, CosNaming::Name._tc, n]],
        :result_type => CORBA._tc_void,
        :exc_list => [
          CosNaming::NamingContext::NotFound._tc,
          CosNaming::NamingContext::CannotProceed._tc,
          CosNaming::NamingContext::InvalidName._tc]})
      _ret
    end #of operation unbind

    def new_context()
      _ret = self._invoke('new_context', {
        :result_type => CosNaming::NamingContext._tc})
      _ret
    end #of operation new_context

    def bind_new_context(n)
      n = CosNaming::Name._tc.validate(n)
      _ret = self._invoke('bind_new_context', {
        :arg_list => [
          ['n', CORBA::ARG_IN, CosNaming::Name._tc, n]],
        :result_type => CosNaming::NamingContext._tc,
        :exc_list => [
          CosNaming::NamingContext::NotFound._tc,
          CosNaming::NamingContext::AlreadyBound._tc,
          CosNaming::NamingContext::CannotProceed._tc,
          CosNaming::NamingContext::InvalidName._tc]})
      _ret
    end #of operation bind_new_context

    def destroy()
      _ret = self._invoke('destroy', {
        :result_type => CORBA._tc_void,
        :exc_list => [
          CosNaming::NamingContext::NotEmpty._tc]})
      _ret
    end #of operation destroy

    def list(how_many)
      how_many = CORBA._tc_ulong.validate(how_many)
      _ret = self._invoke('list', {
        :arg_list => [
          ['how_many', CORBA::ARG_IN, CORBA._tc_ulong, how_many],
          ['bl', CORBA::ARG_OUT, CosNaming::BindingList._tc],
          ['bi', CORBA::ARG_OUT, CosNaming::BindingIterator._tc]],
        :result_type => CORBA._tc_void})
      _ret
    end #of operation list
  end #of interface NamingContext

  module BindingIterator  ## interface


    Id = 'IDL:omg.org/CosNaming/BindingIterator:1.0'.freeze
    Ids = [ Id ].freeze

    def BindingIterator._tc; @@tc_BindingIterator ||= CORBA::TypeCode::ObjectRef.new(Id, 'BindingIterator', self); end
    self._tc  # register typecode

    def BindingIterator._narrow(obj)
      return CORBA::Stub.create_stub(obj)._narrow!(self)
    end

    def BindingIterator._duplicate(obj)
      return CORBA::Stub.create_stub(super(obj))._narrow!(self)
    end

    def _interface_repository_id
      self.class::Id
    end


    def next_one()
      _ret = self._invoke('next_one', {
        :arg_list => [
          ['b', CORBA::ARG_OUT, CosNaming::Binding._tc]],
        :result_type => CORBA._tc_boolean})
      _ret
    end #of operation next_one

    def next_n(how_many)
      how_many = CORBA._tc_ulong.validate(how_many)
      _ret = self._invoke('next_n', {
        :arg_list => [
          ['how_many', CORBA::ARG_IN, CORBA._tc_ulong, how_many],
          ['bl', CORBA::ARG_OUT, CosNaming::BindingList._tc]],
        :result_type => CORBA._tc_boolean})
      _ret
    end #of operation next_n

    def destroy()
      _ret = self._invoke('destroy', {
        :result_type => CORBA._tc_void})
      _ret
    end #of operation destroy
  end #of interface BindingIterator

  module NamingContextExt  ## interface

    include CosNaming::NamingContext

    Id = 'IDL:omg.org/CosNaming/NamingContextExt:1.0'.freeze
    Ids = [ Id,
            CosNaming::NamingContext::Id ].freeze

    def NamingContextExt._tc; @@tc_NamingContextExt ||= CORBA::TypeCode::ObjectRef.new(Id, 'NamingContextExt', self); end
    self._tc  # register typecode

    def NamingContextExt._narrow(obj)
      return CORBA::Stub.create_stub(obj)._narrow!(self)
    end

    def NamingContextExt._duplicate(obj)
      return CORBA::Stub.create_stub(super(obj))._narrow!(self)
    end

    def _interface_repository_id
      self.class::Id
    end

    class StringName < String
      def StringName._tc; @@tc_StringName ||= CORBA::TypeCode::Alias.new('IDL:omg.org/CosNaming/NamingContextExt/StringName:1.0', 'StringName', self, CORBA::_tc_string); end
    end # typedef StringName
    class Address < String
      def Address._tc; @@tc_Address ||= CORBA::TypeCode::Alias.new('IDL:omg.org/CosNaming/NamingContextExt/Address:1.0', 'Address', self, CORBA::_tc_string); end
    end # typedef Address
    class URLString < String
      def URLString._tc; @@tc_URLString ||= CORBA::TypeCode::Alias.new('IDL:omg.org/CosNaming/NamingContextExt/URLString:1.0', 'URLString', self, CORBA::_tc_string); end
    end # typedef URLString

    def to_string(n)
      n = CosNaming::Name._tc.validate(n)
      _ret = self._invoke('to_string', {
        :arg_list => [
          ['n', CORBA::ARG_IN, CosNaming::Name._tc, n]],
        :result_type => CosNaming::NamingContextExt::StringName._tc,
        :exc_list => [
          CosNaming::NamingContext::InvalidName._tc]})
      _ret
    end #of operation to_string

    def to_name(sn)
      sn = CosNaming::NamingContextExt::StringName._tc.validate(sn)
      _ret = self._invoke('to_name', {
        :arg_list => [
          ['sn', CORBA::ARG_IN, CosNaming::NamingContextExt::StringName._tc, sn]],
        :result_type => CosNaming::Name._tc,
        :exc_list => [
          CosNaming::NamingContext::InvalidName._tc]})
      _ret
    end #of operation to_name

    class InvalidAddress < CORBA::UserException

      def InvalidAddress._tc
        @@tc_InvalidAddress ||= CORBA::TypeCode::Except.new('IDL:omg.org/CosNaming/NamingContextExt/InvalidAddress:1.0'.freeze, 'InvalidAddress', self)
      end
      self._tc  # register typecode
    end #of exception InvalidAddress

    def to_url(addr, sn)
      addr = CosNaming::NamingContextExt::Address._tc.validate(addr)
      sn = CosNaming::NamingContextExt::StringName._tc.validate(sn)
      _ret = self._invoke('to_url', {
        :arg_list => [
          ['addr', CORBA::ARG_IN, CosNaming::NamingContextExt::Address._tc, addr],
          ['sn', CORBA::ARG_IN, CosNaming::NamingContextExt::StringName._tc, sn]],
        :result_type => CosNaming::NamingContextExt::URLString._tc,
        :exc_list => [
          CosNaming::NamingContextExt::InvalidAddress._tc,
          CosNaming::NamingContext::InvalidName._tc]})
      _ret
    end #of operation to_url

    def resolve_str(n)
      n = CosNaming::NamingContextExt::StringName._tc.validate(n)
      _ret = self._invoke('resolve_str', {
        :arg_list => [
          ['n', CORBA::ARG_IN, CosNaming::NamingContextExt::StringName._tc, n]],
        :result_type => CORBA._tc_Object,
        :exc_list => [
          CosNaming::NamingContext::NotFound._tc,
          CosNaming::NamingContext::CannotProceed._tc,
          CosNaming::NamingContext::InvalidName._tc]})
      _ret
    end #of operation resolve_str
  end #of interface NamingContextExt
end #of module CosNaming

} ## end of 'CosNaming.idl'
# -*- END -*-
