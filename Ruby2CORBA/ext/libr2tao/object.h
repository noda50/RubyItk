/*--------------------------------------------------------------------
# object.h - R2TAO CORBA Object support
#
# Author: Martin Corino
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the R2CORBA LICENSE which is
# included with this program.
#
# Copyright (c) Remedy IT Expertise BV
# Chamber of commerce Rotterdam nr.276339, The Netherlands
#------------------------------------------------------------------*/
#ifndef __R2TAO_OBJECT_H
#define __R2TAO_OBJECT_H

#include "required.h"
#include "tao/Object.h"

extern void r2tao_Init_Object();

extern R2TAO_EXPORT VALUE r2tao_cObject;

extern VALUE r2tao_t2r(VALUE klass, CORBA::Object_ptr obj);

extern R2TAO_EXPORT VALUE r2tao_Object_t2r(CORBA::Object_ptr obj);
extern R2TAO_EXPORT CORBA::Object_ptr r2tao_Object_r2t(VALUE obj);

#endif
