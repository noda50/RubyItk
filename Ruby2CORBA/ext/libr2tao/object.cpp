/*--------------------------------------------------------------------
# object.cpp - R2TAO CORBA Object support
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
#include "tao/DynamicInterface/Request.h"
#include "tao/DynamicInterface/DII_CORBA_methods.h"
#include "tao/DynamicInterface/Unknown_User_Exception.h"
#include "typecode.h"
#include "object.h"
#include "exception.h"
#include "orb.h"

R2TAO_EXPORT VALUE r2tao_cObject = 0;
VALUE r2tao_cStub;
VALUE r2tao_cRequest;

VALUE r2tao_Object_orb(VALUE self);
VALUE r2tao_Object_object_id(VALUE self);

static int r2tao_IN_ARG;
static int r2tao_INOUT_ARG;
static int r2tao_OUT_ARG;

static VALUE ID_arg_list;
static VALUE ID_result_type;
static VALUE ID_exc_list;

VALUE rCORBA_Object_narrow(VALUE self, VALUE obj);

VALUE rCORBA_Object_is_a(VALUE self, VALUE type_id);
VALUE rCORBA_Object_get_interface(VALUE self);
VALUE rCORBA_Object_is_nil(VALUE self);
VALUE rCORBA_Object_free_ref(VALUE self);
VALUE rCORBA_Object_duplicate(VALUE self);
VALUE rCORBA_Object_release(VALUE self);
VALUE rCORBA_Object_non_existent(VALUE self);
VALUE rCORBA_Object_is_equivalent(VALUE self, VALUE other);
VALUE rCORBA_Object_hash(VALUE self, VALUE max);
VALUE rCORBA_Object_get_policy(VALUE self, VALUE policy_type);
VALUE rCORBA_Object_repository_id(VALUE self);
VALUE rCORBA_Object_interface_repository_id(VALUE self);
VALUE rCORBA_Object_release(VALUE self);

VALUE ri_CORBA_Object_equal(VALUE self, VALUE that);
VALUE ri_CORBA_Object_hash(VALUE self);

VALUE rCORBA_Object_request(VALUE self, VALUE op);

VALUE rCORBA_Stub_invoke(int _argc, VALUE *_argv, VALUE self);

VALUE rCORBA_Request_target(VALUE self);
VALUE rCORBA_Request_operation(VALUE self);
VALUE rCORBA_Request_arguments(VALUE self);
VALUE rCORBA_Request_set_arguments(VALUE self, VALUE arg_list);
VALUE rCORBA_Request_exceptions(VALUE self);
VALUE rCORBA_Request_set_exceptions(VALUE self, VALUE exc_list);
VALUE rCORBA_Request_add_in_arg(int _argc, VALUE *_argv, VALUE self);
VALUE rCORBA_Request_add_out_arg(int _argc, VALUE *_argv, VALUE self);
VALUE rCORBA_Request_add_inout_arg(int _argc, VALUE *_argv, VALUE self);
VALUE rCORBA_Request_set_return_type(VALUE self, VALUE ret_tc);
VALUE rCORBA_Request_return_value(VALUE self);
VALUE rCORBA_Request_invoke(int _argc, VALUE *_argv, VALUE self);
VALUE rCORBA_Request_send_oneway(int _argc, VALUE *_argv, VALUE self);
VALUE rCORBA_Request_send_deferred(VALUE self);
VALUE rCORBA_Request_get_response(VALUE self);
VALUE rCORBA_Request_poll_response(VALUE self);

static void _object_free(void *ptr);

void
r2tao_Init_Object()
{
  VALUE klass;
  VALUE nsCORBA_Object;

  if (r2tao_cObject) return;

  ID_arg_list = rb_eval_string (":arg_list");
  ID_result_type = rb_eval_string (":result_type");
  ID_exc_list = rb_eval_string (":exc_list");

  nsCORBA_Object = rb_eval_string("::R2CORBA::CORBA::Portable::Object");
  klass = r2tao_cObject =
    rb_define_class_under(r2tao_nsCORBA, "Object", rb_cObject);
  rb_include_module (r2tao_cObject, nsCORBA_Object);

  rb_define_singleton_method(klass, "_narrow", RUBY_METHOD_FUNC(rCORBA_Object_narrow), 1);

  rb_define_method(klass, "_is_a?", RUBY_METHOD_FUNC(rCORBA_Object_is_a), 1);
  rb_define_method(klass, "_get_interface", RUBY_METHOD_FUNC(rCORBA_Object_get_interface), 0);
  rb_define_method(klass, "_repository_id", RUBY_METHOD_FUNC(rCORBA_Object_repository_id), 0);
  rb_define_method(klass, "_interface_repository_id", RUBY_METHOD_FUNC(rCORBA_Object_interface_repository_id), 0);
  rb_define_method(klass, "_is_nil?", RUBY_METHOD_FUNC(rCORBA_Object_is_nil), 0);
  rb_define_method(klass, "_free_ref", RUBY_METHOD_FUNC(rCORBA_Object_free_ref), 0);
  rb_define_method(klass, "_duplicate", RUBY_METHOD_FUNC(rCORBA_Object_duplicate), 0);
  rb_define_method(klass, "_release", RUBY_METHOD_FUNC(rCORBA_Object_release), 0);
  rb_define_method(klass, "_non_existent?", RUBY_METHOD_FUNC(rCORBA_Object_non_existent), 0);
  rb_define_method(klass, "_is_equivalent?", RUBY_METHOD_FUNC(rCORBA_Object_is_equivalent), 1);
  rb_define_method(klass, "_hash", RUBY_METHOD_FUNC(rCORBA_Object_hash), 1);
  rb_define_method(klass, "_get_policy", RUBY_METHOD_FUNC(rCORBA_Object_get_policy), 1);
  rb_define_method(klass, "_get_orb", RUBY_METHOD_FUNC(r2tao_Object_orb), 0);
  rb_define_method(klass, "_request", RUBY_METHOD_FUNC(rCORBA_Object_request), 1);

  rb_define_method(klass, "_equal?", RUBY_METHOD_FUNC(ri_CORBA_Object_equal), 1);

  rb_define_method(klass, "==", RUBY_METHOD_FUNC(rCORBA_Object_is_equivalent), 1);
  rb_define_method(klass, "eql?", RUBY_METHOD_FUNC(ri_CORBA_Object_equal), 1);
  rb_define_method(klass, "hash", RUBY_METHOD_FUNC(ri_CORBA_Object_hash), 0);
  rb_define_method(klass, "dup", RUBY_METHOD_FUNC(rCORBA_Object_duplicate), 0);
  rb_define_method(klass, "clone", RUBY_METHOD_FUNC(rCORBA_Object_duplicate), 0);

  // CORBA::Stub

  klass = r2tao_cStub = rb_define_module_under(r2tao_nsCORBA, "Stub");
  // R2TAO::CORBA::Stub._invoke(opname, arg_list, result_type = nil)
  // . arg_list = Array of Array-s containing name, argtype, tc [, value] for each arg
  // . result_type = typecode; if result_type == nil => oneway call
  // -> returns [ <return value>, <out arg1>, ..., <out argn> ] or nil (oneway) or throws exception
  rb_define_protected_method(klass, "_invoke", RUBY_METHOD_FUNC(rCORBA_Stub_invoke), -1);

  r2tao_IN_ARG = NUM2INT (rb_eval_string ("R2CORBA::CORBA::ARG_IN"));
  r2tao_INOUT_ARG = NUM2INT (rb_eval_string ("R2CORBA::CORBA::ARG_INOUT"));
  r2tao_OUT_ARG = NUM2INT (rb_eval_string ("R2CORBA::CORBA::ARG_OUT"));

  // CORBA::Request
  klass = r2tao_cRequest = rb_define_class_under(r2tao_nsCORBA, "Request", rb_cObject);

  rb_define_method(klass, "target", RUBY_METHOD_FUNC(rCORBA_Request_target), 0);
  rb_define_method(klass, "operation", RUBY_METHOD_FUNC(rCORBA_Request_operation), 0);
  rb_define_method(klass, "arguments", RUBY_METHOD_FUNC(rCORBA_Request_arguments), 0);
  rb_define_method(klass, "arguments=", RUBY_METHOD_FUNC(rCORBA_Request_set_arguments), 1);
  rb_define_method(klass, "exceptions", RUBY_METHOD_FUNC(rCORBA_Request_exceptions), 0);
  rb_define_method(klass, "exceptions=", RUBY_METHOD_FUNC(rCORBA_Request_set_exceptions), 1);
  rb_define_method(klass, "add_in_arg", RUBY_METHOD_FUNC(rCORBA_Request_add_in_arg), -1);
  rb_define_method(klass, "add_out_arg", RUBY_METHOD_FUNC(rCORBA_Request_add_out_arg), -1);
  rb_define_method(klass, "add_inout_arg", RUBY_METHOD_FUNC(rCORBA_Request_add_inout_arg), -1);
  rb_define_method(klass, "set_return_type", RUBY_METHOD_FUNC(rCORBA_Request_set_return_type), 1);
  rb_define_method(klass, "return_value", RUBY_METHOD_FUNC(rCORBA_Request_return_value), 0);

  // R2TAO::CORBA::Request.invoke({:arg_list=>[], :result_type=>, :exc_list=>[]})
  // . arg_list = Array of Array-s containing name, argtype, tc [, value] for each arg
  // . result_type = typecode; if result_type == nil => oneway call
  // -> returns [ <return value>, <out arg1>, ..., <out argn> ] or nil (oneway) or throws exception
  rb_define_method(klass, "invoke", RUBY_METHOD_FUNC(rCORBA_Request_invoke), -1);
  rb_define_method(klass, "send_oneway", RUBY_METHOD_FUNC(rCORBA_Request_send_oneway), -1);
  rb_define_method(klass, "send_deferred", RUBY_METHOD_FUNC(rCORBA_Request_send_deferred), 0);
  rb_define_method(klass, "get_response", RUBY_METHOD_FUNC(rCORBA_Request_get_response), 0);
  rb_define_method(klass, "poll_response", RUBY_METHOD_FUNC(rCORBA_Request_poll_response), 0);
}

//-------------------------------------------------------------------
//  Ruby <-> TAO object conversions
//
//===================================================================

VALUE
r2tao_t2r(VALUE klass, CORBA::Object_ptr obj)
{
  VALUE ret;
  CORBA::Object_ptr o;

  o = CORBA::Object::_duplicate (obj);
  ret = Data_Wrap_Struct(klass, 0, _object_free, o);

  return ret;
}

R2TAO_EXPORT VALUE
r2tao_Object_t2r(CORBA::Object_ptr obj)
{
  return r2tao_t2r (r2tao_cObject, obj);
}

R2TAO_EXPORT CORBA::Object_ptr
r2tao_Object_r2t(VALUE obj)
{
  CORBA::Object_ptr ret;

  r2tao_check_type (obj, r2tao_cObject);
  Data_Get_Struct(obj, CORBA::Object, ret);
  return ret;
}

static void
_object_free(void *ptr)
{
  CORBA::release (static_cast<CORBA::Object_ptr> (ptr));
}


static void
_request_free(void *ptr)
{
  CORBA::release (static_cast<CORBA::Request_ptr> (ptr));
}

VALUE
r2tao_Request_t2r(CORBA::Request_ptr req)
{
  VALUE ret;
  CORBA::Request_ptr o;

  o = CORBA::Request::_duplicate (req);
  ret = Data_Wrap_Struct(r2tao_cRequest, 0, _request_free, o);

  return ret;
}

CORBA::Request_ptr
r2tao_Request_r2t(VALUE obj)
{
  CORBA::Request_ptr ret;

  r2tao_check_type(obj, r2tao_cRequest);
  Data_Get_Struct(obj, CORBA::Request, ret);
  return ret;
}

//-------------------------------------------------------------------
//  CORBA::Object methods
//
//===================================================================
// class method
VALUE
rCORBA_Object_narrow(VALUE /*self*/, VALUE obj)
{
  return obj;
}

