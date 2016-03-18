/*--------------------------------------------------------------------
# typecode.cpp - R2TAO CORBA TypeCode support
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
#include "typecode.h"
#include "exception.h"
#include "object.h"
#include "tao/IFR_Client/IFR_BaseC.h"
#include "tao/AnyTypeCode/True_RefCount_Policy.h"
#include "tao/AnyTypeCode/Sequence_TypeCode.h"
#include "tao/AnyTypeCode/Any.h"
#include "tao/AnyTypeCode/BooleanSeqA.h"
#include "tao/AnyTypeCode/CharSeqA.h"
#include "tao/AnyTypeCode/DoubleSeqA.h"
#include "tao/AnyTypeCode/FloatSeqA.h"
#include "tao/AnyTypeCode/LongDoubleSeqA.h"
#include "tao/AnyTypeCode/LongSeqA.h"
#include "tao/AnyTypeCode/OctetSeqA.h"
#include "tao/AnyTypeCode/ShortSeqA.h"
#include "tao/AnyTypeCode/StringSeqA.h"
#include "tao/AnyTypeCode/ULongSeqA.h"
#include "tao/AnyTypeCode/UShortSeqA.h"
#include "tao/AnyTypeCode/WCharSeqA.h"
#include "tao/AnyTypeCode/WStringSeqA.h"
#include "tao/AnyTypeCode/LongLongSeqA.h"
#include "tao/AnyTypeCode/ULongLongSeqA.h"
#include "tao/AnyTypeCode/Any_Dual_Impl_T.h"
#include "tao/BooleanSeqC.h"
#include "tao/CharSeqC.h"
#include "tao/DoubleSeqC.h"
#include "tao/FloatSeqC.h"
#include "tao/LongDoubleSeqC.h"
#include "tao/LongSeqC.h"
#include "tao/OctetSeqC.h"
#include "tao/ShortSeqC.h"
#include "tao/StringSeqC.h"
#include "tao/ULongSeqC.h"
#include "tao/UShortSeqC.h"
#include "tao/WCharSeqC.h"
#include "tao/WStringSeqC.h"
#include "tao/LongLongSeqC.h"
#include "tao/ULongLongSeqC.h"
#include "tao/DynamicAny/DynamicAny.h"
#include "tao/TypeCodeFactory/TypeCodeFactory_Loader.h"

#define CHECK_RTYPE(v,t)\
  if (rb_type ((v)) != (t)) \
  { throw CORBA::BAD_PARAM(0, CORBA::COMPLETED_NO); }

VALUE R2TAO_EXPORT r2tao_cTypecode = 0;

static VALUE r2tao_cLongDouble;
//static VALUE r2tao_cTypecode_String;
static VALUE r2tao_cAny;

static VALUE rb_cBigDecimal;

static VALUE ld_alloc(VALUE klass);
static void ld_free(void* ptr);

static VALUE r2tao_LongDouble_initialize(int _argc, VALUE *_argv0, VALUE klass);
static VALUE r2tao_LongDouble_to_s(int _argc, VALUE *_argv, VALUE self);
static VALUE r2tao_LongDouble_to_f(VALUE self);
static VALUE r2tao_LongDouble_to_i(VALUE self);
static VALUE r2tao_LongDouble_size(VALUE self);

static VALUE r2tao_sym_default;

static VALUE tc_alloc(VALUE klass);
static void tc_free(void* ptr);

static VALUE rCORBA_Typecode_init(VALUE self, VALUE kind);

static void r2tao_Typecode_Ruby2Struct (CORBA::Any& _any, CORBA::TypeCode_ptr _tc, VALUE rarr, CORBA::ORB_ptr _orb);
static void r2tao_Typecode_Ruby2Union (CORBA::Any& _any, CORBA::TypeCode_ptr _tc, VALUE rs, CORBA::ORB_ptr _orb);
static void r2tao_Typecode_Ruby2Sequence(CORBA::Any& _any, CORBA::TypeCode_ptr _tc, VALUE rarr, CORBA::ORB_ptr _orb);

static VALUE r2tao_Typecode_Struct2Ruby (const CORBA::Any& _any, CORBA::TypeCode_ptr _tc, VALUE rtc, VALUE roottc, CORBA::ORB_ptr _orb);
static VALUE r2tao_Typecode_Union2Ruby (const CORBA::Any& _any, CORBA::TypeCode_ptr _tc, VALUE rtc, VALUE roottc, CORBA::ORB_ptr _orb);
static VALUE r2tao_Typecode_Sequence2Ruby(const CORBA::Any& _any, CORBA::TypeCode_ptr _tc, VALUE rtc, VALUE roottc, CORBA::ORB_ptr _orb);

static ID get_type_ID;
static ID typecode_for_any_ID;
static ID value_for_any_ID;

void r2tao_Init_Typecode()
{
  VALUE k;
  VALUE kinc;

  if (r2tao_cTypecode) return;

  //rb_eval_string("puts 'r2tao_Init_Typecode start' if $VERBOSE");

  kinc = rb_eval_string("::R2CORBA::CORBA::Portable::TypeCode");
  k = r2tao_cTypecode =
    rb_define_class_under (r2tao_nsCORBA, "TypeCode", rb_cObject);
  rb_define_alloc_func (r2tao_cTypecode, RUBY_ALLOC_FUNC (tc_alloc));
  rb_include_module (r2tao_cTypecode, kinc);

  r2tao_sym_default = rb_eval_string(":default");

  //rb_eval_string("puts 'r2tao_Init_Typecode 2' if $VERBOSE");

  // define Typecode methods
  rb_define_private_method(k, "_init", RUBY_METHOD_FUNC(rCORBA_Typecode_init), 1);

  // define Typecode-kind constants
  rb_define_const (kinc, "TK_NULL", INT2NUM (CORBA::tk_null));
  rb_define_const (kinc, "TK_VOID", INT2NUM (CORBA::tk_void));
  rb_define_const (kinc, "TK_SHORT", INT2NUM (CORBA::tk_short));
  rb_define_const (kinc, "TK_LONG", INT2NUM (CORBA::tk_long));
  rb_define_const (kinc, "TK_USHORT", INT2NUM (CORBA::tk_ushort));
  rb_define_const (kinc, "TK_ULONG", INT2NUM (CORBA::tk_ulong));
  rb_define_const (kinc, "TK_FLOAT", INT2NUM (CORBA::tk_float));
  rb_define_const (kinc, "TK_DOUBLE", INT2NUM (CORBA::tk_double));
  rb_define_const (kinc, "TK_BOOLEAN", INT2NUM (CORBA::tk_boolean));
  rb_define_const (kinc, "TK_CHAR", INT2NUM (CORBA::tk_char));
  rb_define_const (kinc, "TK_OCTET", INT2NUM (CORBA::tk_octet));
  rb_define_const (kinc, "TK_ANY", INT2NUM (CORBA::tk_any));
  rb_define_const (kinc, "TK_TYPECODE", INT2NUM (CORBA::tk_TypeCode));
  rb_define_const (kinc, "TK_PRINCIPAL", INT2NUM (CORBA::tk_Principal));
  rb_define_const (kinc, "TK_OBJREF", INT2NUM (CORBA::tk_objref));
  rb_define_const (kinc, "TK_STRUCT", INT2NUM (CORBA::tk_struct));
  rb_define_const (kinc, "TK_UNION", INT2NUM (CORBA::tk_union));
  rb_define_const (kinc, "TK_ENUM", INT2NUM (CORBA::tk_enum));
  rb_define_const (kinc, "TK_STRING", INT2NUM (CORBA::tk_string));
  rb_define_const (kinc, "TK_SEQUENCE", INT2NUM (CORBA::tk_sequence));
  rb_define_const (kinc, "TK_ARRAY", INT2NUM (CORBA::tk_array));
  rb_define_const (kinc, "TK_ALIAS", INT2NUM (CORBA::tk_alias));
  rb_define_const (kinc, "TK_EXCEPT", INT2NUM (CORBA::tk_except));
  rb_define_const (kinc, "TK_LONGLONG", INT2NUM (CORBA::tk_longlong));
  rb_define_const (kinc, "TK_ULONGLONG", INT2NUM (CORBA::tk_ulonglong));
  rb_define_const (kinc, "TK_LONGDOUBLE", INT2NUM (CORBA::tk_longdouble));
  rb_define_const (kinc, "TK_WCHAR", INT2NUM (CORBA::tk_wchar));
  rb_define_const (kinc, "TK_WSTRING", INT2NUM (CORBA::tk_wstring));
  rb_define_const (kinc, "TK_FIXED", INT2NUM (CORBA::tk_fixed));
  rb_define_const (kinc, "TK_VALUE", INT2NUM (CORBA::tk_value));
  rb_define_const (kinc, "TK_VALUE_BOX", INT2NUM (CORBA::tk_value_box));
  rb_define_const (kinc, "TK_NATIVE", INT2NUM (CORBA::tk_native));
  rb_define_const (kinc, "TK_ABSTRACT_INTERFACE", INT2NUM (CORBA::tk_abstract_interface));
  rb_define_const (kinc, "TK_LOCAL_INTERFACE", INT2NUM (CORBA::tk_local_interface));
  rb_define_const (kinc, "TK_COMPONENT", INT2NUM (CORBA::tk_component));
  rb_define_const (kinc, "TK_HOME", INT2NUM (CORBA::tk_home));
  rb_define_const (kinc, "TK_EVENT", INT2NUM (CORBA::tk_event));

  k = r2tao_cLongDouble =
    rb_define_class_under (r2tao_nsCORBA, "LongDouble", rb_cObject);
  rb_define_alloc_func (r2tao_cLongDouble, RUBY_ALLOC_FUNC (ld_alloc));
  rb_define_method(k, "initialize", RUBY_METHOD_FUNC(r2tao_LongDouble_initialize), -1);
  rb_define_method(k, "to_s", RUBY_METHOD_FUNC(r2tao_LongDouble_to_s), -1);
  rb_define_method(k, "to_f", RUBY_METHOD_FUNC(r2tao_LongDouble_to_f), 0);
  rb_define_method(k, "to_i", RUBY_METHOD_FUNC(r2tao_LongDouble_to_i), 0);
  rb_define_singleton_method(k, "size", RUBY_METHOD_FUNC(r2tao_LongDouble_size), 0);

  rb_require ("bigdecimal");
  rb_cBigDecimal = rb_eval_string ("::BigDecimal");

  r2tao_cAny = rb_eval_string ("R2CORBA::CORBA::Any");

  get_type_ID = rb_intern ("get_type");
  typecode_for_any_ID = rb_intern ("typecode_for_any");
  value_for_any_ID = rb_intern ("value_for_any");

  //rb_eval_string("puts 'r2tao_Init_Typecode end' if $VERBOSE");
}

static VALUE ld_alloc(VALUE klass)
{
  VALUE obj;

  ACE_CDR::LongDouble* ld = new ACE_CDR::LongDouble;
  ACE_CDR_LONG_DOUBLE_ASSIGNMENT ((*ld), 0.0);
  obj = Data_Wrap_Struct(klass, 0, ld_free, ld);
  return obj;
}

static void ld_free(void* ptr)
{
  if (ptr)
    delete static_cast<ACE_CDR::LongDouble*> (ptr);
}

#if defined (NONNATIVE_LONGDOUBLE)
#define NATIVE_LONGDOUBLE ACE_CDR::LongDouble::NativeImpl
#else
#define NATIVE_LONGDOUBLE long double
#endif

#define RLD2CLD(_x) \
  ((NATIVE_LONGDOUBLE)*static_cast<ACE_CDR::LongDouble*> (DATA_PTR (_x)))

#define SETCLD2RLD(_x, _d) \
  ACE_CDR_LONG_DOUBLE_ASSIGNMENT ((*static_cast<ACE_CDR::LongDouble*> (DATA_PTR (_x))), _d)

static VALUE r2tao_cld2rld(const NATIVE_LONGDOUBLE& _d)
{
  VALUE _rd = Data_Wrap_Struct(r2tao_cLongDouble, 0, ld_free, new ACE_CDR::LongDouble);
  SETCLD2RLD (_rd, _d);
  return _rd;
}

#define CLD2RLD(_d) \
  r2tao_cld2rld(_d)


VALUE r2tao_LongDouble_initialize(int _argc, VALUE *_argv, VALUE self)
{
  VALUE v0, v1 = Qnil;
  rb_scan_args(_argc, _argv, "11", &v0, &v1);

  if (rb_obj_is_kind_of(v0, rb_cFloat) == Qtrue)
  {
    SETCLD2RLD(self, NUM2DBL(v0));
    return self;
  }
  else if (rb_obj_is_kind_of(v0, rb_cBigDecimal) == Qtrue)
  {
    if (v1 != Qnil)
    {
      v0 = rb_funcall (v0, rb_intern ("round"), 1, v1);
    }
    v0 = rb_funcall (v0, rb_intern ("to_s"), 0);
  }

  if (rb_obj_is_kind_of(v0, rb_cString) == Qtrue)
  {
    char* endp = 0;
#if defined (NONNATIVE_LONGDOUBLE) && !defined (ACE_IMPLEMENT_WITH_NATIVE_LONGDOUBLE)
    NATIVE_LONGDOUBLE _ld = ::strtod (RSTRING (v0)->ptr, &endp);
#else
    NATIVE_LONGDOUBLE _ld = ::strtold (RSTRING (v0)->ptr, &endp);
#endif

    if (errno == ERANGE)
      rb_raise (rb_eRangeError, "floating point '%s' out-of-range", RSTRING (v0)->ptr);

    if (RSTRING (v0)->ptr == endp)
      rb_raise (rb_eArgError, "floating point string '%s' invalid", RSTRING (v0)->ptr);

    SETCLD2RLD(self, _ld);
    return self;
  }

  rb_raise (rb_eTypeError, "wrong argument type %s (expected Float, String or BigDecimal)",
            rb_class2name(CLASS_OF(v0)));

  return Qnil;
}

VALUE r2tao_LongDouble_to_s(int _argc, VALUE *_argv, VALUE self)
{
  VALUE prec = Qnil;
  rb_scan_args(_argc, _argv, "01", &prec);

  unsigned long lprec = (prec == Qnil ? 0 : NUM2ULONG (prec));
  
  R2TAO_TRY
  {
    unsigned long len = (lprec < 512) ? 1024 : 2*lprec;
    CORBA::String_var buf = CORBA::string_alloc (len);
#if defined (NONNATIVE_LONGDOUBLE) && !defined (ACE_IMPLEMENT_WITH_NATIVE_LONGDOUBLE)
    if (prec == Qnil)
      ACE_OS::snprintf ((char*)buf, len-1, "%f", RLD2CLD(self));
    else
      ACE_OS::snprintf ((char*)buf, len-1, "%.*f", lprec, RLD2CLD(self));
#else
    if (prec == Qnil)
      ACE_OS::snprintf ((char*)buf, len-1, "%Lf", RLD2CLD(self));
    else
      ACE_OS::snprintf ((char*)buf, len-1, "%.*Lf", lprec, RLD2CLD(self));
#endif
    return rb_str_new2 ((char*)buf);
  }
  R2TAO_CATCH;

  return Qnil;
}

VALUE r2tao_LongDouble_to_f(VALUE self)
{
  return rb_float_new (RLD2CLD(self));
}

VALUE r2tao_LongDouble_to_i(VALUE self)
{
  unsigned long long l =
    static_cast<unsigned long long> (RLD2CLD(self));
  return ULL2NUM (l);
}

VALUE r2tao_LongDouble_size(VALUE /*self*/)
{
  return INT2FIX (sizeof (NATIVE_LONGDOUBLE) * CHAR_BIT);
}

