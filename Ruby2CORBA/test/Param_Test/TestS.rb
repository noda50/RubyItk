# -*- Ruby -*-
#
# ****  Code generated by the R2CORBA IDL Compiler ****
# R2CORBA has been developed by:
#        Remedy IT
#        Nijkerk, GLD
#        The Netherlands
#        http://www.remedy.nl  http://www.theaceorb.nl
#
require 'corba/poa.rb'
require 'TestC.rb'

module POA
  CORBA.implement('Test.idl', {}, CORBA::IDL::SERVANT_INTF) {

  module Types

  end #of module Types

  module Test

    class Hello < PortableServer::Servant; end  ## servant forward

    class Hello < PortableServer::Servant ## servant

      module Intf
        Id = 'IDL:Remedy/Test/Hello:1.0'.freeze
        Ids = [ Id ]
        Operations = {}

        Operations.store(:_get_Max_LongLong, {
            :result_type => CORBA._tc_longlong,
            :op_sym => :max_LongLong })

        def max_LongLong()
          raise ::CORBA::NO_IMPLEMENT.new(
                   'unimplemented servant attribute get',
                   1, ::CORBA::COMPLETED_NO)
        end #of attribute get_Max_LongLong

        Operations.store(:_get_Min_LongLong, {
            :result_type => CORBA._tc_longlong,
            :op_sym => :min_LongLong })

        def min_LongLong()
          raise ::CORBA::NO_IMPLEMENT.new(
                   'unimplemented servant attribute get',
                   1, ::CORBA::COMPLETED_NO)
        end #of attribute get_Min_LongLong

        Operations.store(:_get_Max_ULongLong, {
            :result_type => CORBA._tc_ulonglong,
            :op_sym => :max_ULongLong })

        def max_ULongLong()
          raise ::CORBA::NO_IMPLEMENT.new(
                   'unimplemented servant attribute get',
                   1, ::CORBA::COMPLETED_NO)
        end #of attribute get_Max_ULongLong

        Operations.store(:_get_Min_ULongLong, {
            :result_type => CORBA._tc_ulonglong,
            :op_sym => :min_ULongLong })

        def min_ULongLong()
          raise ::CORBA::NO_IMPLEMENT.new(
                   'unimplemented servant attribute get',
                   1, ::CORBA::COMPLETED_NO)
        end #of attribute get_Min_ULongLong

        Operations.store(:_get_Max_Long, {
            :result_type => CORBA._tc_long,
            :op_sym => :max_Long })

        def max_Long()
          raise ::CORBA::NO_IMPLEMENT.new(
                   'unimplemented servant attribute get',
                   1, ::CORBA::COMPLETED_NO)
        end #of attribute get_Max_Long

        Operations.store(:_get_Min_Long, {
            :result_type => CORBA._tc_long,
            :op_sym => :min_Long })

        def min_Long()
          raise ::CORBA::NO_IMPLEMENT.new(
                   'unimplemented servant attribute get',
                   1, ::CORBA::COMPLETED_NO)
        end #of attribute get_Min_Long

        Operations.store(:_get_Max_ULong, {
            :result_type => CORBA._tc_ulong,
            :op_sym => :max_ULong })

        def max_ULong()
          raise ::CORBA::NO_IMPLEMENT.new(
                   'unimplemented servant attribute get',
                   1, ::CORBA::COMPLETED_NO)
        end #of attribute get_Max_ULong

        Operations.store(:_get_Min_ULong, {
            :result_type => CORBA._tc_ulong,
            :op_sym => :min_ULong })

        def min_ULong()
          raise ::CORBA::NO_IMPLEMENT.new(
                   'unimplemented servant attribute get',
                   1, ::CORBA::COMPLETED_NO)
        end #of attribute get_Min_ULong

        Operations.store(:_get_Max_Short, {
            :result_type => CORBA._tc_short,
            :op_sym => :max_Short })

        def max_Short()
          raise ::CORBA::NO_IMPLEMENT.new(
                   'unimplemented servant attribute get',
                   1, ::CORBA::COMPLETED_NO)
        end #of attribute get_Max_Short

        Operations.store(:_get_Min_Short, {
            :result_type => CORBA._tc_short,
            :op_sym => :min_Short })

        def min_Short()
          raise ::CORBA::NO_IMPLEMENT.new(
                   'unimplemented servant attribute get',
                   1, ::CORBA::COMPLETED_NO)
        end #of attribute get_Min_Short

        Operations.store(:_get_Max_UShort, {
            :result_type => CORBA._tc_ushort,
            :op_sym => :max_UShort })

        def max_UShort()
          raise ::CORBA::NO_IMPLEMENT.new(
                   'unimplemented servant attribute get',
                   1, ::CORBA::COMPLETED_NO)
        end #of attribute get_Max_UShort

        Operations.store(:_get_Min_UShort, {
            :result_type => CORBA._tc_ushort,
            :op_sym => :min_UShort })

        def min_UShort()
          raise ::CORBA::NO_IMPLEMENT.new(
                   'unimplemented servant attribute get',
                   1, ::CORBA::COMPLETED_NO)
        end #of attribute get_Min_UShort

        Operations.store(:_get_Max_Octet, {
            :result_type => CORBA._tc_octet,
            :op_sym => :max_Octet })

        def max_Octet()
          raise ::CORBA::NO_IMPLEMENT.new(
                   'unimplemented servant attribute get',
                   1, ::CORBA::COMPLETED_NO)
        end #of attribute get_Max_Octet

        Operations.store(:_get_Min_Octet, {
            :result_type => CORBA._tc_octet,
            :op_sym => :min_Octet })

        def min_Octet()
          raise ::CORBA::NO_IMPLEMENT.new(
                   'unimplemented servant attribute get',
                   1, ::CORBA::COMPLETED_NO)
        end #of attribute get_Min_Octet

        Operations.store(:get_string, {
          :result_type => ::Test::TString2._tc})

        def get_string()
          raise ::CORBA::NO_IMPLEMENT.new(
                   'unimplemented servant operation',
                   1, ::CORBA::COMPLETED_NO)
        end

        Operations.store(:_get_Message, {
            :result_type => ::Test::TString3._tc,
            :op_sym => :message })

        def message()
          raise ::CORBA::NO_IMPLEMENT.new(
                   'unimplemented servant attribute get',
                   1, ::CORBA::COMPLETED_NO)
        end #of attribute get_Message

        Operations.store(:_set_Message, {
            :arg_list => [
              ['val', CORBA::ARG_IN, ::Test::TString3._tc]],
            :result_type => CORBA._tc_void,
            :op_sym => :message= })

        def message=(val)
          raise ::CORBA::NO_IMPLEMENT.new(
                   'unimplemented servant attribute set',
                   1, ::CORBA::COMPLETED_NO)
        end #of attribute set_Message

        Operations.store(:_get_Numbers, {
            :result_type => ::Test::TShortSeq._tc,
            :op_sym => :numbers })

        def numbers()
          raise ::CORBA::NO_IMPLEMENT.new(
                   'unimplemented servant attribute get',
                   1, ::CORBA::COMPLETED_NO)
        end #of attribute get_Numbers

        Operations.store(:_set_Numbers, {
            :arg_list => [
              ['val', CORBA::ARG_IN, ::Test::TShortSeq._tc]],
            :result_type => CORBA._tc_void,
            :op_sym => :numbers= })

        def numbers=(val)
          raise ::CORBA::NO_IMPLEMENT.new(
                   'unimplemented servant attribute set',
                   1, ::CORBA::COMPLETED_NO)
        end #of attribute set_Numbers

        Operations.store(:_get_StructSeq, {
            :result_type => ::Test::S1Seq._tc,
            :op_sym => :structSeq })

        def structSeq()
          raise ::CORBA::NO_IMPLEMENT.new(
                   'unimplemented servant attribute get',
                   1, ::CORBA::COMPLETED_NO)
        end #of attribute get_StructSeq

        Operations.store(:_set_StructSeq, {
            :arg_list => [
              ['val', CORBA::ARG_IN, ::Test::S1Seq._tc]],
            :result_type => CORBA._tc_void,
            :op_sym => :structSeq= })

        def structSeq=(val)
          raise ::CORBA::NO_IMPLEMENT.new(
                   'unimplemented servant attribute set',
                   1, ::CORBA::COMPLETED_NO)
        end #of attribute set_StructSeq

        Operations.store(:_get_theCube, {
            :result_type => ::Test::TLongCube._tc,
            :op_sym => :theCube })

        def theCube()
          raise ::CORBA::NO_IMPLEMENT.new(
                   'unimplemented servant attribute get',
                   1, ::CORBA::COMPLETED_NO)
        end #of attribute get_theCube

        Operations.store(:_set_theCube, {
            :arg_list => [
              ['val', CORBA::ARG_IN, ::Test::TLongCube._tc]],
            :result_type => CORBA._tc_void,
            :op_sym => :theCube= })

        def theCube=(val)
          raise ::CORBA::NO_IMPLEMENT.new(
                   'unimplemented servant attribute set',
                   1, ::CORBA::COMPLETED_NO)
        end #of attribute set_theCube

        Operations.store(:_get_AnyValue, {
            :result_type => CORBA._tc_any,
            :op_sym => :anyValue })

        def anyValue()
          raise ::CORBA::NO_IMPLEMENT.new(
                   'unimplemented servant attribute get',
                   1, ::CORBA::COMPLETED_NO)
        end #of attribute get_AnyValue

        Operations.store(:_set_AnyValue, {
            :arg_list => [
              ['val', CORBA::ARG_IN, CORBA._tc_any]],
            :result_type => CORBA._tc_void,
            :op_sym => :anyValue= })

        def anyValue=(val)
          raise ::CORBA::NO_IMPLEMENT.new(
                   'unimplemented servant attribute set',
                   1, ::CORBA::COMPLETED_NO)
        end #of attribute set_AnyValue

        Operations.store(:_get_selfref, {
            :result_type => ::Test::Hello._tc,
            :op_sym => :selfref })

        def selfref()
          raise ::CORBA::NO_IMPLEMENT.new(
                   'unimplemented servant attribute get',
                   1, ::CORBA::COMPLETED_NO)
        end #of attribute get_selfref

        Operations.store(:_get_S3Value, {
            :result_type => CORBA._tc_any,
            :op_sym => :s3Value })

        def s3Value()
          raise ::CORBA::NO_IMPLEMENT.new(
                   'unimplemented servant attribute get',
                   1, ::CORBA::COMPLETED_NO)
        end #of attribute get_S3Value

        Operations.store(:_set_S3Value, {
            :arg_list => [
              ['val', CORBA::ARG_IN, CORBA._tc_any]],
            :result_type => CORBA._tc_void,
            :op_sym => :s3Value= })

        def s3Value=(val)
          raise ::CORBA::NO_IMPLEMENT.new(
                   'unimplemented servant attribute set',
                   1, ::CORBA::COMPLETED_NO)
        end #of attribute set_S3Value

        Operations.store(:_get_UnionValue, {
            :result_type => ::Test::U1._tc,
            :op_sym => :unionValue })

        def unionValue()
          raise ::CORBA::NO_IMPLEMENT.new(
                   'unimplemented servant attribute get',
                   1, ::CORBA::COMPLETED_NO)
        end #of attribute get_UnionValue

        Operations.store(:_set_UnionValue, {
            :arg_list => [
              ['val', CORBA::ARG_IN, ::Test::U1._tc]],
            :result_type => CORBA._tc_void,
            :op_sym => :unionValue= })

        def unionValue=(val)
          raise ::CORBA::NO_IMPLEMENT.new(
                   'unimplemented servant attribute set',
                   1, ::CORBA::COMPLETED_NO)
        end #of attribute set_UnionValue

        Operations.store(:run_test, {
          :arg_list => [
            ['instr', CORBA::ARG_IN, ::Test::TString._tc],
            ['inoutstr', CORBA::ARG_INOUT, CORBA._tc_string],
            ['outstr', CORBA::ARG_OUT, CORBA._tc_string]],
          :result_type => CORBA._tc_long})

        def run_test(instr, inoutstr)
          raise ::CORBA::NO_IMPLEMENT.new(
                   'unimplemented servant operation',
                   1, ::CORBA::COMPLETED_NO)
        end

        Operations.store(:shutdown, {})

        def shutdown()    # oneway
          raise ::CORBA::NO_IMPLEMENT.new(
                   'unimplemented servant operation',
                   1, ::CORBA::COMPLETED_NO)
        end

      end #of Intf

      Id = Intf::Id

      include_interface(PortableServer::Servant::Intf)

      include Intf

      def _this; ::Test::Hello._narrow(super); end
    end #of servant Hello
  end #of module Test

  } ## end of 'Test.idl'
end #of module POA
# -*- END -*-