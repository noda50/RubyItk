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

CORBA.implement('Test.idl', {}, CORBA::IDL::CLIENT_STUB) {

module Test


  module Hello  ## interface


    Id = 'IDL:Test/Hello:1.0'.freeze
    Ids = [ Id ].freeze

    def Hello._tc; @@tc_Hello ||= CORBA::TypeCode::ObjectRef.new(Id, 'Hello', self); end
    self._tc  # register typecode

    def Hello._narrow(obj)
      return CORBA::Stub.create_stub(obj)._narrow!(self)
    end

    def Hello._duplicate(obj)
      return CORBA::Stub.create_stub(super(obj))._narrow!(self)
    end

    def _interface_repository_id
      self.class::Id
    end


    def get_string()
      _ret = self._invoke('get_string', {
        :result_type => CORBA._tc_string})
      _ret
    end #of operation get_string

    def shutdown()    # oneway
      self._invoke('shutdown', {})
    end #of operation shutdown
  end #of interface Hello
end #of module Test

} ## end of 'Test.idl'
# -*- END -*-
