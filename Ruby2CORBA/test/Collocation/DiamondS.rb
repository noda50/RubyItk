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
require 'DiamondC.rb'

module POA
  CORBA.implement('Diamond.idl', {}, CORBA::IDL::SERVANT_INTF) {

  module Diamond


    class Top < PortableServer::Servant ## servant

      module Intf
        Id = 'IDL:Diamond/Top:1.0'.freeze
        Ids = [ Id ]
        Operations = {}

        Operations.store(:shape, {
          :result_type => CORBA._tc_string})

        def shape()
          raise ::CORBA::NO_IMPLEMENT.new(
                   'unimplemented servant operation',
                   1, ::CORBA::COMPLETED_NO)
        end

      end #of Intf

      Id = Intf::Id

      include_interface(PortableServer::Servant::Intf)

      include Intf

      def _this; ::Diamond::Top._narrow(super); end
    end #of servant Top

    class Left < PortableServer::Servant ## servant

      module Intf
        Id = 'IDL:Diamond/Left:1.0'.freeze
        Ids = [ Id ]
        Operations = {}

        Operations.store(:color, {
          :result_type => CORBA._tc_string})

        def color()
          raise ::CORBA::NO_IMPLEMENT.new(
                   'unimplemented servant operation',
                   1, ::CORBA::COMPLETED_NO)
        end

      end #of Intf

      Id = Intf::Id

      include_interface(Diamond::Top::Intf)

      include Intf

      def _this; ::Diamond::Left._narrow(super); end
    end #of servant Left

    class Right < PortableServer::Servant ## servant

      module Intf
        Id = 'IDL:Diamond/Right:1.0'.freeze
        Ids = [ Id ]
        Operations = {}

        Operations.store(:width, {
          :result_type => CORBA._tc_long})

        def width()
          raise ::CORBA::NO_IMPLEMENT.new(
                   'unimplemented servant operation',
                   1, ::CORBA::COMPLETED_NO)
        end

      end #of Intf

      Id = Intf::Id

      include_interface(Diamond::Top::Intf)

      include Intf

      def _this; ::Diamond::Right._narrow(super); end
    end #of servant Right

    class Buttom < PortableServer::Servant ## servant

      module Intf
        Id = 'IDL:Diamond/Buttom:1.0'.freeze
        Ids = [ Id ]
        Operations = {}

        Operations.store(:name, {
          :result_type => CORBA._tc_string})

        def name()
          raise ::CORBA::NO_IMPLEMENT.new(
                   'unimplemented servant operation',
                   1, ::CORBA::COMPLETED_NO)
        end

        Operations.store(:area, {
          :arg_list => [
            ['unit', CORBA::ARG_IN, ::Diamond::Buttom::E_units._tc],
            ['result', CORBA::ARG_OUT, CORBA._tc_long]],
          :result_type => CORBA._tc_void})

        def area(unit)
          raise ::CORBA::NO_IMPLEMENT.new(
                   'unimplemented servant operation',
                   1, ::CORBA::COMPLETED_NO)
        end

      end #of Intf

      Id = Intf::Id

      include_interface(Diamond::Left::Intf)
      include_interface(Diamond::Right::Intf)

      include Intf

      def _this; ::Diamond::Buttom._narrow(super); end
    end #of servant Buttom
  end #of module Diamond

  } ## end of 'Diamond.idl'
end #of module POA
# -*- END -*-