VALUE
r2tao_Object_orb(VALUE self)
{
  return r2tao_ORB_t2r(r2tao_Object_r2t(self)->_get_orb ());
}

VALUE
rCORBA_Object_get_interface(VALUE /*self*/)
{
  X_CORBA(NO_IMPLEMENT);
  return Qnil;
}

VALUE
rCORBA_Object_repository_id(VALUE self)
{
  VALUE ret = Qnil;

  CORBA::Object_ptr obj = r2tao_Object_r2t (self);

  R2TAO_TRY
  {
    ret = rb_str_new2 (obj->_repository_id ());
  }
  R2TAO_CATCH;

  return ret;
}

VALUE
rCORBA_Object_interface_repository_id(VALUE self)
{
  VALUE ret = Qnil;

  CORBA::Object_ptr obj = r2tao_Object_r2t (self);

  R2TAO_TRY
  {
    ret = rb_str_new2 (obj->_interface_repository_id ());
  }
  R2TAO_CATCH;

  return ret;
}

VALUE
rCORBA_Object_is_nil(VALUE self)
{
  VALUE ret = Qnil;

  CORBA::Object_ptr obj = r2tao_Object_r2t (self);

  R2TAO_TRY
  {
    ret = CORBA::is_nil (obj) ? Qtrue: Qfalse;
  }
  R2TAO_CATCH;

  return ret;
}

