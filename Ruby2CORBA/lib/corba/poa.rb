#--------------------------------------------------------------------
# poa.rb - R2CORBA POA loader
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
require 'corba/r2tao/POAC'
require 'corba/r2tao/POAManagerC'
require 'corba/r2tao/Servant'
require 'corba/r2tao/IORTableC'

begin
  require "librpoa"
rescue LoadError
  $stderr.puts $!.to_s if $VERBOSE
  require "librpoad"
end