VALUE tc_alloc(VALUE klass)
{
  VALUE obj;
  // we start off without the C++ representation
  obj = Data_Wrap_Struct(klass, 0, tc_free, 0);
  return obj;
}

void tc_free(void* ptr)
{
  if (ptr)
    CORBA::release ((CORBA::TypeCode_ptr)ptr);
}

VALUE rCORBA_Typecode_init(VALUE self, VALUE kind)
{
  CORBA::TypeCode_ptr tc = CORBA::TypeCode::_nil ();
  switch ((CORBA::TCKind)NUM2INT (kind))
  {
    case CORBA::tk_null:
      tc = CORBA::_tc_null;
      break;
    case CORBA::tk_void:
      tc = CORBA::_tc_void;
      break;
    case CORBA::tk_short:
      tc = CORBA::_tc_short;
      break;
    case CORBA::tk_long:
      tc = CORBA::_tc_long;
      break;
    case CORBA::tk_ushort:
      tc = CORBA::_tc_ushort;
      break;
    case CORBA::tk_ulong:
      tc = CORBA::_tc_ulong;
      break;
    case CORBA::tk_longlong:
      tc = CORBA::_tc_longlong;
      break;
    case CORBA::tk_ulonglong:
      tc = CORBA::_tc_ulonglong;
      break;
    case CORBA::tk_float:
      tc = CORBA::_tc_float;
      break;
    case CORBA::tk_double:
      tc = CORBA::_tc_double;
      break;
    case CORBA::tk_longdouble:
      tc = CORBA::_tc_longdouble;
      break;
    case CORBA::tk_boolean:
      tc = CORBA::_tc_boolean;
      break;
    case CORBA::tk_char:
      tc = CORBA::_tc_char;
      break;
    case CORBA::tk_octet:
      tc = CORBA::_tc_octet;
      break;
    case CORBA::tk_wchar:
      tc = CORBA::_tc_wchar;
      break;
    case CORBA::tk_any:
      tc = CORBA::_tc_any;
      break;
    case CORBA::tk_TypeCode:
      tc = CORBA::_tc_TypeCode;
      break;
    case CORBA::tk_Principal:
      tc = CORBA::_tc_Principal;
      break;
    default:
      return Qnil;
  }

  DATA_PTR(self) = CORBA::TypeCode::_duplicate (tc);
  return Qnil;
}

/*===================================================================
 *  Typecodeconversion Ruby --> CORBA
 *
 */