VALUE
rCORBA_Object_free_ref(VALUE self)
{
  CORBA::Object_ptr obj = r2tao_Object_r2t (self);

  R2TAO_TRY
  {
    if (!CORBA::is_nil (obj))
    {
      _object_free (DATA_PTR (self));
      DATA_PTR (self) = CORBA::Object::_nil ();
    }
  }
  R2TAO_CATCH;

  return self;
}

VALUE
rCORBA_Object_duplicate(VALUE self)
{
  VALUE ret = Qnil;

  R2TAO_TRY
  {
    ret = r2tao_Object_t2r (r2tao_Object_r2t (self));
  }
  R2TAO_CATCH;

  return ret;
}

VALUE
rCORBA_Object_release(VALUE /*self*/)
{
/*  DO NOTHING
*/
  return Qnil;
}

VALUE
rCORBA_Object_non_existent(VALUE self)
{
  VALUE ret = Qnil;

  R2TAO_TRY
  {
    ret = r2tao_Object_r2t (self)->_non_existent () ? Qtrue: Qfalse;
  }
  R2TAO_CATCH;

  return ret;
}

VALUE
rCORBA_Object_is_equivalent(VALUE self, VALUE _other)
{
  CORBA::Object_ptr other, obj;
  VALUE ret = Qnil;

  obj = r2tao_Object_r2t (self);
  other = r2tao_Object_r2t (_other);

  R2TAO_TRY
  {
    ret = obj->_is_equivalent (other)? Qtrue: Qfalse;
  }
  R2TAO_CATCH;

  return ret;
}

