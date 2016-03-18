#--------------------------------------------------------------------
# Stub.rb - R2TAO CORBA Stub support
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
    module Stub
      include R2CORBA::CORBA::Portable::Stub

      def init()
        init_corba_portable_stub()
      end

      def Stub.create_stub(obj)
        raise(TypeError) unless obj.is_a?(CORBA::Object)
        obj.extend(self) unless obj.is_a?(self)
        obj.init()
        return obj
      end

    end
  end
end
