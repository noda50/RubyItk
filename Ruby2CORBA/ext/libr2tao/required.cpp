/*--------------------------------------------------------------------
# required.h - R2TAO CORBA basic support
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

#include "required.h"

R2TAO_EXPORT VALUE r2tao_nsCORBA = 0;

extern void r2tao_Init_Exception();
extern void r2tao_Init_Object();
extern void r2tao_Init_ORB();
extern void r2tao_Init_Typecode();

#if defined(WIN32) && defined(_DEBUG)
extern "C" R2TAO_EXPORT void Init_libr2taod()
#else
extern "C" R2TAO_EXPORT void Init_libr2tao()
#endif
{
  rb_eval_string("puts 'Init_libr2tao start' if $VERBOSE");

  if (r2tao_nsCORBA) return;

  rb_eval_string("puts 'Init_libr2tao 2' if $VERBOSE");

  VALUE klass = rb_define_module_under (rb_eval_string ("::R2CORBA"), "TAO");
  rb_define_const (klass, "MAJOR_VERSION", INT2NUM (TAO_MAJOR_VERSION));
  rb_define_const (klass, "MINOR_VERSION", INT2NUM (TAO_MINOR_VERSION));
  rb_define_const (klass, "BETA_VERSION", INT2NUM (TAO_BETA_VERSION));
  rb_define_const (klass, "VERSION", rb_str_new2 (TAO_VERSION));

  r2tao_nsCORBA = rb_eval_string("::R2CORBA::CORBA");

  rb_eval_string("puts 'Init_libr2tao r2tao_Init_Exception' if $VERBOSE");

  r2tao_Init_Exception();

  rb_eval_string("puts 'Init_libr2tao r2tao_Init_Object' if $VERBOSE");

  r2tao_Init_Object();

  rb_eval_string("puts 'Init_libr2tao r2tao_Init_ORB' if $VERBOSE");

  r2tao_Init_ORB();

  rb_eval_string("puts 'Init_libr2tao r2tao_Init_Typecode' if $VERBOSE");

  r2tao_Init_Typecode();
}

R2TAO_EXPORT void r2tao_check_type(VALUE x, VALUE t)
{
  if (rb_obj_is_kind_of(x, t) != Qtrue)
  {
    rb_raise(rb_eTypeError, "wrong argument type %s (expected %s)",
	     rb_class2name(CLASS_OF(x)), rb_class2name(t));
  }
}