R2TAO_EXPORT CORBA::TypeCode_ptr r2tao_Typecode_r2t(VALUE rtc, CORBA::ORB_ptr _orb)
{
  r2tao_check_type(rtc, r2tao_cTypecode);

  if (DATA_PTR (rtc))
  {
    CORBA::TypeCode_ptr tc = static_cast<CORBA::TypeCode_ptr> (DATA_PTR (rtc));
    return CORBA::TypeCode::_duplicate (tc);
  }

  CORBA::TypeCode_var _tc = CORBA::TypeCode::_nil ();

  VALUE rkind = rb_iv_get (rtc, "@kind");
  switch ((CORBA::TCKind)NUM2INT (rkind))
  {
    case CORBA::tk_objref:
    {
      VALUE rid = rb_iv_get (rtc, "@id");
      VALUE rname = rb_iv_get (rtc, "@name");
      _tc = _orb->create_interface_tc (RSTRING(rid)->ptr, RSTRING(rname)->ptr);
    }
    break;

    case CORBA::tk_home:
    {
      VALUE rid = rb_iv_get (rtc, "@id");
      VALUE rname = rb_iv_get (rtc, "@name");
      _tc = _orb->create_home_tc (RSTRING(rid)->ptr, RSTRING(rname)->ptr);
    }
    break;

    case CORBA::tk_component:
    {
      VALUE rid = rb_iv_get (rtc, "@id");
      VALUE rname = rb_iv_get (rtc, "@name");
      _tc = _orb->create_component_tc (RSTRING(rid)->ptr, RSTRING(rname)->ptr);
    }
    break;

    case CORBA::tk_alias:
    {
      VALUE rid = rb_iv_get (rtc, "@id");
      VALUE rname = rb_iv_get (rtc, "@name");
      VALUE raliased_tc = rb_iv_get (rtc, "@aliased_tc");
      CORBA::TypeCode_var _aliased_tc = r2tao_Typecode_r2t (raliased_tc, _orb);
      _tc = _orb->create_alias_tc (RSTRING(rid)->ptr, RSTRING(rname)->ptr,
                                   _aliased_tc.in ());
    }
    break;

    case CORBA::tk_sequence:
    case CORBA::tk_array:
    {
      VALUE rcontent_tc = rb_iv_get (rtc, "@content_tc");
      VALUE is_recursive_tc = rb_funcall (rcontent_tc, rb_intern ("is_recursive_tc?"), 0);
      VALUE rcont_bound = rb_iv_get (rtc, "@length");
      CORBA::ULong _bound =
          rcont_bound == Qnil ? 0 : NUM2ULONG (rcont_bound);
      if (is_recursive_tc == Qtrue)
      {
        VALUE rid = rb_iv_get (rcontent_tc, "@id");
        CORBA::TypeCode_var recursive_tc =
            _orb->create_recursive_tc (RSTRING(rid)->ptr);
        _tc = _orb->create_sequence_tc (_bound, recursive_tc.in ());
      }
      else
      {
        CORBA::TypeCode_var _ctc = r2tao_Typecode_r2t (rcontent_tc, _orb);

        if (CORBA::tk_sequence == (CORBA::TCKind)NUM2INT (rkind))
        {
          if (_bound > 0)
          {
            _tc = _orb->create_sequence_tc (_bound, _ctc.in ());
          }
          else
          {
            switch (_ctc->kind ())
            {
              case CORBA::tk_short:
                _tc = CORBA::TypeCode::_duplicate (CORBA::_tc_ShortSeq);
                break;
              case CORBA::tk_long:
                _tc = CORBA::TypeCode::_duplicate (CORBA::_tc_LongSeq);
                break;
              case CORBA::tk_ushort:
                _tc = CORBA::TypeCode::_duplicate (CORBA::_tc_UShortSeq);
                break;
              case CORBA::tk_ulong:
                _tc = CORBA::TypeCode::_duplicate (CORBA::_tc_ULongSeq);
                break;
              case CORBA::tk_longlong:
                _tc = CORBA::TypeCode::_duplicate (CORBA::_tc_LongLongSeq);
                break;
              case CORBA::tk_ulonglong:
                _tc = CORBA::TypeCode::_duplicate (CORBA::_tc_ULongLongSeq);
                break;
              case CORBA::tk_float:
                _tc = CORBA::TypeCode::_duplicate (CORBA::_tc_FloatSeq);
                break;
              case CORBA::tk_double:
                _tc = CORBA::TypeCode::_duplicate (CORBA::_tc_DoubleSeq);
                break;
              case CORBA::tk_longdouble:
                _tc = CORBA::TypeCode::_duplicate (CORBA::_tc_LongDoubleSeq);
                break;
              case CORBA::tk_boolean:
                _tc = CORBA::TypeCode::_duplicate (CORBA::_tc_BooleanSeq);
                break;
              case CORBA::tk_char:
                _tc = CORBA::TypeCode::_duplicate (CORBA::_tc_CharSeq);
                break;
              case CORBA::tk_octet:
                _tc = CORBA::TypeCode::_duplicate (CORBA::_tc_OctetSeq);
                break;
              case CORBA::tk_wchar:
                _tc = CORBA::TypeCode::_duplicate (CORBA::_tc_WCharSeq);
                break;
              default:
                _tc = _orb->create_sequence_tc (_bound, _ctc.in ());
                break;
            }
          }
        }
        else
        {
          _tc = _orb->create_array_tc (_bound, _ctc.in ());
        }
      }
    }
    break;

    case CORBA::tk_string:
    {
      ID id_length = rb_intern ("@length");
      VALUE rlength = Qnil;
      if (rb_ivar_defined (rtc, id_length) == Qtrue)
        rlength = rb_ivar_get (rtc, id_length);
      if (rlength != Qnil)
      {
        _tc = _orb->create_string_tc (NUM2ULONG (rlength));
      }
      else
      {
        _tc = CORBA::TypeCode::_duplicate (CORBA::_tc_string);
      }
    }
    break;

    case CORBA::tk_wstring:
    {
      ID id_length = rb_intern ("@length");
      VALUE rlength = Qnil;
      if (rb_ivar_defined (rtc, id_length) == Qtrue)
        rlength = rb_ivar_get (rtc, id_length);
      if (rlength != Qnil)
      {
        _tc = _orb->create_wstring_tc (NUM2ULONG (rlength));
      }
      else
      {
        _tc = CORBA::TypeCode::_duplicate (CORBA::_tc_wstring);
      }
    }
    break;

    case CORBA::tk_except:
    case CORBA::tk_struct:
    {
      VALUE rmembers = rb_iv_get (rtc, "@members");
      CHECK_RTYPE(rmembers, T_ARRAY);
      unsigned long count = static_cast<unsigned long> (RARRAY (rmembers)->len);
      CORBA::StructMemberSeq members (count);
      members.length (count);
      for (unsigned long m=0; m<count ;++m)
      {
        VALUE mset = rb_ary_entry (rmembers, m);
        CHECK_RTYPE(mset, T_ARRAY);
        VALUE mname = rb_ary_entry (mset, 0);
        CHECK_RTYPE(mname, T_STRING);
        VALUE rmtc = rb_ary_entry (mset, 1);
        CORBA::TypeCode_var mtc = r2tao_Typecode_r2t (rmtc, _orb);
        members[m].name = CORBA::string_dup (RSTRING (mname)->ptr);
        members[m].type = CORBA::TypeCode::_duplicate (mtc.in ());
      }
      VALUE repo_id = rb_iv_get (rtc, "@id");
      VALUE name = rb_iv_get (rtc, "@name");
      if (CORBA::tk_struct == (CORBA::TCKind)NUM2INT (rkind))
        _tc = _orb->create_struct_tc (RSTRING (repo_id)->ptr,
                                      RSTRING (name)->ptr,
                                      members);
      else
        _tc = _orb->create_exception_tc (RSTRING (repo_id)->ptr,
                                         RSTRING (name)->ptr,
                                         members);
    }
    break;

    case CORBA::tk_enum:
    {
      VALUE rmembers = rb_iv_get (rtc, "@members");
      CHECK_RTYPE(rmembers, T_ARRAY);
      unsigned long count = static_cast<unsigned long> (RARRAY (rmembers)->len);
      CORBA::EnumMemberSeq members (count);
      members.length (count);
      for (unsigned long m=0; m<count ;++m)
      {
        VALUE el = rb_ary_entry (rmembers, m);
        CHECK_RTYPE(el, T_STRING);
        members[m] = CORBA::string_dup (RSTRING (el)->ptr);
      }
      VALUE repo_id = rb_iv_get (rtc, "@id");
      VALUE name = rb_iv_get (rtc, "@name");
      _tc = _orb->create_enum_tc (RSTRING (repo_id)->ptr,
                                  RSTRING (name)->ptr,
                                  members);
    }
    break;

    case CORBA::tk_union:
    {
      VALUE rswtc = rb_iv_get (rtc, "@switchtype");
      CORBA::TypeCode_var swtc = r2tao_Typecode_r2t (rswtc, _orb);
      VALUE rmembers = rb_iv_get (rtc, "@members");
      CHECK_RTYPE(rmembers, T_ARRAY);
      unsigned long count = static_cast<unsigned long> (RARRAY (rmembers)->len);
      CORBA::UnionMemberSeq members (count);
      members.length (count);
      long default_inx = NUM2ULONG (rb_funcall (rtc, rb_intern ("default_index"), 0));
      for (unsigned long m=0; m<count ;++m)
      {
        VALUE mset = rb_ary_entry (rmembers, m);
        CHECK_RTYPE(mset, T_ARRAY);
        VALUE mname = rb_ary_entry (mset, 1);
        CHECK_RTYPE(mname, T_STRING);
        VALUE rmtc = rb_ary_entry (mset, 2);
        CORBA::TypeCode_var mtc = r2tao_Typecode_r2t (rmtc, _orb);
        if (default_inx<0 || default_inx != (long)m)
        {
          VALUE mlabel = rb_ary_entry (mset, 0);
          r2tao_Typecode_Ruby2Any(members[m].label, swtc.in (), mlabel, _orb);
        }
        else
        {
          CORBA::Octet defval = 0;
          members[m].label <<= CORBA::Any::from_octet(defval);
        }
        members[m].name = CORBA::string_dup (RSTRING (mname)->ptr);
        members[m].type = CORBA::TypeCode::_duplicate (mtc. in());
      }
      VALUE repo_id = rb_iv_get (rtc, "@id");
      VALUE name = rb_iv_get (rtc, "@name");
      _tc = _orb->create_union_tc (RSTRING (repo_id)->ptr,
                                   RSTRING (name)->ptr,
                                   CORBA::TypeCode::_duplicate (swtc.in ()),
                                   members);
    }
    break;

    default:
    {
    }
    break;
  }

  DATA_PTR(rtc) = CORBA::TypeCode::_duplicate (_tc. in());

  CORBA::TypeCode_ptr tc = static_cast<CORBA::TypeCode_ptr> (DATA_PTR (rtc));
  return CORBA::TypeCode::_duplicate (tc);
}

/*===================================================================
 *  Typecodeconversion CORBA --> Ruby
 *
 */

