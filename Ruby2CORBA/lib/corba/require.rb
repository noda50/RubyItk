#--------------------------------------------------------------------
# require.rb - R2CORBA loader
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
[
  'base/require',
  'r2tao/require',
].each { |f| require "corba/#{f}.rb" }