VALUE
rCORBA_Object_hash(VALUE self, VALUE _max)
{
  CORBA::ULong ret=0, max;
  CORBA::Object_ptr obj = r2tao_Object_r2t (self);

  max = NUM2ULONG(_max);
  R2TAO_TRY
  {
    ret = obj->_hash(max);
  }
  R2TAO_CATCH;

  return ULONG2NUM(ret);
}

VALUE
rCORBA_Object_get_policy(VALUE /*self*/, VALUE /*policy_type*/)
{
  /* TODO */
  X_CORBA(NO_IMPLEMENT);
  return Qnil;
}

VALUE
ri_CORBA_Object_equal(VALUE self, VALUE that)
{
  CORBA::Object_ptr obj1, obj2;

  r2tao_check_type(that, r2tao_cObject);

  Data_Get_Struct(self, CORBA::Object, obj1);
  Data_Get_Struct(self, CORBA::Object, obj2);
  return (obj1 == obj2) ? Qtrue : Qfalse;
}

VALUE
ri_CORBA_Object_hash(VALUE self)
{
  return ULONG2NUM ((CORBA::ULong)reinterpret_cast<unsigned long> (r2tao_Object_r2t (self)));
}

VALUE
rCORBA_Object_is_a(VALUE self, VALUE type_id)
{
  CORBA::Object_ptr obj;
  VALUE ret = Qnil;

  obj = r2tao_Object_r2t (self);
  Check_Type(type_id, T_STRING);

  R2TAO_TRY
  {
    int f = obj->_is_a (RSTRING(type_id)->ptr);
    //::printf ("rCORBA_Object_is_a: %s -> %d\n", RSTRING(type_id)->ptr, f);
    ret = f ? Qtrue: Qfalse;
  }
  R2TAO_CATCH;

  return ret;
}

//-------------------------------------------------------------------
//  CORBA::Stub methods
//
//===================================================================

VALUE
rCORBA_Object_request(VALUE self, VALUE op_name)
{
  CORBA::Object_ptr obj;
  CORBA::Request_var req;

  obj = r2tao_Object_r2t (self);
  Check_Type(op_name, T_STRING);

  R2TAO_TRY
  {
    req = obj->_request (RSTRING(op_name)->ptr);
  }
  R2TAO_CATCH;

  return r2tao_Request_t2r (req.in ());
}

//-------------------------------------------------------------------
//  CORBA::Request methods
//
//===================================================================

static VALUE _r2tao_set_request_arguments(CORBA::Request_ptr _req, VALUE arg_list)
{
  long ret_val = 0;
  CORBA::ORB_var _orb = _req->target ()->_get_orb ();

  // clear all current args
  CORBA::ULong arg_num = _req->arguments ()->count ();
  while (arg_num > 0)
    _req->arguments ()->remove (--arg_num);

  if (arg_list != Qnil)
  {
    long arg_len = RARRAY (arg_list)->len;
    for (long a=0; a<arg_len ;++a)
    {
      VALUE argspec = rb_ary_entry (arg_list, a);
      VALUE argname = rb_ary_entry (argspec, 0);
      int _arg_type = NUM2INT (rb_ary_entry (argspec, 1));
      CORBA::TypeCode_var _arg_tc = r2tao_Typecode_r2t (rb_ary_entry (argspec, 2), _orb. in());

      //::printf("arg_name=%s; arg_type=%d\n", _arg_name, _arg_type);

      if (_arg_type != r2tao_OUT_ARG)
      {
        VALUE arg_val = rb_ary_entry (argspec, 3);

        char *_arg_name = argname != Qnil ? RSTRING (argname)->ptr : 0;
        CORBA::Any& _arg = (_arg_type == r2tao_IN_ARG) ?
            (_arg_name ? _req->add_in_arg (_arg_name) : _req->add_in_arg ()) :
            (_arg_name ? _req->add_inout_arg (_arg_name) : _req->add_inout_arg ());

        if (_arg_type == r2tao_INOUT_ARG)
          ++ret_val;

        // assign value to Any
        r2tao_Typecode_Ruby2Any(_arg, _arg_tc.in (), arg_val, _orb.in ());
      }
      else
      {
        ++ret_val;
        char *_arg_name = argname != Qnil ? RSTRING (argname)->ptr : 0;
        CORBA::Any& _arg = _arg_name ?
            _req->add_out_arg (_arg_name) : _req->add_out_arg ();

        // assign type info to Any
        r2tao_Typecode_Ruby2Any(_arg, _arg_tc.in (), Qnil, _orb.in ());
      }
    }
  }
  return LONG2NUM (ret_val);
}