R2TAO_EXPORT VALUE r2tao_Typecode_t2r(CORBA::TypeCode_ptr _tc, CORBA::ORB_ptr _orb)
{
  VALUE rtc = Qnil;

  switch (_tc->kind ())
  {
    case CORBA::tk_null:
      rtc = rb_funcall (r2tao_nsCORBA, rb_intern ("_tc_null"), 0);
      break;
    case CORBA::tk_void:
      rtc = rb_funcall (r2tao_nsCORBA, rb_intern ("_tc_void"), 0);
      break;
    case CORBA::tk_short:
      rtc = rb_funcall (r2tao_nsCORBA, rb_intern ("_tc_short"), 0);
      break;
    case CORBA::tk_long:
      rtc = rb_funcall (r2tao_nsCORBA, rb_intern ("_tc_long"), 0);
      break;
    case CORBA::tk_ushort:
      rtc = rb_funcall (r2tao_nsCORBA, rb_intern ("_tc_ushort"), 0);
      break;
    case CORBA::tk_ulong:
      rtc = rb_funcall (r2tao_nsCORBA, rb_intern ("_tc_ulong"), 0);
      break;
    case CORBA::tk_longlong:
      rtc = rb_funcall (r2tao_nsCORBA, rb_intern ("_tc_longlong"), 0);
      break;
    case CORBA::tk_ulonglong:
      rtc = rb_funcall (r2tao_nsCORBA, rb_intern ("_tc_ulonglong"), 0);
      break;
    case CORBA::tk_float:
      rtc = rb_funcall (r2tao_nsCORBA, rb_intern ("_tc_float"), 0);
      break;
    case CORBA::tk_double:
      rtc = rb_funcall (r2tao_nsCORBA, rb_intern ("_tc_double"), 0);
      break;
    case CORBA::tk_longdouble:
      rtc = rb_funcall (r2tao_nsCORBA, rb_intern ("_tc_longdouble"), 0);
      break;
    case CORBA::tk_boolean:
      rtc = rb_funcall (r2tao_nsCORBA, rb_intern ("_tc_boolean"), 0);
      break;
    case CORBA::tk_char:
      rtc = rb_funcall (r2tao_nsCORBA, rb_intern ("_tc_char"), 0);
      break;
    case CORBA::tk_octet:
      rtc = rb_funcall (r2tao_nsCORBA, rb_intern ("_tc_octet"), 0);
      break;
    case CORBA::tk_wchar:
      rtc = rb_funcall (r2tao_nsCORBA, rb_intern ("_tc_wchar"), 0);
      break;
    case CORBA::tk_any:
      rtc = rb_funcall (r2tao_nsCORBA, rb_intern ("_tc_any"), 0);
      break;
    case CORBA::tk_TypeCode:
      rtc = rb_funcall (r2tao_nsCORBA, rb_intern ("_tc_TypeCode"), 0);
      break;
    case CORBA::tk_Principal:
      rtc = rb_funcall (r2tao_nsCORBA, rb_intern ("_tc_Principal"), 0);
      break;
    case CORBA::tk_alias:
    {
      VALUE rid = rb_str_new2 (_tc->id ());
      rtc = rb_funcall (r2tao_cTypecode, rb_intern ("typecode_for_id"), 1, rid);
      if (rtc == Qnil)
      {
        CORBA::TypeCode_var alias_tc = _tc->content_type ();
        VALUE ralias_tc = r2tao_Typecode_t2r(alias_tc.in (), _orb);
        VALUE argv[4];
        argv[0] = rid;
        argv[1] = rb_str_new2 (_tc->name ());
        argv[2] = Qnil;
        argv[3] = ralias_tc;
        rtc = rb_class_new_instance (4, argv, rb_eval_string ("::CORBA::TypeCode::Alias"));
        DATA_PTR(rtc) = CORBA::TypeCode::_duplicate (_tc);
      }
      break;
    }
    case CORBA::tk_string:
    {
      if (_tc->length ()>0)
      {
        VALUE argv[1];
        argv[0] = ULL2NUM (_tc->length ());
        rtc = rb_class_new_instance (1, argv, rb_eval_string ("::CORBA::TypeCode::String"));
        DATA_PTR(rtc) = CORBA::TypeCode::_duplicate (_tc);
      }
      else
      {
        rtc = rb_funcall (r2tao_nsCORBA, rb_intern ("_tc_string"), 0);
      }
      break;
    }
    case CORBA::tk_wstring:
    {
      if (_tc->length ()>0)
      {
        VALUE argv[1];
        argv[0] = ULL2NUM (_tc->length ());
        rtc = rb_class_new_instance (1, argv, rb_eval_string ("::CORBA::TypeCode::WString"));
        DATA_PTR(rtc) = CORBA::TypeCode::_duplicate (_tc);
      }
      else
      {
        rtc = rb_funcall (r2tao_nsCORBA, rb_intern ("_tc_wstring"), 0);
      }
      break;
    }
    case CORBA::tk_objref:
    {
      VALUE rid = rb_str_new2 (_tc->id ());
      rtc = rb_funcall (r2tao_cTypecode, rb_intern ("typecode_for_id"), 1, rid);
      if (rtc == Qnil)
      {
        VALUE argv[3];
        argv[0] = rid;
        argv[1] = rb_str_new2 (_tc->name ());
        argv[2] = r2tao_cObject;
        rtc = rb_class_new_instance (3, argv, rb_eval_string ("::CORBA::TypeCode::ObjectRef"));
        DATA_PTR(rtc) = CORBA::TypeCode::_duplicate (_tc);
      }
      break;
    }
    case CORBA::tk_home:
    {
      VALUE rid = rb_str_new2 (_tc->id ());
      rtc = rb_funcall (r2tao_cTypecode, rb_intern ("typecode_for_id"), 1, rid);
      if (rtc == Qnil)
      {
        VALUE argv[3];
        argv[0] = rid;
        argv[1] = rb_str_new2 (_tc->name ());
        argv[2] = r2tao_cObject;
        rtc = rb_class_new_instance (3, argv, rb_eval_string ("::CORBA::TypeCode::Home"));
        DATA_PTR(rtc) = CORBA::TypeCode::_duplicate (_tc);
      }
      break;
    }
    case CORBA::tk_component:
    {
      VALUE rid = rb_str_new2 (_tc->id ());
      rtc = rb_funcall (r2tao_cTypecode, rb_intern ("typecode_for_id"), 1, rid);
      if (rtc == Qnil)
      {
        VALUE argv[3];
        argv[0] = rid;
        argv[1] = rb_str_new2 (_tc->name ());
        argv[2] = r2tao_cObject;
        rtc = rb_class_new_instance (3, argv, rb_eval_string ("::CORBA::TypeCode::Component"));
        DATA_PTR(rtc) = CORBA::TypeCode::_duplicate (_tc);
      }
      break;
    }
    case CORBA::tk_sequence:
    {
      CORBA::TypeCode_var ctc = _tc->content_type ();
      VALUE rcontent_tc = r2tao_Typecode_t2r(ctc.in (), _orb);
      VALUE argv[2];
      argv[0] = rcontent_tc;
      argv[1] = _tc->length ()>0 ? ULL2NUM (_tc->length ()) : Qnil;
      rtc = rb_class_new_instance (2, argv, rb_eval_string ("::CORBA::TypeCode::Sequence"));
      DATA_PTR(rtc) = CORBA::TypeCode::_duplicate (_tc);
      break;
    }
    case CORBA::tk_array:
    {
      // count dimensions
      int numsizes = 1;
      CORBA::TypeCode_var _ctc = _tc->content_type ();
      while (_ctc->kind () == CORBA::tk_array)
      {
        numsizes++;
        _ctc = _ctc->content_type ();
      }

      // get actual content type
      VALUE rcontent_tc = r2tao_Typecode_t2r(_ctc.in (), _orb);

      // setup constructor arguments
      ACE_Auto_Basic_Ptr<VALUE>   argv(new VALUE[1+numsizes]);
      argv.get()[0] = rcontent_tc;
      argv.get()[1] = ULL2NUM (_tc->length ()); 
      _ctc = _tc->content_type ();
      for (int i=1; i<numsizes ;++i)
      {
        argv.get()[i+1] = ULL2NUM (_ctc->length ());
        _ctc = _ctc->content_type ();
      }

      // create new Array typecode
      rtc = rb_class_new_instance (numsizes+1, argv.get(), rb_eval_string ("::CORBA::TypeCode::Array"));
      DATA_PTR(rtc) = CORBA::TypeCode::_duplicate (_tc);
      break;
    }
    case CORBA::tk_except:
    case CORBA::tk_struct:
    {
      VALUE rid = rb_str_new2 (_tc->id ());
      rtc = rb_funcall (r2tao_cTypecode, rb_intern ("typecode_for_id"), 1, rid);
      if (rtc == Qnil)
      {
        unsigned long mcount = _tc->member_count ();
        VALUE rmembers = rb_ary_new2 (mcount);
        for (unsigned long l=0; l<mcount ;++l)
        {
          VALUE rmember = rb_ary_new2 (2);
          rb_ary_push (rmember, rb_str_new2 (_tc->member_name (l)));
          CORBA::TypeCode_var mtc = _tc->member_type (l);
          rb_ary_push (rmember, r2tao_Typecode_t2r (mtc.in (), _orb));
          rb_ary_push (rmembers, rmember);
        }
        VALUE argv[4];
        argv[0] = rid;
        argv[1] = rb_str_new2 (_tc->name ());
        argv[2] = Qnil;
        argv[3] = rmembers;
        rtc = rb_class_new_instance (4, argv,
          _tc->kind () == CORBA::tk_struct ?
              rb_eval_string ("::CORBA::TypeCode::Struct") :
              rb_eval_string ("::CORBA::TypeCode::Except"));
        DATA_PTR(rtc) = CORBA::TypeCode::_duplicate (_tc);
      }
      break;
    }
    case CORBA::tk_enum:
    {
      VALUE rid = rb_str_new2 (_tc->id ());
      rtc = rb_funcall (r2tao_cTypecode, rb_intern ("typecode_for_id"), 1, rid);
      if (rtc == Qnil)
      {
        unsigned long mcount = _tc->member_count ();
        VALUE rmembers = rb_ary_new2 (mcount);
        for (unsigned long l=0; l<mcount ;++l)
        {
          rb_ary_push (rmembers, rb_str_new2 (_tc->member_name (l)));
        }
        VALUE argv[3];
        argv[0] = rid;
        argv[1] = rb_str_new2 (_tc->name ());
        argv[2] = rmembers;
        rtc = rb_class_new_instance (3, argv, rb_eval_string ("::CORBA::TypeCode::Enum"));
        DATA_PTR(rtc) = CORBA::TypeCode::_duplicate (_tc);
      }
      break;
    }
    case CORBA::tk_union:
    {
      VALUE rid = rb_str_new2 (_tc->id ());
      rtc = rb_funcall (r2tao_cTypecode, rb_intern ("typecode_for_id"), 1, rid);
      if (rtc == Qnil)
      {
        CORBA::TypeCode_var swtc = _tc->discriminator_type ();
        VALUE rswtc = r2tao_Typecode_t2r (swtc.in (), _orb);
        unsigned long mcount = _tc->member_count ();
        VALUE rmembers = rb_ary_new2 (mcount);
        long default_inx = _tc->default_index ();
        for (unsigned long l=0; l<mcount ;++l)
        {
          VALUE rmember = rb_ary_new2 (2);
          if (default_inx<0 || default_inx != (long)l)
          {
            rb_ary_push (rmember, r2tao_Typecode_Any2Ruby(*_tc->member_label (l), swtc.in (), rswtc, rswtc, _orb));
          }
          else
          {
            rb_ary_push (rmember, r2tao_sym_default);
          }
          rb_ary_push (rmember, rb_str_new2 (_tc->member_name (l)));
          CORBA::TypeCode_var mtc = _tc->member_type (l);
          rb_ary_push (rmember, r2tao_Typecode_t2r (mtc.in (), _orb));
          rb_ary_push (rmembers, rmember);
        }
        VALUE argv[5];
        argv[0] = rid;
        argv[1] = rb_str_new2 (_tc->name ());
        argv[2] = Qnil;
        argv[3] = rswtc;
        argv[4] = rmembers;
        rtc = rb_class_new_instance (4, argv,
                rb_eval_string ("::CORBA::TypeCode::Union"));
        DATA_PTR(rtc) = CORBA::TypeCode::_duplicate (_tc);
      }
      break;
    }
    default:
      return Qnil;
  }

  if (rtc == Qnil)
  {
    ACE_ERROR ((LM_ERROR, "R2TAO::Unable to convert TAO typecode to Ruby\n"));

    throw ::CORBA::BAD_TYPECODE (0, CORBA::COMPLETED_NO);
  }

  return rtc;
}

