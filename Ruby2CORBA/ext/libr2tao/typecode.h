/*--------------------------------------------------------------------
# typecode.h - R2TAO CORBA TypeCode support
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
#ifndef __R2TAO_TYPECODE_H
#define __R2TAO_TYPECODE_H

#include "required.h"
#include "tao/AnyTypeCode/AnyTypeCode_methods.h"
#include "tao/AnyTypeCode/TypeCode.h"
#include "tao/AnyTypeCode/TypeCode_Constants.h"

extern void r2tao_Init_Typecode();

extern R2TAO_EXPORT VALUE r2tao_cTypecode;

extern R2TAO_EXPORT CORBA::TypeCode_ptr r2tao_Typecode_r2t(VALUE rtc, CORBA::ORB_ptr _orb);
extern R2TAO_EXPORT VALUE r2tao_Typecode_t2r(CORBA::TypeCode_ptr _tc, CORBA::ORB_ptr _orb);

extern R2TAO_EXPORT void r2tao_Typecode_Ruby2Any(CORBA::Any& _any, CORBA::TypeCode_ptr _tc, VALUE val, CORBA::ORB_ptr _orb);
extern R2TAO_EXPORT VALUE r2tao_Typecode_Any2Ruby(const CORBA::Any& _any, CORBA::TypeCode_ptr _tc, VALUE rtc, VALUE roottc, CORBA::ORB_ptr _orb);

extern R2TAO_EXPORT void r2tao_Ruby_to_Any(CORBA::Any& _any, VALUE val, CORBA::ORB_ptr _orb);
#endif