static VALUE _r2tao_set_request_exceptions(CORBA::Request_ptr _req, VALUE exc_list)
{
  long exc_len = 0;
  CORBA::ORB_var _orb = _req->target ()->_get_orb ();

  // clear all current excepts
  CORBA::ULong x_num = _req->exceptions ()->count ();
  while (x_num > 0)
    _req->exceptions ()->remove (--x_num);

  if (exc_list != Qnil)
  {
    exc_len = RARRAY (exc_list)->len;
    for (long x=0; x<exc_len ;++x)
    {
      VALUE exctc = rb_ary_entry (exc_list, x);
      CORBA::TypeCode_var _xtc = r2tao_Typecode_r2t (exctc, _orb.in ());
      _req->exceptions ()->add (_xtc.in ());
    }
  }
  return LONG2NUM (exc_len);
}

static VALUE _r2tao_set_request_return_type(CORBA::Request_ptr _req, VALUE ret_rtc)
{
  CORBA::ORB_var _orb = _req->target ()->_get_orb ();

  CORBA::TypeCode_var _ret_tc = r2tao_Typecode_r2t (ret_rtc, _orb. in());
  _req->set_return_type (_ret_tc.in ());
  return Qtrue;
}

static VALUE _r2tao_invoke_request(CORBA::Request_ptr _req, bool& _raise)
{
  CORBA::ULong ret_num = 0;
  // get the ORB we're using for the request
  CORBA::ORB_var _orb  = _req->target ()->_get_orb ();

  CORBA::TypeCode_var _ret_tc = _req->return_value ().type ();
  // invoke twoway if resulttype specified (could be void!)
  if (_ret_tc->kind () != CORBA::tk_null)
  {
    if (_ret_tc->kind () != CORBA::tk_void)
      ++ret_num;

    CORBA::ULong arg_num = _req->arguments ()->count ();
    for (CORBA::ULong a=0; a<arg_num ;++a)
    {
      CORBA::NamedValue_ptr _arg = _req->arguments ()->item (a);
      if (ACE_BIT_DISABLED (_arg->flags (), CORBA::ARG_IN))
        ++ret_num;
    }

    // invoke request
    try
    {
      _req->invoke ();
    }
    catch (CORBA::UnknownUserException& user_ex)
    {
      CORBA::Any& _excany = user_ex.exception ();

      CORBA::ULong exc_len = _req->exceptions ()->count ();
      for (CORBA::ULong x=0; x<exc_len ;++x)
      {
        CORBA::TypeCode_var _xtc = _req->exceptions ()->item (x);
        if (ACE_OS::strcmp (_xtc->id (),
                            _excany._tao_get_typecode ()->id ()) == 0)
        {
          VALUE x_rtc = r2tao_Typecode_t2r(_xtc.in (), _orb.in ());
          VALUE rexc = r2tao_Typecode_Any2Ruby (_excany,
                                                _xtc.in (),
                                                x_rtc, x_rtc,
                                                _orb.in ());
          _raise = true;
          return rexc;
        }
      }

      // rethrow if we were not able to identify the exception
      // will be caught and handled in outer exception handler
      throw;
    }

    // handle result and OUT arguments
    VALUE result = (ret_num>1 ? rb_ary_new () : Qnil);

    if (_ret_tc->kind () != CORBA::tk_void)
    {
      CORBA::Any& retval = _req->return_value ();
      VALUE result_type = r2tao_Typecode_t2r(_ret_tc.in (), _orb.in ());
      // return value
      if (ret_num>1)
        rb_ary_push (result, r2tao_Typecode_Any2Ruby (retval, _ret_tc.in (), result_type, result_type, _orb.in ()));
      else
        result = r2tao_Typecode_Any2Ruby (retval, _ret_tc.in (), result_type, result_type, _orb.in ());

      --ret_num; // return value handled
    }

    // (in)out args
    if (ret_num > 0)
    {
      for (CORBA::ULong a=0; a<arg_num ;++a)
      {
        CORBA::NamedValue_ptr _arg = _req->arguments ()->item (a);
        if (ACE_BIT_DISABLED (_arg->flags (), CORBA::ARG_IN))
        {
          CORBA::TypeCode_var _arg_tc = _arg->value ()->type ();
          VALUE arg_rtc = r2tao_Typecode_t2r(_arg_tc.in (), _orb.in ());
          if (result != Qnil)
            rb_ary_push (result, r2tao_Typecode_Any2Ruby (*_arg->value (), _arg_tc.in (), arg_rtc, arg_rtc, _orb.in ()));
          else
            result = r2tao_Typecode_Any2Ruby (*_arg->value (), _arg_tc.in (), arg_rtc, arg_rtc, _orb.in ());
        }
      }
    }

    return result;
  }
  else  // invoke oneway
  {
    // oneway
    _req->send_oneway ();

    return Qtrue;
  }
}