/*===================================================================
 *  Dynamic Any factory
 *
 */
DynamicAny::DynAny_ptr r2tao_Typecode_CreateDynAny (CORBA::ORB_ptr _orb, const CORBA::Any& _any)
{
  CORBA::Object_var factory_obj =
    _orb->resolve_initial_references ("DynAnyFactory");

  DynamicAny::DynAnyFactory_var dynany_factory =
    DynamicAny::DynAnyFactory::_narrow (factory_obj.in ());

  if (CORBA::is_nil (dynany_factory.in ()))
  {
    ACE_ERROR ((LM_ERROR, "R2TAO::Unable to resolve DynAnyFactory\n"));

    throw ::CORBA::INV_OBJREF (0, CORBA::COMPLETED_NO);
  }

  DynamicAny::DynAny_ptr da =
    dynany_factory->create_dyn_any (_any);

  return da;
}

DynamicAny::DynAny_ptr r2tao_Typecode_CreateDynAny4tc (CORBA::ORB_ptr _orb, CORBA::TypeCode_ptr _tc)
{
  CORBA::Object_var factory_obj =
    _orb->resolve_initial_references ("DynAnyFactory");

  DynamicAny::DynAnyFactory_var dynany_factory =
    DynamicAny::DynAnyFactory::_narrow (factory_obj.in ());

  if (CORBA::is_nil (dynany_factory.in ()))
  {
    ACE_ERROR ((LM_ERROR, "R2TAO::Unable to resolve DynAnyFactory\n"));

    throw ::CORBA::INV_OBJREF (0, CORBA::COMPLETED_NO);
  }

  DynamicAny::DynAny_ptr da =
    dynany_factory->create_dyn_any_from_type_code (_tc);

  return da;
}

/*===================================================================
 *  Dataconversion Ruby --> CORBA Any
 *
 */
void r2tao_Typecode_Ruby2Struct (CORBA::Any& _any, CORBA::TypeCode_ptr _tc, VALUE rs, CORBA::ORB_ptr _orb)
{
  DynamicAny::DynAny_var da = r2tao_Typecode_CreateDynAny4tc (_orb, _tc);
  DynamicAny::DynStruct_var das = DynamicAny::DynStruct::_narrow (da.in ());

  if (rs != Qnil)
  {
    CORBA::ULong mcount = _tc->member_count ();

    DynamicAny::NameValuePairSeq_var nvps = das->get_members ();

    for (CORBA::ULong m=0; m<mcount ;++m)
    {
      CORBA::TypeCode_var mtc = _tc->member_type (m);
      VALUE mval = rb_funcall (rs, rb_intern (_tc->member_name (m)), 0);
      r2tao_Typecode_Ruby2Any (nvps[m].value, mtc.in (), mval, _orb);
    }

    das->set_members (nvps);
  }

  CORBA::Any_var av = das->to_any ();
  _any = av.in ();

  das->destroy ();
}

void r2tao_Typecode_Ruby2Union (CORBA::Any& _any, CORBA::TypeCode_ptr _tc, VALUE ru, CORBA::ORB_ptr _orb)
{
  if (TAO_debug_level > 5)
    ACE_DEBUG ((LM_INFO, "R2TAO (%P|%t) - Typecode_Ruby2Union:: kind=%d, rval=%d\n", _tc->kind (), ru));

  DynamicAny::DynAny_var da = r2tao_Typecode_CreateDynAny4tc (_orb, _tc);
  DynamicAny::DynUnion_var dau = DynamicAny::DynUnion::_narrow (da.in ());

  if (ru != Qnil)
  {
    VALUE at_default = rb_funcall (ru, rb_intern ("_is_at_default?"), 0);
    VALUE value = rb_iv_get (ru, "@value");
    VALUE disc = rb_iv_get (ru, "@discriminator");
    if (at_default == Qfalse)
    {
      if (disc == Qnil)
      {
        dau->set_to_no_active_member ();
      }
      else
      {
        CORBA::Any_var _any = new CORBA::Any;
        CORBA::TypeCode_var dtc = _tc->discriminator_type ();
        r2tao_Typecode_Ruby2Any(*_any, dtc.in (), disc, _orb);
        DynamicAny::DynAny_var _dyna = r2tao_Typecode_CreateDynAny (_orb, *_any);
        dau->set_discriminator (_dyna.in ());
      }
    }
    else
    {
      dau->set_to_default_member ();
    }

    if (disc != Qnil && value != Qnil)
    {
      VALUE rvaltc = rb_funcall (ru, rb_intern("_value_tc"), 0);
      CORBA::TypeCode_var valtc = r2tao_Typecode_r2t (rvaltc, _orb);
      CORBA::Any_var _any = new CORBA::Any;
      r2tao_Typecode_Ruby2Any(*_any, valtc.in (), value, _orb);
      DynamicAny::DynAny_var dynval = dau->member ();
      dynval->from_any (*_any);
    }
  }

  CORBA::Any_var av = dau->to_any ();
  _any = av.in ();

  dau->destroy ();
}

void r2tao_Typecode_Ruby2Sequence(CORBA::Any& _any, CORBA::TypeCode_ptr _tc, VALUE rarr, CORBA::ORB_ptr _orb)
{
  CORBA::TypeCode_var _ctc = _tc->content_type ();
  if (TAO_debug_level > 5)
    ACE_DEBUG ((LM_INFO, "R2TAO (%P|%t) - Typecode_Ruby2Sequence:: content kind=%d, rval type=%d\n", _ctc->kind (), rb_type (rarr)));

  CORBA::ULong alen = 0;
  if (rarr != Qnil)
  {
    switch (_ctc->kind ())
    {
      case CORBA::tk_char:
      case CORBA::tk_octet:
        CHECK_RTYPE(rarr, T_STRING);
        alen = static_cast<unsigned long> (RSTRING (rarr)->len);
        break;
      default:
        CHECK_RTYPE(rarr, T_ARRAY);
        alen = static_cast<unsigned long> (RARRAY (rarr)->len);
        break;
    }
  }

  switch (_ctc->kind ())
  {
    case CORBA::tk_short:
    {
      CORBA::ShortSeq_var tmp = new CORBA::ShortSeq();
      tmp->length (alen);
      for (CORBA::ULong l=0; l<alen ;++l)
      {
        VALUE el = rb_ary_entry (rarr, l);
        tmp[l] = (CORBA::Short)NUM2INT (el);
      }
      _any <<= tmp;
      return;
    }
    case CORBA::tk_long:
    {
      CORBA::LongSeq_var tmp = new CORBA::LongSeq();
      tmp->length (alen);
      for (CORBA::ULong l=0; l<alen ;++l)
      {
        VALUE el = rb_ary_entry (rarr, l);
        tmp[l] = (CORBA::Long)NUM2LONG (el);
      }
      _any <<= tmp;
      return;
    }
    case CORBA::tk_ushort:
    {
      CORBA::UShortSeq_var tmp = new CORBA::UShortSeq();
      tmp->length (alen);
      for (CORBA::ULong l=0; l<alen ;++l)
      {
        VALUE el = rb_ary_entry (rarr, l);
        tmp[l] = (CORBA::UShort)NUM2UINT (el);
      }
      _any <<= tmp;
      return;
    }
    case CORBA::tk_ulong:
    {
      CORBA::ULongSeq_var tmp = new CORBA::ULongSeq();
      tmp->length (alen);
      for (CORBA::ULong l=0; l<alen ;++l)
      {
        VALUE el = rb_ary_entry (rarr, l);
        tmp[l] = (CORBA::ULong)NUM2ULONG (el);
      }
      _any <<= tmp;
      return;
    }
    case CORBA::tk_longlong:
    {
      CORBA::LongLongSeq_var tmp = new CORBA::LongLongSeq();
      tmp->length (alen);
      for (CORBA::ULong l=0; l<alen ;++l)
      {
        VALUE el = rb_ary_entry (rarr, l);
        tmp[l] = (CORBA::LongLong)NUM2LL (el);
      }
      _any <<= tmp;
      return;
    }
    case CORBA::tk_ulonglong:
    {
      CORBA::ULongLongSeq_var tmp = new CORBA::ULongLongSeq();
      tmp->length (alen);
      for (CORBA::ULong l=0; l<alen ;++l)
      {
        VALUE el = rb_ary_entry (rarr, l);
        tmp[l] = (CORBA::ULongLong)NUM2ULL (el);
      }
      _any <<= tmp;
      return;
    }
    case CORBA::tk_float:
    {
      CORBA::FloatSeq_var tmp = new CORBA::FloatSeq();
      tmp->length (alen);
      for (CORBA::ULong l=0; l<alen ;++l)
      {
        VALUE el = rb_ary_entry (rarr, l);
        tmp[l] = (CORBA::Float)NUM2DBL (el);
      }
      _any <<= tmp;
      return;
    }
    case CORBA::tk_double:
    {
      CORBA::DoubleSeq_var tmp = new CORBA::DoubleSeq();
      tmp->length (alen);
      for (CORBA::ULong l=0; l<alen ;++l)
      {
        VALUE el = rb_ary_entry (rarr, l);
        tmp[l] = (CORBA::Double)NUM2DBL (el);
      }
      _any <<= tmp;
      return;
    }
    case CORBA::tk_longdouble:
    {
      CORBA::LongDoubleSeq_var tmp = new CORBA::LongDoubleSeq();
      tmp->length (alen);
      for (CORBA::ULong l=0; l<alen ;++l)
      {
        VALUE el = rb_ary_entry (rarr, l);
        ACE_CDR_LONG_DOUBLE_ASSIGNMENT (tmp[l], CLD2RLD (el));
      }
      _any <<= tmp;
      return;
    }
    case CORBA::tk_boolean:
    {
      CORBA::BooleanSeq_var tmp = new CORBA::BooleanSeq();
      tmp->length (alen);
      for (CORBA::ULong l=0; l<alen ;++l)
      {
        VALUE el = rb_ary_entry (rarr, l);
        tmp[l] = (CORBA::Boolean)(el == Qtrue ? true : false);
      }
      _any <<= tmp;
      return;
    }
    case CORBA::tk_char:
    {
      char* s = rarr != Qnil ? RSTRING (rarr)->ptr : 0;
      CORBA::CharSeq_var tmp = new CORBA::CharSeq();
      tmp->length (alen);
      for (unsigned long l=0; l<alen ;++l)
      {
        tmp[l] = s[l];
      }
      _any <<= tmp;
      return;
    }
    case CORBA::tk_octet:
    {
      unsigned char* s = rarr != Qnil ? (unsigned char*)RSTRING (rarr)->ptr : 0;
      CORBA::OctetSeq_var tmp = new CORBA::OctetSeq();
      tmp->length (alen);
      for (unsigned long l=0; l<alen ;++l)
      {
        tmp[l] = s[l];
      }
      _any <<= tmp;
      return;
    }
    case CORBA::tk_wchar:
    {
      CORBA::WCharSeq_var tmp = new CORBA::WCharSeq();
      tmp->length (alen);
      for (CORBA::ULong l=0; l<alen ;++l)
      {
        VALUE el = rb_ary_entry (rarr, l);
        tmp[l] = (CORBA::WChar)NUM2INT (el);
      }
      _any <<= tmp;
      return;
    }
    default:
    {
      DynamicAny::DynAny_var da = r2tao_Typecode_CreateDynAny4tc (_orb, _tc);
      DynamicAny::DynSequence_var das = DynamicAny::DynSequence::_narrow (da.in ());

      if (rarr != Qnil && alen > 0)
      {
        CORBA::ULong seqmax = _tc->length ();

        DynamicAny::AnySeq_var elems =
          seqmax == 0 ? new DynamicAny::AnySeq () : new DynamicAny::AnySeq (seqmax);
        elems->length (alen);

        for (CORBA::ULong e=0; e<alen ;++e)
        {
          VALUE eval = rb_ary_entry (rarr, e);
          r2tao_Typecode_Ruby2Any (elems[e], _ctc.in (), eval, _orb);
        }

        das->set_elements (elems);
      }

      CORBA::Any_var av = das->to_any ();
      _any = av.in ();

      das->destroy ();
      return;
    }
  }

  ACE_ERROR ((LM_ERROR, "R2TAO::Unable to convert Ruby sequence to TAO\n"));
  throw ::CORBA::NO_IMPLEMENT (0, CORBA::COMPLETED_NO);
}

