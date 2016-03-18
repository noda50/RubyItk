#--------------------------------------------------------------------
# policies.rb - R2CORBA Policy support loader
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

require 'corba.rb'
require 'corba/poa.rb'
require 'corba/r2tao/BiDirPolicyC'
require 'corba/r2tao/MessagingC'
require 'corba/r2tao/TAO_ExtC'

begin
  require "librpol"
rescue LoadError
  require "librpold"
end
 