VALUE rCORBA_Stub_invoke(int _argc, VALUE *_argv, VALUE self)
{
  // since rb_exc_raise () does not return and does *not* honour
  // C++ exception rules we invoke from an inner function and
  // only raise the user exception when returned so all stack
  // unwinding has been correctly handled.
  VALUE ret=Qnil;
  bool _raise = false;
  CORBA::Object_ptr obj;
  VALUE opname = Qnil;
  VALUE arg_list = Qnil;
  VALUE result_type = Qnil;
  VALUE exc_list = Qnil;
  VALUE v1=Qnil;

  // extract and check arguments
  rb_scan_args(_argc, _argv, "20", &opname, &v1);
  Check_Type (v1, T_HASH);

  arg_list = rb_hash_aref (v1, ID_arg_list);
  result_type = rb_hash_aref (v1, ID_result_type);
  exc_list = rb_hash_aref (v1, ID_exc_list);

  Check_Type(opname, T_STRING);
  if (arg_list != Qnil)
    Check_Type (arg_list, T_ARRAY);
  if (result_type != Qnil)
    r2tao_check_type(result_type, r2tao_cTypecode);
  if (exc_list != Qnil)
    Check_Type (exc_list, T_ARRAY);

  obj = r2tao_Object_r2t (self);

  R2TAO_TRY
  {
    CORBA::Request_var _req = obj->_request (RSTRING(opname)->ptr);

    if (arg_list != Qnil)
      _r2tao_set_request_arguments(_req.in (), arg_list);
    if (exc_list != Qnil)
      _r2tao_set_request_exceptions(_req.in (), exc_list);
    if (result_type != Qnil)
      _r2tao_set_request_return_type(_req.in (), result_type);

    ret = _r2tao_invoke_request(_req.in (), _raise);
  }
  R2TAO_CATCH;
  if (_raise) rb_exc_raise (ret);
  return ret;
}

VALUE rCORBA_Request_invoke(int _argc, VALUE *_argv, VALUE self)
{
  // since rb_exc_raise () does not return and does *not* honour
  // C++ exception rules we invoke from an inner function and
  // only raise the user exception when returned so all stack
  // unwinding has been correctly handled.
  VALUE ret=Qnil;
  bool _raise = false;
  VALUE arg_list = Qnil;
  VALUE result_type = Qnil;
  VALUE exc_list = Qnil;
  VALUE v1=Qnil;

  // extract and check arguments
  rb_scan_args(_argc, _argv, "01", &v1);
  if (v1 != Qnil)
  {
    Check_Type (v1, T_HASH);
    arg_list = rb_hash_aref (v1, ID_arg_list);
    result_type = rb_hash_aref (v1, ID_result_type);
    exc_list = rb_hash_aref (v1, ID_exc_list);
  }

  if (arg_list != Qnil)
    Check_Type (arg_list, T_ARRAY);
  if (result_type != Qnil)
    r2tao_check_type(result_type, r2tao_cTypecode);
  if (exc_list != Qnil)
    Check_Type (exc_list, T_ARRAY);

  CORBA::Request_ptr _req =  r2tao_Request_r2t(self);

  R2TAO_TRY
  {
    if (arg_list != Qnil)
      _r2tao_set_request_arguments(_req, arg_list);
    if (exc_list != Qnil)
      _r2tao_set_request_exceptions(_req, exc_list);
    if (result_type != Qnil)
      _r2tao_set_request_return_type(_req, result_type);

    ret = _r2tao_invoke_request(_req, _raise);
  }
  R2TAO_CATCH;

  if (_raise) rb_exc_raise (ret);
  return ret;
}

VALUE rCORBA_Request_send_oneway(int _argc, VALUE *_argv, VALUE self)
{
  VALUE arg_list = Qnil;
  // extract and check arguments
  rb_scan_args(_argc, _argv, "01", &arg_list);
  if (arg_list != Qnil)
  {
    Check_Type (arg_list, T_ARRAY);
  }
  CORBA::Request_ptr _req =  r2tao_Request_r2t(self);

  R2TAO_TRY
  {
    if (arg_list != Qnil)
      _r2tao_set_request_arguments(_req, arg_list);

    _req->send_oneway ();
  }
  R2TAO_CATCH;

  return Qtrue;
}

VALUE rCORBA_Request_send_deferred(VALUE self)
{
  CORBA::Request_ptr _req =  r2tao_Request_r2t(self);

  R2TAO_TRY
  {
    _req->send_deferred ();
  }
  R2TAO_CATCH;

  return Qtrue;
}