R2TAO_EXPORT void r2tao_Typecode_Ruby2Any(CORBA::Any& _any, CORBA::TypeCode_ptr _tc, VALUE rval, CORBA::ORB_ptr _orb)
{
  if (TAO_debug_level > 5)
    ACE_DEBUG ((LM_INFO, "R2TAO (%P|%t) - Typecode_Ruby2Any:: kind=%d, rval=%d\n", _tc->kind (), rval));

  switch (_tc->kind ())
  {
    case CORBA::tk_null:
    case CORBA::tk_void:
      break;
    case CORBA::tk_alias:
    {
      CORBA::TypeCode_var _ctc = _tc->content_type ();
      r2tao_Typecode_Ruby2Any(_any, _ctc.in (), rval, _orb);
      return;
    }
    case CORBA::tk_short:
    {
      CORBA::Short val = rval == Qnil ? 0 : NUM2INT (rval);
      _any <<= val;
      return;
    }
    case CORBA::tk_long:
    {
      CORBA::Long val = rval == Qnil ? 0 : NUM2INT (rval);
      _any <<= val;
      return;
    }
    case CORBA::tk_ushort:
    {
      CORBA::UShort val = rval == Qnil ? 0 : NUM2UINT (rval);
      _any <<= val;
      return;
    }
    case CORBA::tk_ulong:
    {
      CORBA::ULong val = rval == Qnil ? 0 : NUM2ULONG (rval);
      _any <<= val;
      return;
    }
    case CORBA::tk_longlong:
    {
      CORBA::LongLong val = rval == Qnil ? 0 : NUM2LL (rval);
      _any <<= val;
      return;
    }
    case CORBA::tk_ulonglong:
    {
      CORBA::ULongLong val = rval == Qnil ? 0 : NUM2ULL (rval);
      _any <<= val;
      return;
    }
    case CORBA::tk_float:
    {
      CORBA::Float val = rval == Qnil ? 0.0f : (CORBA::Float)NUM2DBL (rval);
      _any <<= val;
      return;
    }
    case CORBA::tk_double:
    {
      CORBA::Double val = rval == Qnil ? 0.0 : NUM2DBL (rval);
      _any <<= val;
      return;
    }
    case CORBA::tk_longdouble:
    {
      CORBA::LongDouble val;
      ACE_CDR_LONG_DOUBLE_ASSIGNMENT (val, rval == Qnil ? 0.0 : RLD2CLD (rval));
      _any <<= val;
      return;
    }
    case CORBA::tk_boolean:
    {
      CORBA::Boolean val = (rval == Qnil || rval == Qfalse) ? 0 : 1;
      _any <<= CORBA::Any::from_boolean (val);
      return;
    }
    case CORBA::tk_char:
    {
      CORBA::Char val = 0;
      if (rval != Qnil)
      {
        CHECK_RTYPE(rval, T_STRING);
        val = *RSTRING (rval)->ptr;
      }
      _any <<= CORBA::Any::from_char (val);
      return;
    }
    case CORBA::tk_octet:
    {
      CORBA::Octet  val = rval == Qnil ? 0 : NUM2UINT (rval);
      _any <<= CORBA::Any::from_octet (val);
      return;
    }
    case CORBA::tk_wchar:
    {
      CORBA::WChar val = rval == Qnil ? 0 : NUM2UINT (rval);
      _any <<= CORBA::Any::from_wchar (val);
      return;
    }
    case CORBA::tk_string:
    {
      if (rval == Qnil)
      {
        _any <<= (char*)0;
      }
      else
      {
        CHECK_RTYPE(rval, T_STRING);
        _any <<= RSTRING (rval)->ptr;
      }
      return;
    }
    case CORBA::tk_wstring:
    {
      if (rval == Qnil)
      {
        _any <<= (CORBA::WChar*)0;
      }
      else
      {
        CHECK_RTYPE(rval, T_ARRAY);
        CORBA::ULong alen = static_cast<unsigned long> (RARRAY (rval)->len);
        CORBA::WString_var ws = CORBA::wstring_alloc (alen+1);
        for (CORBA::ULong l=0; l<alen ;++l)
        {
          ws[l] = static_cast<CORBA::WChar> (NUM2INT (rb_ary_entry (rval, l)));
        }
        ws[alen] = static_cast<CORBA::WChar> (0);
        _any <<= ws;
      }
      return;
    }
    case CORBA::tk_enum:
    {
      DynamicAny::DynAny_var da = r2tao_Typecode_CreateDynAny4tc (_orb, _tc);
      DynamicAny::DynEnum_var das = DynamicAny::DynEnum::_narrow (da.in ());

      if (rval != Qnil)
      {
        das->set_as_ulong (NUM2ULONG (rval));
      }

      CORBA::Any_var av = das->to_any ();
      _any = av.in ();

      das->destroy ();
      return;
    }
    case CORBA::tk_array:
    {
      DynamicAny::DynAny_var da = r2tao_Typecode_CreateDynAny4tc (_orb, _tc);
      DynamicAny::DynArray_var das = DynamicAny::DynArray::_narrow (da.in ());

      if (rval != Qnil)
      {
        CORBA::ULong arrlen = _tc->length ();

        DynamicAny::AnySeq_var elems = new DynamicAny::AnySeq (arrlen);
        elems->length (arrlen);

        CORBA::TypeCode_var etc = _tc->content_type ();

        for (CORBA::ULong e=0; e<arrlen ;++e)
        {
          VALUE eval = rb_ary_entry (rval, e);
          r2tao_Typecode_Ruby2Any (elems[e], etc.in (), eval, _orb);
        }

        das->set_elements (elems);
      }

      CORBA::Any_var av = das->to_any ();
      _any = av.in ();

      das->destroy ();
      return;
    }
    case CORBA::tk_sequence:
    {
      r2tao_Typecode_Ruby2Sequence(_any, _tc, rval, _orb);
      return;
    }
    case CORBA::tk_except:
    case CORBA::tk_struct:
    {
      r2tao_Typecode_Ruby2Struct (_any, _tc, rval, _orb);
      return;
    }
    case CORBA::tk_union:
    {
      r2tao_Typecode_Ruby2Union (_any, _tc, rval, _orb);
      return;
    }
    case CORBA::tk_objref:
    {
      if (rval != Qnil)
      {
        _any <<= r2tao_Object_r2t (rval);
      }
      else
      {
        _any <<= CORBA::Object::_nil ();
      }
      return;
    }
    case CORBA::tk_any:
    {
      CORBA::Any  anyval;
      r2tao_Ruby_to_Any(anyval, rval, _orb);
      _any <<= anyval;
      return;
    }
    case CORBA::tk_TypeCode:
    {
      if (rval != Qnil)
      {
        CORBA::TypeCode_var tctc = r2tao_Typecode_r2t (rval, _orb);
        _any <<= tctc.in ();
      }
      else
      {
        _any <<= CORBA::TypeCode::_nil ();
      }
      return;
    }
    case CORBA::tk_Principal:
    {
      break;
    }
    default:
      break;
  }

  ACE_ERROR ((LM_ERROR, "R2TAO::Unable to convert Ruby data to TAO\n"));
  throw ::CORBA::NO_IMPLEMENT (0, CORBA::COMPLETED_NO);
}

void r2tao_Ruby_to_Any(CORBA::Any& _any, VALUE val, CORBA::ORB_ptr _orb)
{
  if (val != Qnil)
  {
    VALUE rvaltc = rb_funcall (r2tao_cAny, typecode_for_any_ID, 1, val);
    if (rvaltc == Qnil)
    {
      ACE_ERROR ((LM_ERROR, "R2TAO::invalid datatype for CORBA::Any\n"));

      throw ::CORBA::MARSHAL (0, ::CORBA::COMPLETED_NO);
    }

    CORBA::TypeCode_var atc = r2tao_Typecode_r2t (rvaltc, _orb);
    r2tao_Typecode_Ruby2Any (_any,
                              atc.in (),
                              rb_funcall (r2tao_cAny, value_for_any_ID, 1, val),
                              _orb);
  }
}

/*===================================================================
 *  Dataconversion CORBA Any --> Ruby
 *
 */
