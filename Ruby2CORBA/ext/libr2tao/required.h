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
#ifndef __R2TAO_REQUIRED_H
#define __R2TAO_REQUIRED_H

#if defined (WIN32) || defined (_MSC_VER)
  // prevent inclusion of Ruby Win32 defs which clash with ACE
  // are only important for Ruby internals
  #define RUBY_WIN32_H
  // if we're compiling with MSVC 7.1 this is most probably for
  // the standard Ruby dist which is built with MSVC 6
  // fudge the version macro so Ruby doesn't complain
  #if (_MSC_VER >= 1310) && (_MSC_VER < 1400)
  #define OLD_MSC_VER 1310
  #undef _MSC_VER
  #define _MSC_VER 1200
  #endif
#endif

#define RUBY_EXTCONF_H "r2tao_ext.h"
#include <ruby.h>
// remove conflicting macro defined by Ruby
#undef TYPE

#undef RUBY_METHOD_FUNC
extern "C" {
  typedef VALUE (*TfnRuby)(ANYARGS);
  typedef VALUE (*TfnRbAlloc)(VALUE);
};
#define RUBY_METHOD_FUNC(func) ((TfnRuby)func)
#define RUBY_ALLOC_FUNC(func) ((TfnRbAlloc)func)

// includes for Ruby <= 1.8.4 miss this macro
#if !defined (NUM2ULL)
# define NUM2ULL(x) rb_num2ull (x)
#endif

#include "r2tao_export.h"
#include <tao/Version.h>

extern R2TAO_EXPORT VALUE r2tao_nsCORBA;

extern R2TAO_EXPORT void r2tao_check_type(VALUE x, VALUE t);

#endif