VALUE rCORBA_Request_get_response(VALUE self)
{
  CORBA::Request_ptr _req =  r2tao_Request_r2t(self);

  R2TAO_TRY
  {
    _req->get_response ();
  }
  R2TAO_CATCH;

  return Qtrue;
}

VALUE rCORBA_Request_poll_response(VALUE self)
{
  CORBA::Request_ptr _req =  r2tao_Request_r2t(self);

  VALUE ret=Qnil;
  R2TAO_TRY
  {
    ret = _req->poll_response () ? Qtrue : Qfalse;
  }
  R2TAO_CATCH;

  return ret;
}

VALUE rCORBA_Request_target(VALUE self)
{
  CORBA::Request_ptr _req =  r2tao_Request_r2t(self);
  R2TAO_TRY
  {
    CORBA::Object_var obj = _req->target ();
    return r2tao_Object_t2r (obj.in ());
  }
  R2TAO_CATCH;
  return Qnil;
}

VALUE rCORBA_Request_operation(VALUE self)
{
  CORBA::Request_ptr _req =  r2tao_Request_r2t(self);
  R2TAO_TRY
  {
    return rb_str_new2 (_req->operation ());
  }
  R2TAO_CATCH;
  return Qnil;
}

VALUE rCORBA_Request_arguments(VALUE self)
{
  CORBA::Request_ptr _req =  r2tao_Request_r2t(self);
  R2TAO_TRY
  {
    CORBA::ULong arg_len = _req->arguments ()->count ();
    VALUE rargs = rb_ary_new ();
    for (CORBA::ULong a=0; a<arg_len ;++a)
    {
      VALUE rarg = rb_ary_new ();
      CORBA::NamedValue_ptr arg = _req->arguments ()->item (a);

      rb_ary_push (rarg, rb_str_new2 (arg->name ()));
      if (ACE_BIT_ENABLED (arg->flags (), CORBA::ARG_IN))
        rb_ary_push (rarg, ULONG2NUM (r2tao_IN_ARG));
      else if (ACE_BIT_ENABLED (arg->flags (), CORBA::ARG_OUT))
        rb_ary_push (rarg, ULONG2NUM (r2tao_OUT_ARG));
      else if (ACE_BIT_ENABLED (arg->flags (), CORBA::ARG_INOUT))
        rb_ary_push (rarg, ULONG2NUM (r2tao_INOUT_ARG));
      CORBA::TypeCode_var atc = arg->value ()->type ();
      VALUE arg_rtc = r2tao_Typecode_t2r(atc.in (), _req->target ()->_get_orb ());
      rb_ary_push (rarg, arg_rtc);
      VALUE arg_val = r2tao_Typecode_Any2Ruby (*arg->value (), atc.in (),
                                                arg_rtc, arg_rtc,
                                                _req->target ()->_get_orb ());
      rb_ary_push (rarg, arg_val);
      rb_ary_push (rargs, rarg);
    }
    return rargs;
  }
  R2TAO_CATCH;
  return Qnil;
}

VALUE rCORBA_Request_set_arguments(VALUE self, VALUE arg_list)
{
  CORBA::Request_ptr _req =  r2tao_Request_r2t(self);
  if (arg_list != Qnil)
    Check_Type (arg_list, T_ARRAY);

  R2TAO_TRY
  {
    return _r2tao_set_request_arguments(_req, arg_list);
  }
  R2TAO_CATCH;
  return Qnil;
}

VALUE rCORBA_Request_exceptions(VALUE self)
{
  CORBA::Request_ptr _req =  r2tao_Request_r2t(self);
  R2TAO_TRY
  {
    CORBA::ORB_var _orb = _req->target ()->_get_orb ();

    CORBA::ULong exc_len = _req->exceptions ()->count ();
    VALUE rexc = rb_ary_new ();
    for (CORBA::ULong x=0; x<exc_len ;++x)
    {
      CORBA::TypeCode_var xtc = _req->exceptions ()->item (x);
      VALUE x_rtc = r2tao_Typecode_t2r(xtc.in (), _orb.in ());
      rb_ary_push (rexc, x_rtc);
    }
    return rexc;
  }
  R2TAO_CATCH;
  return Qnil;
}

VALUE rCORBA_Request_set_exceptions(VALUE self, VALUE exc_list)
{
  CORBA::Request_ptr _req =  r2tao_Request_r2t(self);
  R2TAO_TRY
  {
    return _r2tao_set_request_exceptions(_req, exc_list);
  }
  R2TAO_CATCH;
  return Qnil;
}