#define R2TAO_TCTYPE(rtc) \
  rb_funcall ((rtc), get_type_ID, 0)

#define R2TAO_NEW_TCOBJECT(rtc) \
  rb_class_new_instance (0, 0, rb_funcall ((rtc), get_type_ID, 0))

VALUE r2tao_Typecode_Struct2Ruby (const CORBA::Any& _any, CORBA::TypeCode_ptr _tc, VALUE rtc, VALUE roottc, CORBA::ORB_ptr _orb)
{
  DynamicAny::DynAny_var da = r2tao_Typecode_CreateDynAny (_orb, _any);
  DynamicAny::DynStruct_var das = DynamicAny::DynStruct::_narrow (da.in ());

  VALUE new_rs = R2TAO_NEW_TCOBJECT (roottc);

  CORBA::ULong mcount = _tc->member_count ();

  DynamicAny::NameValuePairSeq_var nvps = das->get_members ();

  VALUE rtc_members = rb_iv_get (rtc, "@members");

  for (CORBA::ULong m=0; m<mcount ;++m)
  {
    CORBA::TypeCode_var mtc = _tc->member_type (m);
    VALUE mset = rb_ary_entry (rtc_members, m);
    VALUE mrtc = rb_ary_entry (mset, 1);
    VALUE rmval = r2tao_Typecode_Any2Ruby (nvps[m].value, mtc.in (), mrtc, mrtc, _orb);
    const char* name = _tc->member_name (m);
    CORBA::String_var mname = CORBA::string_alloc (2 + ACE_OS::strlen (name));
    ACE_OS::sprintf ((char*)mname.in (), "@%s", name);
    rb_iv_set (new_rs, mname.in (), rmval);
  }

  das->destroy ();

  return new_rs;
}

VALUE r2tao_Typecode_Union2Ruby (const CORBA::Any& _any, CORBA::TypeCode_ptr _tc, VALUE rtc, VALUE roottc, CORBA::ORB_ptr _orb)
{
  VALUE new_ru = R2TAO_NEW_TCOBJECT (roottc);

  DynamicAny::DynAny_var da = r2tao_Typecode_CreateDynAny (_orb, _any);
  DynamicAny::DynUnion_var dau = DynamicAny::DynUnion::_narrow (da.in ());

  if (!dau->has_no_active_member ())
  {
    DynamicAny::DynAny_var dyndisc = dau->get_discriminator ();
    CORBA::Any_var anydisc = dyndisc->to_any ();
    CORBA::Octet defval;
    VALUE rdisc;
    if ((anydisc >>= CORBA::Any::to_octet (defval)) == 1 && defval == 0)
    {
      rdisc = r2tao_sym_default;
    }
    else
    {
      VALUE rdisctype = rb_funcall (rtc, rb_intern ("discriminator_type"), 0);
      CORBA::TypeCode_var dtc = _tc->discriminator_type ();
      rdisc = r2tao_Typecode_Any2Ruby (*anydisc, dtc.in (), rdisctype, rdisctype, _orb);
    }
    rb_iv_set (new_ru, "@discriminator", rdisc);

    DynamicAny::DynAny_var dynval = dau->member ();
    CORBA::Any_var anyval = dynval->to_any ();
    VALUE rvaltc = rb_funcall (new_ru, rb_intern ("_value_tc"), 0);
    CORBA::TypeCode_var valtc = r2tao_Typecode_r2t (rvaltc, _orb);
    VALUE rvalue = r2tao_Typecode_Any2Ruby (*anyval, valtc.in (), rvaltc, rvaltc, _orb);
    rb_iv_set (new_ru, "@value", rvalue);
  }

  dau->destroy ();

  return new_ru;
}

VALUE r2tao_Typecode_Sequence2Ruby(const CORBA::Any& _any, CORBA::TypeCode_ptr _tc, VALUE rtc, VALUE roottc, CORBA::ORB_ptr _orb)
{
  VALUE rtcklass = R2TAO_TCTYPE(roottc);

  switch (_tc->content_type ()->kind ())
  {
    case CORBA::tk_short:
    {
      const CORBA::ShortSeq* tmp;
      if (TAO::Any_Dual_Impl_T<CORBA::ShortSeq>::extract (
            _any,
            CORBA::ShortSeq::_tao_any_destructor,
            _tc,
            tmp))
      {
        VALUE ret = (rtcklass == rb_cArray) ?
              rb_ary_new2 ((long)tmp->length ()) :
              rb_class_new_instance (0, 0, rtcklass);
        for (CORBA::ULong l=0; l<tmp->length () ;++l)
        {
          rb_ary_push (ret, INT2FIX ((int)(*tmp)[l]));
        }
        return ret;
      }
      break;
    }
    case CORBA::tk_long:
    {
      const CORBA::LongSeq* tmp;
      if (TAO::Any_Dual_Impl_T<CORBA::LongSeq>::extract (
            _any,
            CORBA::LongSeq::_tao_any_destructor,
            _tc,
            tmp))
      {
        VALUE ret = (rtcklass == rb_cArray) ?
              rb_ary_new2 ((long)tmp->length ()) :
              rb_class_new_instance (0, 0, rtcklass);
        for (CORBA::ULong l=0; l<tmp->length () ;++l)
        {
          rb_ary_push (ret, INT2FIX ((long)(*tmp)[l]));
        }
        return ret;
      }
      break;
    }
    case CORBA::tk_ushort:
    {
      const CORBA::UShortSeq* tmp;
      if (TAO::Any_Dual_Impl_T<CORBA::UShortSeq>::extract (
            _any,
            CORBA::UShortSeq::_tao_any_destructor,
            _tc,
            tmp))
      {
        VALUE ret = (rtcklass == rb_cArray) ?
              rb_ary_new2 ((long)tmp->length ()) :
              rb_class_new_instance (0, 0, rtcklass);
        for (CORBA::ULong l=0; l<tmp->length () ;++l)
        {
          rb_ary_push (ret, INT2FIX ((int)(*tmp)[l]));
        }
        return ret;
      }
      break;
    }
    case CORBA::tk_ulong:
    {
      const CORBA::ULongSeq* tmp;
      if (TAO::Any_Dual_Impl_T<CORBA::ULongSeq>::extract (
            _any,
            CORBA::ULongSeq::_tao_any_destructor,
            _tc,
            tmp))
      {
        VALUE ret = (rtcklass == rb_cArray) ?
              rb_ary_new2 ((long)tmp->length ()) :
              rb_class_new_instance (0, 0, rtcklass);
        for (CORBA::ULong l=0; l<tmp->length () ;++l)
        {
          rb_ary_push (ret, ULONG2NUM ((unsigned long)(*tmp)[l]));
        }
        return ret;
      }
      break;
    }
    case CORBA::tk_longlong:
    {
      const CORBA::LongLongSeq* tmp;
      if (TAO::Any_Dual_Impl_T<CORBA::LongLongSeq>::extract (
            _any,
            CORBA::LongLongSeq::_tao_any_destructor,
            _tc,
            tmp))
      {
        VALUE ret = (rtcklass == rb_cArray) ?
              rb_ary_new2 ((long)tmp->length ()) :
              rb_class_new_instance (0, 0, rtcklass);
        for (CORBA::ULong l=0; l<tmp->length () ;++l)
        {
          rb_ary_push (ret, LL2NUM ((*tmp)[l]));
        }
        return ret;
      }
      break;
    }
    case CORBA::tk_ulonglong:
    {
      const CORBA::ULongLongSeq* tmp;
      if (TAO::Any_Dual_Impl_T<CORBA::ULongLongSeq>::extract (
            _any,
            CORBA::ULongLongSeq::_tao_any_destructor,
            _tc,
            tmp))
      {
        VALUE ret = (rtcklass == rb_cArray) ?
              rb_ary_new2 ((long)tmp->length ()) :
              rb_class_new_instance (0, 0, rtcklass);
        for (CORBA::ULong l=0; l<tmp->length () ;++l)
        {
          rb_ary_push (ret, ULL2NUM ((*tmp)[l]));
        }
        return ret;
      }
      break;
    }
    case CORBA::tk_float:
    {
      const CORBA::FloatSeq* tmp;
      if (TAO::Any_Dual_Impl_T<CORBA::FloatSeq>::extract (
            _any,
            CORBA::FloatSeq::_tao_any_destructor,
            _tc,
            tmp))
      {
        VALUE ret = (rtcklass == rb_cArray) ?
              rb_ary_new2 ((long)tmp->length ()) :
              rb_class_new_instance (0, 0, rtcklass);
        for (CORBA::ULong l=0; l<tmp->length () ;++l)
        {
          rb_ary_push (ret, rb_float_new ((CORBA::Double)(*tmp)[l]));
        }
        return ret;
      }
      break;
    }
    case CORBA::tk_double:
    {
      const CORBA::DoubleSeq* tmp;
      if (TAO::Any_Dual_Impl_T<CORBA::DoubleSeq>::extract (
            _any,
            CORBA::DoubleSeq::_tao_any_destructor,
            _tc,
            tmp))
      {
        VALUE ret = (rtcklass == rb_cArray) ?
              rb_ary_new2 ((long)tmp->length ()) :
              rb_class_new_instance (0, 0, rtcklass);
        for (CORBA::ULong l=0; l<tmp->length () ;++l)
        {
          rb_ary_push (ret, rb_float_new ((*tmp)[l]));
        }
        return ret;
      }
      break;
    }
    case CORBA::tk_longdouble:
    {
      const CORBA::LongDoubleSeq* tmp;
      if (TAO::Any_Dual_Impl_T<CORBA::LongDoubleSeq>::extract (
            _any,
            CORBA::DoubleSeq::_tao_any_destructor,
            _tc,
            tmp))
      {
        VALUE ret = (rtcklass == rb_cArray) ?
              rb_ary_new2 ((long)tmp->length ()) :
              rb_class_new_instance (0, 0, rtcklass);
        for (CORBA::ULong l=0; l<tmp->length () ;++l)
        {
          rb_ary_push (ret, CLD2RLD ((*tmp)[l]));
        }
        return ret;
      }
      break;
    }
    case CORBA::tk_boolean:
    {
      const CORBA::BooleanSeq* tmp;
      if (TAO::Any_Dual_Impl_T<CORBA::BooleanSeq>::extract (
            _any,
            CORBA::BooleanSeq::_tao_any_destructor,
            _tc,
            tmp))
      {
        VALUE ret = (rtcklass == rb_cArray) ?
              rb_ary_new2 ((long)tmp->length ()) :
              rb_class_new_instance (0, 0, rtcklass);
        for (CORBA::ULong l=0; l<tmp->length () ;++l)
        {
          rb_ary_push (ret, ((*tmp)[l] ? Qtrue : Qfalse));
        }
        return ret;
      }
      break;
    }
    case CORBA::tk_char:
    {
      const CORBA::CharSeq* tmp;
      if (TAO::Any_Dual_Impl_T<CORBA::CharSeq>::extract (
            _any,
            CORBA::CharSeq::_tao_any_destructor,
            _tc,
            tmp))
      {
        return rb_str_new ((char*)tmp->get_buffer (), (long)tmp->length ());
      }
      break;
    }
    case CORBA::tk_octet:
    {
      const CORBA::OctetSeq* tmp;
      if (TAO::Any_Dual_Impl_T<CORBA::OctetSeq>::extract (
            _any,
            CORBA::OctetSeq::_tao_any_destructor,
            _tc,
            tmp))
      {
        return rb_str_new ((char*)tmp->get_buffer (), (long)tmp->length ());
      }
      break;
    }
    case CORBA::tk_wchar:
    {
      const CORBA::WCharSeq* tmp;
      if (TAO::Any_Dual_Impl_T<CORBA::WCharSeq>::extract (
            _any,
            CORBA::WCharSeq::_tao_any_destructor,
            _tc,
            tmp))
      {
        VALUE ret = (rtcklass == rb_cArray) ?
              rb_ary_new2 ((long)tmp->length ()) :
              rb_class_new_instance (0, 0, rtcklass);
        for (CORBA::ULong l=0; l<tmp->length () ;++l)
        {
          rb_ary_push (ret, INT2FIX ((int)(*tmp)[l]));
        }
        return ret;
      }
      break;
    }
    default:
    {
      DynamicAny::DynAny_var da = r2tao_Typecode_CreateDynAny (_orb, _any);
      DynamicAny::DynSequence_var das = DynamicAny::DynSequence::_narrow (da.in ());

      DynamicAny::AnySeq_var elems = das->get_elements ();
      CORBA::ULong seqlen = elems->length ();

      VALUE ret = (rtcklass == rb_cArray) ?
            rb_ary_new2 ((long)seqlen) :
            rb_class_new_instance (0, 0, rtcklass);

      CORBA::TypeCode_var etc = _tc->content_type ();
      VALUE ertc = rb_iv_get (rtc, "@content_tc");
      VALUE is_recursive_tc = rb_funcall (ertc, rb_intern ("is_recursive_tc?"), 0);
      if (is_recursive_tc == Qtrue)
      {
        ertc = rb_funcall (ertc, rb_intern ("recursed_tc"), 0);
      }

      for (CORBA::ULong l=0; l<seqlen ;++l)
      {
        VALUE rval = r2tao_Typecode_Any2Ruby (elems[l], etc.in (), ertc, ertc, _orb);
        rb_ary_push (ret, rval);
      }

      das->destroy ();
      return ret;
    }
  }

  ACE_ERROR ((LM_ERROR, "R2TAO::Cannot convert TAO sequence to Ruby\n"));
  throw ::CORBA::NO_IMPLEMENT (0, CORBA::COMPLETED_NO);

  return Qnil;
}

