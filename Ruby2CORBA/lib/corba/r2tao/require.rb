#--------------------------------------------------------------------
# require.rb - R2TAO loader
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

begin
  require "libr2tao"
rescue LoadError
  $stderr.puts $!.to_s if $VERBOSE
  require "libr2taod"
end
[ 'Typecode',
  'Stub',
  'IDL',
  'ORB',
].each { |f| require "corba/r2tao/#{f}.rb" }