VALUE rCORBA_Request_add_in_arg(int _argc, VALUE *_argv, VALUE self)
{
  VALUE arg_name = Qnil;
  VALUE arg_rtc = Qnil;
  VALUE arg_rval = Qnil;

  // extract and check arguments
  rb_scan_args(_argc, _argv, "21", &arg_rtc, &arg_rval, &arg_name);
  r2tao_check_type(arg_rtc, r2tao_cTypecode);
  if (arg_name!=Qnil)
    Check_Type(arg_name, T_STRING);

  CORBA::Request_ptr _req =  r2tao_Request_r2t(self);
  R2TAO_TRY
  {
    CORBA::ORB_var _orb = _req->target ()->_get_orb ();
  
    CORBA::TypeCode_var _arg_tc = r2tao_Typecode_r2t (arg_rtc, _orb. in());
    char *_arg_name = (arg_name!=Qnil) ? RSTRING (arg_name)->ptr : 0;
    // add IN arg
    CORBA::Any& _arg = (arg_name!=Qnil) ?
          _req->add_in_arg (_arg_name) : _req->add_in_arg ();
    // assign value to Any
    if (arg_rval!=Qnil)
      r2tao_Typecode_Ruby2Any(_arg, _arg_tc.in (), arg_rval, _orb.in ());
  }
  R2TAO_CATCH;
  return ULONG2NUM (_req->arguments ()->count ());
}

VALUE rCORBA_Request_add_out_arg(int _argc, VALUE *_argv, VALUE self)
{
  VALUE arg_name = Qnil;
  VALUE arg_rtc = Qnil;

  // extract and check arguments
  rb_scan_args(_argc, _argv, "11", &arg_rtc, &arg_name);
  r2tao_check_type(arg_rtc, r2tao_cTypecode);
  if (arg_name!=Qnil)
    Check_Type(arg_name, T_STRING);

  CORBA::Request_ptr _req =  r2tao_Request_r2t(self);
  R2TAO_TRY
  {
    CORBA::ORB_var _orb = _req->target ()->_get_orb ();
  
    CORBA::TypeCode_var _arg_tc = r2tao_Typecode_r2t (arg_rtc, _orb. in());
    char *_arg_name = (arg_name!=Qnil) ? RSTRING (arg_name)->ptr : 0;
    // add OUT arg
    if (arg_name!=Qnil)
      _req->add_out_arg (_arg_name);
    else
      _req->add_out_arg ();
  }
  R2TAO_CATCH;
  return ULONG2NUM (_req->arguments ()->count ());
}

VALUE rCORBA_Request_add_inout_arg(int _argc, VALUE *_argv, VALUE self)
{
  VALUE arg_name = Qnil;
  VALUE arg_rtc = Qnil;
  VALUE arg_rval = Qnil;

  // extract and check arguments
  rb_scan_args(_argc, _argv, "21", &arg_rtc, &arg_rval, &arg_name);
  r2tao_check_type(arg_rtc, r2tao_cTypecode);
  if (arg_name!=Qnil)
    Check_Type(arg_name, T_STRING);

  CORBA::Request_ptr _req =  r2tao_Request_r2t(self);
  R2TAO_TRY
  {
    CORBA::ORB_var _orb = _req->target ()->_get_orb ();
  
    CORBA::TypeCode_var _arg_tc = r2tao_Typecode_r2t (arg_rtc, _orb. in());
    char *_arg_name = (arg_name!=Qnil) ? RSTRING (arg_name)->ptr : 0;
    // add INOUT arg
    CORBA::Any& _arg = (arg_name!=Qnil) ?
          _req->add_inout_arg (_arg_name) : _req->add_inout_arg ();
    // assign value to Any
    if (arg_rval!=Qnil)
      r2tao_Typecode_Ruby2Any(_arg, _arg_tc.in (), arg_rval, _orb.in ());
  }
  R2TAO_CATCH;
  return ULONG2NUM (_req->arguments ()->count ());
}

VALUE rCORBA_Request_set_return_type(VALUE self, VALUE ret_rtc)
{
  CORBA::Request_ptr _req =  r2tao_Request_r2t(self);
  r2tao_check_type(ret_rtc, r2tao_cTypecode);
  R2TAO_TRY
  {
    return _r2tao_set_request_return_type(_req, ret_rtc);
  }
  R2TAO_CATCH;
  return Qnil;
}

VALUE rCORBA_Request_return_value(VALUE self)
{
  CORBA::Request_ptr _req =  r2tao_Request_r2t(self);
  R2TAO_TRY
  {
    CORBA::ORB_var _orb = _req->target ()->_get_orb ();

    CORBA::Any& _ret_val = _req->return_value ();
    CORBA::TypeCode_var _ret_tc = _ret_val.type ();
    VALUE result_type = r2tao_Typecode_t2r(_ret_tc.in (), _orb.in ());
    return r2tao_Typecode_Any2Ruby (_ret_val, _ret_tc.in (), result_type, result_type, _orb.in ());
  }
  R2TAO_CATCH;

  return Qnil;
}