R2TAO_EXPORT VALUE r2tao_Typecode_Any2Ruby(const CORBA::Any& _any, CORBA::TypeCode_ptr _tc, VALUE rtc, VALUE roottc, CORBA::ORB_ptr _orb)
{
  switch (_tc->kind ())
  {
    case CORBA::tk_null:
    case CORBA::tk_void:
      return Qnil;
    case CORBA::tk_alias:
    {
      VALUE raliased_type = rb_iv_get (rtc, "@aliased_tc");
      CORBA::TypeCode_var ctc = _tc->content_type ();
      return r2tao_Typecode_Any2Ruby(_any, ctc.in (), raliased_type, roottc, _orb);
    }
    case CORBA::tk_short:
    {
      CORBA::Short val;
      _any >>= val;
      return INT2FIX ((int)val);
    }
    case CORBA::tk_long:
    {
      CORBA::Long val;
      _any >>= val;
      return LONG2NUM (val);
    }
    case CORBA::tk_ushort:
    {
      CORBA::UShort val;
      _any >>= val;
      return UINT2NUM ((unsigned int)val);
    }
    case CORBA::tk_ulong:
    {
      CORBA::ULong val;
      _any >>= val;
      return ULONG2NUM (val);
    }
    case CORBA::tk_longlong:
    {
      CORBA::LongLong val;
      _any >>= val;
      return LL2NUM (val);
    }
    case CORBA::tk_ulonglong:
    {
      CORBA::ULongLong val;
      _any >>= val;
      return ULL2NUM (val);
    }
    case CORBA::tk_float:
    {
      CORBA::Float val;
      _any >>= val;
      return rb_float_new ((double)val);
    }
    case CORBA::tk_double:
    {
      CORBA::Double val;
      _any >>= val;
      return rb_float_new ((double)val);
    }
    case CORBA::tk_longdouble:
    {
      CORBA::LongDouble val;
      _any >>= val;
      return CLD2RLD (val);
    }
    case CORBA::tk_boolean:
    {
      CORBA::Boolean val;
      _any >>= CORBA::Any::to_boolean (val);
      return (val ? Qtrue : Qfalse);
    }
    case CORBA::tk_char:
    {
      CORBA::Char val;
      _any >>= CORBA::Any::to_char (val);
      return rb_str_new (&val, 1);
    }
    case CORBA::tk_octet:
    {
      CORBA::Octet val;
      _any >>= CORBA::Any::to_octet (val);
      return INT2FIX ((int)val);
    }
    case CORBA::tk_wchar:
    {
      CORBA::WChar val;
      _any >>= CORBA::Any::to_wchar (val);
      return INT2FIX ((int)val);
    }
    case CORBA::tk_string:
    {
      if (_tc->length ()>0)
      {
        char *tmp;
        _any >>= CORBA::Any::to_string (tmp, _tc->length ());
        return rb_str_new (tmp, (long)_tc->length ());
      }
      else
      {
        const char *tmp;
        _any >>= tmp;
        return tmp ? rb_str_new2 (tmp) : Qnil;
      }
    }
    case CORBA::tk_wstring:
    {
      VALUE rtcklass = R2TAO_TCTYPE(roottc);
      if (_tc->length ()>0)
      {
        CORBA::WChar *tmp;
        _any >>= CORBA::Any::to_wstring (tmp, _tc->length ());
        VALUE ret = (rtcklass == rb_cArray) ?
              rb_ary_new2 ((long)_tc->length ()) :
              rb_class_new_instance (0, 0, rtcklass);
        for (CORBA::ULong l=0; l<_tc->length () ;++l)
          rb_ary_push (ret, INT2FIX (tmp[l]));
        return ret;
      }
      else
      {
        const CORBA::WChar *tmp;
        _any >>= tmp;
        if (tmp == 0)
          return Qnil;
        
        VALUE ret = rb_class_new_instance (0, 0, rtcklass);
        for (CORBA::ULong l=0; tmp[l] != CORBA::WChar(0) ;++l)
          rb_ary_push (ret, INT2FIX (tmp[l]));
        return ret;
      }
    }
    case CORBA::tk_enum:
    {
      DynamicAny::DynAny_var da = r2tao_Typecode_CreateDynAny (_orb, _any);
      DynamicAny::DynEnum_var das = DynamicAny::DynEnum::_narrow (da.in ());

      VALUE ret = ULL2NUM (das->get_as_ulong ());

      das->destroy ();
      return ret;
    }
    case CORBA::tk_array:
    {
      DynamicAny::DynAny_var da = r2tao_Typecode_CreateDynAny (_orb, _any);
      DynamicAny::DynArray_var das = DynamicAny::DynArray::_narrow (da.in ());

      DynamicAny::AnySeq_var elems = das->get_elements ();
      CORBA::ULong arrlen = elems->length ();

      VALUE rtcklass = R2TAO_TCTYPE(roottc);
      VALUE ret = (rtcklass == rb_cArray) ?
            rb_ary_new2 ((long)arrlen) :
            rb_class_new_instance (0, 0, rtcklass);

      CORBA::TypeCode_var etc = _tc->content_type ();
      VALUE ertc = rb_iv_get (rtc, "@content_tc");

      for (CORBA::ULong l=0; l<arrlen ;++l)
      {
        VALUE rval = r2tao_Typecode_Any2Ruby (elems[l], etc.in (), ertc, ertc, _orb);
        rb_ary_push (ret, rval);
      }

      das->destroy ();
      return ret;
    }
    case CORBA::tk_sequence:
    {
      return r2tao_Typecode_Sequence2Ruby (_any, _tc, rtc, roottc, _orb);
    }
    case CORBA::tk_except:
    case CORBA::tk_struct:
    {
      return r2tao_Typecode_Struct2Ruby (_any, _tc, rtc, roottc, _orb);
    }
    case CORBA::tk_union:
    {
      return r2tao_Typecode_Union2Ruby (_any, _tc, rtc, roottc, _orb);
    }
    case CORBA::tk_objref:
    {
      CORBA::Object_var val;
      _any >>= CORBA::Any::to_object (val.out ());
      if (CORBA::is_nil (val))
        return Qnil;

      VALUE robj = r2tao_Object_t2r(val.in ());
      VALUE obj_type = rb_funcall (rtc, rb_intern ("get_type"), 0);
      VALUE ret = rb_funcall (obj_type, rb_intern ("_narrow"), 1, robj);
      return ret;
    }
    case CORBA::tk_any:
    {
      const CORBA::Any *_anyval;
      _any >>= _anyval;
      CORBA::TypeCode_var atc = _anyval->type ();
      rtc = r2tao_Typecode_t2r(atc.in (), _orb);
      return r2tao_Typecode_Any2Ruby (*_anyval, atc.in (), rtc, rtc, _orb);
    }
    case CORBA::tk_TypeCode:
    {
      CORBA::TypeCode_ptr _tcval;
      _any >>= _tcval;

      return r2tao_Typecode_t2r(_tcval, _orb);
    }
    case CORBA::tk_Principal:
    {
      break;
    }
    default:
      break;
  }

  ACE_ERROR ((LM_ERROR, "R2TAO::Cannot convert TAO data to Ruby\n"));
  throw ::CORBA::NO_IMPLEMENT (0, CORBA::COMPLETED_NO);

  return Qnil;
}

