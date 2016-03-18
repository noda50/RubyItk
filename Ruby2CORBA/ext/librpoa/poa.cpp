/*--------------------------------------------------------------------
# poa.cpp - R2TAO CORBA PortableServer support
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

#include "poa.h"
#include "tao/DynamicInterface/Server_Request.h"
#include "tao/DynamicInterface/Dynamic_Implementation.h"
#include "tao/AnyTypeCode/Any.h"
#include "tao/AnyTypeCode/NVList.h"
#include "tao/ORB.h"
#include "tao/Exception.h"
#include "tao/TSS_Resources.h"
#include "tao/PortableServer/POA_Current_Impl.h"
#include "tao/IORTable/IORTable.h"
#include "typecode.h"
#include "object.h"
#include "exception.h"
#include "orb.h"

#define RUBY_INVOKE_FUNC RUBY_ALLOC_FUNC

static VALUE r2tao_nsPOA = 0;
static VALUE r2tao_nsPOAManager;
static VALUE r2tao_nsPortableServer;
static VALUE r2tao_nsIORTable;
static VALUE r2tao_cServant;
static VALUE r2tao_cDynamicImp;
static VALUE r2tao_cServerRequest;
static VALUE r2tao_cObjectId;
static VALUE r2tao_nsPolicy;

static VALUE r2tao_cIORTableLocator;
static VALUE r2tao_cIORTableNotFoundX;

static int r2tao_IN_ARG;
static int r2tao_INOUT_ARG;
static int r2tao_OUT_ARG;

static ID repo_Id;
static ID repo_Ids;
static ID get_operation_sig_ID;

static ID invoke_ID;
static ID primary_interface_ID;
static ID is_a_ID;

static ID new_ID;
static ID locate_ID;
static ID include_ID;

static VALUE ID_arg_list;
static VALUE ID_result_type;
static VALUE ID_exc_list;
static VALUE ID_op_sym;

static VALUE r2tao_PS_string_to_ObjectId(VALUE self, VALUE string);
static VALUE r2tao_PS_ObjectId_to_string(VALUE self, VALUE oid);

static VALUE r2tao_POA_destroy(VALUE self, VALUE etherealize, VALUE wait_for_completion);
static VALUE r2tao_POA_the_name(VALUE self);
static VALUE r2tao_POA_the_POAManager(VALUE self);
static VALUE r2tao_POA_the_parent(VALUE self);
static VALUE r2tao_POA_the_children(VALUE self);
static VALUE r2tao_POA_activate_object(VALUE self, VALUE servant);
static VALUE r2tao_POA_activate_object_with_id(VALUE self, VALUE id, VALUE servant);
static VALUE r2tao_POA_deactivate_object(VALUE self, VALUE oid);
static VALUE r2tao_POA_create_reference(VALUE self, VALUE repoid);
static VALUE r2tao_POA_create_reference_with_id(VALUE self, VALUE oid, VALUE repoid);
static VALUE r2tao_POA_servant_to_id(VALUE self, VALUE servant);
static VALUE r2tao_POA_servant_to_reference(VALUE self, VALUE servant);
static VALUE r2tao_POA_reference_to_servant(VALUE self, VALUE obj);
static VALUE r2tao_POA_reference_to_id(VALUE self, VALUE obj);
static VALUE r2tao_POA_id_to_servant(VALUE self, VALUE oid);
static VALUE r2tao_POA_id_to_reference(VALUE self, VALUE oid);
static VALUE r2tao_POA_create_POA(VALUE self, VALUE name, VALUE poaman, VALUE policies);
static VALUE r2tao_POA_find_POA(VALUE self, VALUE name, VALUE activate);
static VALUE r2tao_POA_id(VALUE self);

static PortableServer::POAManager_ptr r2tao_POAManager_r2t(VALUE obj);

static VALUE r2tao_POAManager_activate(VALUE self);
static VALUE r2tao_POAManager_hold_requests(VALUE self, VALUE wait_for_completion);
static VALUE r2tao_POAManager_discard_requests(VALUE self, VALUE wait_for_completion);
static VALUE r2tao_POAManager_deactivate(VALUE self, VALUE etherealize, VALUE wait_for_completion);
static VALUE r2tao_POAManager_get_state(VALUE self);
static VALUE r2tao_POAManager_get_id(VALUE self);
static VALUE r2tao_POAManager_get_orb(VALUE self);

static VALUE r2tao_IORTable_bind(VALUE self, VALUE obj_key, VALUE ior);
static VALUE r2tao_IORTable_rebind(VALUE self, VALUE obj_key, VALUE ior);
static VALUE r2tao_IORTable_unbind(VALUE self, VALUE obj_key);
static VALUE r2tao_IORTable_set_locator(VALUE self, VALUE locator);

static VALUE r2tao_Servant_default_POA(VALUE self);
static VALUE r2tao_Servant_this(VALUE self);

static VALUE r2tao_ServerRequest_operation(VALUE self);
static VALUE r2tao_ServerRequest_describe(VALUE self, VALUE desc);
static VALUE r2tao_ServerRequest_arguments(VALUE self);
static VALUE r2tao_ServerRequest_get(VALUE self, VALUE key);
static VALUE r2tao_ServerRequest_set(VALUE self, VALUE key, VALUE val);

static VALUE srv_alloc(VALUE klass);
static void srv_free(void* ptr);

static VALUE r2tao_ObjectId_t2r(const PortableServer::ObjectId& oid);
static PortableServer::ObjectId* r2tao_ObjectId_r2t(VALUE oid);

#if defined(WIN32) && defined(_DEBUG)
extern "C" R2TAO_POA_EXPORT void Init_librpoad()
#else
extern "C" R2TAO_POA_EXPORT void Init_librpoa()
#endif
{
  VALUE klass;

  if (r2tao_nsCORBA == 0)
  {
    rb_raise(rb_eRuntimeError, "CORBA base not initialized.");
    return;
  }

  if (r2tao_nsPOA) return;

  ID_arg_list = rb_eval_string (":arg_list");
  ID_result_type = rb_eval_string (":result_type");
  ID_exc_list = rb_eval_string (":exc_list");
  ID_op_sym = rb_eval_string (":op_sym");

  r2tao_nsPortableServer = klass = rb_eval_string("::R2CORBA::PortableServer");
  rb_define_singleton_method(klass, "string_to_ObjectId", RUBY_METHOD_FUNC(r2tao_PS_string_to_ObjectId), 1);
  rb_define_singleton_method(klass, "ObjectId_to_string", RUBY_METHOD_FUNC(r2tao_PS_ObjectId_to_string), 1);

  r2tao_nsPOA = klass = rb_eval_string("::R2CORBA::PortableServer::POA");

  rb_define_method(klass, "destroy", RUBY_METHOD_FUNC(r2tao_POA_destroy), 2);
  rb_define_method(klass, "the_name", RUBY_METHOD_FUNC(r2tao_POA_the_name), 0);
  rb_define_method(klass, "the_POAManager", RUBY_METHOD_FUNC(r2tao_POA_the_POAManager), 0);
  rb_define_method(klass, "the_parent", RUBY_METHOD_FUNC(r2tao_POA_the_parent), 0);
  rb_define_method(klass, "the_children", RUBY_METHOD_FUNC(r2tao_POA_the_children), 0);
  rb_define_method(klass, "activate_object", RUBY_METHOD_FUNC(r2tao_POA_activate_object), 1);
  rb_define_method(klass, "activate_object_with_id", RUBY_METHOD_FUNC(r2tao_POA_activate_object_with_id), 2);
  rb_define_method(klass, "deactivate_object", RUBY_METHOD_FUNC(r2tao_POA_deactivate_object), 1);
  rb_define_method(klass, "create_reference", RUBY_METHOD_FUNC(r2tao_POA_create_reference), 1);
  rb_define_method(klass, "create_reference_with_id", RUBY_METHOD_FUNC(r2tao_POA_create_reference_with_id), 2);
  rb_define_method(klass, "servant_to_id", RUBY_METHOD_FUNC(r2tao_POA_servant_to_id), 1);
  rb_define_method(klass, "servant_to_reference", RUBY_METHOD_FUNC(r2tao_POA_servant_to_reference), 1);
  rb_define_method(klass, "reference_to_servant", RUBY_METHOD_FUNC(r2tao_POA_reference_to_servant), 1);
  rb_define_method(klass, "reference_to_id", RUBY_METHOD_FUNC(r2tao_POA_reference_to_id), 1);
  rb_define_method(klass, "id_to_servant", RUBY_METHOD_FUNC(r2tao_POA_id_to_servant), 1);
  rb_define_method(klass, "id_to_reference", RUBY_METHOD_FUNC(r2tao_POA_id_to_reference), 1);
  rb_define_method(klass, "create_POA", RUBY_METHOD_FUNC(r2tao_POA_create_POA), 3);
  rb_define_method(klass, "find_POA", RUBY_METHOD_FUNC(r2tao_POA_find_POA), 2);
  rb_define_method(klass, "id", RUBY_METHOD_FUNC(r2tao_POA_id), 0);

  r2tao_nsPOAManager = klass = rb_eval_string("::R2CORBA::PortableServer::POAManager");

  rb_define_method(klass, "activate", RUBY_METHOD_FUNC(r2tao_POAManager_activate), 0);
  rb_define_method(klass, "hold_requests", RUBY_METHOD_FUNC(r2tao_POAManager_hold_requests), 1);
  rb_define_method(klass, "discard_requests", RUBY_METHOD_FUNC(r2tao_POAManager_discard_requests), 1);
  rb_define_method(klass, "deactivate", RUBY_METHOD_FUNC(r2tao_POAManager_deactivate), 2);
  rb_define_method(klass, "get_state", RUBY_METHOD_FUNC(r2tao_POAManager_get_state), 0);
  rb_define_method(klass, "get_id", RUBY_METHOD_FUNC(r2tao_POAManager_get_id), 0);
  rb_define_method(klass, "_get_orb", RUBY_METHOD_FUNC(r2tao_POAManager_get_orb), 0);

  r2tao_nsIORTable = klass = rb_eval_string("::R2CORBA::IORTable::Table");

  rb_define_method(klass, "bind", RUBY_METHOD_FUNC(r2tao_IORTable_bind), 2);
  rb_define_method(klass, "rebind", RUBY_METHOD_FUNC(r2tao_IORTable_rebind), 2);
  rb_define_method(klass, "unbind", RUBY_METHOD_FUNC(r2tao_IORTable_unbind), 1);
  rb_define_method(klass, "set_locator", RUBY_METHOD_FUNC(r2tao_IORTable_set_locator), 1);

  r2tao_cIORTableNotFoundX = rb_eval_string("::R2CORBA::IORTable::NotFound");
  r2tao_cIORTableLocator = rb_eval_string("::R2CORBA::IORTable::Locator");

  r2tao_cServant = klass = rb_eval_string("::R2CORBA::PortableServer::Servant");
  rb_define_alloc_func (r2tao_cServant, RUBY_ALLOC_FUNC (srv_alloc));
  rb_define_method(klass, "_default_POA", RUBY_METHOD_FUNC(r2tao_Servant_default_POA), 0);
  rb_define_method(klass, "_this", RUBY_METHOD_FUNC(r2tao_Servant_this), 0);

  repo_Id = rb_intern ("Id");
  repo_Ids = rb_intern ("Ids");
  get_operation_sig_ID = rb_intern("get_operation_signature");
  include_ID = rb_intern ("include?");

  r2tao_cDynamicImp = klass = rb_eval_string("::R2CORBA::PortableServer::DynamicImplementation");
  //rb_define_class_under (r2tao_nsPortableServer, "DynamicImplementation", r2tao_cServant);

  r2tao_cServerRequest = klass = rb_define_class_under (r2tao_nsCORBA, "ServerRequest", rb_cObject);
  rb_define_method(klass, "operation", RUBY_METHOD_FUNC(r2tao_ServerRequest_operation), 0);
  rb_define_method(klass, "describe", RUBY_METHOD_FUNC(r2tao_ServerRequest_describe), 1);
  rb_define_method(klass, "arguments", RUBY_METHOD_FUNC(r2tao_ServerRequest_arguments), 0);
  rb_define_method(klass, "[]", RUBY_METHOD_FUNC(r2tao_ServerRequest_get), 1);
  rb_define_method(klass, "[]=", RUBY_METHOD_FUNC(r2tao_ServerRequest_set), 2);

  invoke_ID = rb_intern ("invoke");
  primary_interface_ID = rb_intern ("_primary_interface");
  is_a_ID = rb_intern ("_is_a?");

  new_ID = rb_intern ("new");

  locate_ID = rb_intern ("locate");
  
  r2tao_IN_ARG = NUM2INT (rb_eval_string ("R2CORBA::CORBA::ARG_IN"));
  r2tao_INOUT_ARG = NUM2INT (rb_eval_string ("R2CORBA::CORBA::ARG_INOUT"));
  r2tao_OUT_ARG = NUM2INT (rb_eval_string ("R2CORBA::CORBA::ARG_OUT"));

  r2tao_cObjectId = rb_eval_string("::R2CORBA::PortableServer::ObjectId");
  r2tao_nsPolicy = rb_eval_string ("R2CORBA::CORBA::Policy");
}

//-------------------------------------------------------------------
//  R2TAO ArgumentList class
//
//===================================================================

struct DSI_Data {
  CORBA::ServerRequest_ptr  _request;
  CORBA::NVList_ptr _nvlist;
  CORBA::TypeCode_var _result_type;
  VALUE _rData;

  DSI_Data(CORBA::ServerRequest_ptr _req)
    : _request(_req), _nvlist(0), _rData(Qnil) {}
  ~DSI_Data() {
    if (this->_rData!=Qnil) { DATA_PTR(this->_rData) = 0; }
  }
};

VALUE r2tao_ServerRequest_operation(VALUE self)
{
  if (DATA_PTR (self) != 0)
  {
    CORBA::ServerRequest_ptr request = static_cast<DSI_Data*> (DATA_PTR (self))->_request;
    return rb_str_new2 (request->operation ());
  }
  return Qnil;
}

VALUE r2tao_ServerRequest_describe(VALUE self, VALUE desc)
{
  if (DATA_PTR (self) != 0)
  {
    DSI_Data* dsi_data = static_cast<DSI_Data*> (DATA_PTR (self));

    // only allowed once
    if (CORBA::NVList::_nil () != dsi_data->_nvlist)
    {
      X_CORBA (BAD_INV_ORDER);
    }

    CORBA::ServerRequest_ptr request = dsi_data->_request;

    if (desc != Qnil && rb_type (desc) == T_HASH)
    {
      // check desc and create argument list for ORB
      VALUE arg_list = rb_hash_aref (desc, ID_arg_list);
      if (arg_list != Qnil && rb_type (arg_list) != T_ARRAY)
      {
        X_CORBA(BAD_PARAM);
      }
      VALUE result_type = rb_hash_aref (desc, ID_result_type);
      if (result_type != Qnil && rb_obj_is_kind_of(result_type, r2tao_cTypecode) != Qtrue)
      {
        X_CORBA(BAD_PARAM);
      }

      CORBA::ORB_ptr _orb = request->_tao_server_request ().orb ();

      R2TAO_TRY
      {
        _orb->create_list (0, dsi_data->_nvlist);
      }
      R2TAO_CATCH;

      long arg_len =
          arg_list == Qnil ? 0 : RARRAY (arg_list)->len;
      for (long arg=0; arg<arg_len ;++arg)
      {
        VALUE argspec = rb_ary_entry (arg_list, arg);
        if (argspec != Qnil && rb_type (argspec) != T_ARRAY)
        {
          X_CORBA(BAD_PARAM);
        }
        VALUE argname = rb_ary_entry (argspec, 0);
        if (argname != Qnil && rb_obj_is_kind_of(argname, rb_cString)==Qfalse)
        {
          X_CORBA(BAD_PARAM);
        }
        char *_arg_name = argname != Qnil ? RSTRING (argname)->ptr : 0;
        int _arg_type = NUM2INT (rb_ary_entry (argspec, 1));
        VALUE arg_rtc = rb_ary_entry (argspec, 2);
        if (rb_obj_is_kind_of(arg_rtc, r2tao_cTypecode)==Qfalse)
        {
          X_CORBA(BAD_PARAM);
        }
        R2TAO_TRY
        {
          CORBA::TypeCode_var _arg_tc = r2tao_Typecode_r2t (arg_rtc, _orb);

          CORBA::NamedValue_ptr _nv = _arg_name ?
                dsi_data->_nvlist->add_item (_arg_name, _arg_type == r2tao_IN_ARG ?
                                                        CORBA::ARG_IN :
                                                        (_arg_type == r2tao_INOUT_ARG ?
                                                          CORBA::ARG_INOUT : CORBA::ARG_OUT))
                :
                dsi_data->_nvlist->add (_arg_type == r2tao_IN_ARG ?
                                        CORBA::ARG_IN :
                                        (_arg_type == r2tao_INOUT_ARG ?
                                          CORBA::ARG_INOUT : CORBA::ARG_OUT));
          // assign type info to Any
          _nv->value ()->_tao_set_typecode (_arg_tc.in ());
        }
        R2TAO_CATCH;
      }

      R2TAO_TRY
      {
        // set ORB arguments (retrieves data for IN/INOUT args)
        request->arguments (dsi_data->_nvlist);

        // register result type (if any)
        if (result_type != Qnil)
          dsi_data->_result_type = r2tao_Typecode_r2t (result_type, _orb);
      }
      R2TAO_CATCH;
    }
    else
    {
      X_CORBA(BAD_PARAM);
    }
  }
  return Qnil;
}

VALUE r2tao_ServerRequest_arguments(VALUE self)
{
  if (DATA_PTR (self) != 0)
  {
    DSI_Data* dsi_data = static_cast<DSI_Data*> (DATA_PTR (self));
    if (CORBA::NVList::_nil () == dsi_data->_nvlist)
    {
      X_CORBA (BAD_INV_ORDER);
    }

    R2TAO_TRY
    {
      CORBA::ServerRequest_ptr request = dsi_data->_request;

      CORBA::ORB_ptr _orb = request->_tao_server_request ().orb ();

      // build argument list for servant implementation
      CORBA::ULong arg_len = dsi_data->_nvlist->count ();
      VALUE rargs = rb_ary_new ();
      for (CORBA::ULong arg=0; arg<arg_len ;++arg)
      {
        CORBA::NamedValue_ptr _nv = dsi_data->_nvlist->item (arg);
        if (ACE_BIT_DISABLED (_nv->flags (), CORBA::ARG_OUT))
        {
          CORBA::TypeCode_var _arg_tc = _nv->value ()->type ();
          VALUE rtc = r2tao_Typecode_t2r (_arg_tc, _orb);
          VALUE rval = r2tao_Typecode_Any2Ruby(*_nv->value (), _arg_tc.in (), rtc, rtc, _orb);
          rb_ary_push (rargs, rval);
        }
      }
      return rargs;
    }
    R2TAO_CATCH;
  }
  return Qnil;
}

VALUE r2tao_ServerRequest_get(VALUE self, VALUE key)
{
  if (DATA_PTR (self) != 0)
  {
    DSI_Data* dsi_data = static_cast<DSI_Data*> (DATA_PTR (self));
    if (CORBA::NVList::_nil () == dsi_data->_nvlist)
    {
      X_CORBA (BAD_INV_ORDER);
    }

    if (key == Qnil)
    {
      X_CORBA (BAD_PARAM);
    }

    if (rb_obj_is_kind_of (key, rb_cString) == Qtrue)
    {
      char* arg_name = RSTRING(key)->ptr;
      CORBA::ULong arg_num = dsi_data->_nvlist->count ();
      for (CORBA::ULong ix=0; ix<arg_num ;++ix)
      {
        CORBA::NamedValue_ptr _nv = dsi_data->_nvlist->item (ix);
        if (_nv->name () && ACE_OS::strcmp (arg_name, _nv->name ()) == 0)
        {
          R2TAO_TRY
          {
            CORBA::ORB_ptr _orb = dsi_data->_request->_tao_server_request ().orb ();

            CORBA::TypeCode_var _arg_tc = _nv->value ()->type ();
            VALUE rtc = r2tao_Typecode_t2r (_arg_tc, _orb);
            return r2tao_Typecode_Any2Ruby(*_nv->value (), _arg_tc.in (), rtc, rtc, _orb);
          }
          R2TAO_CATCH;
        }
      }

      X_CORBA (BAD_PARAM);
    }
    else
    {
      CORBA::ULong ix = NUM2ULONG (key);
      if (dsi_data->_nvlist->count () <= ix)
      {
        X_CORBA (BAD_PARAM);
      }
      R2TAO_TRY
      {
        CORBA::ORB_ptr _orb = dsi_data->_request->_tao_server_request ().orb ();

        CORBA::NamedValue_ptr _nv = dsi_data->_nvlist->item (ix);
        CORBA::TypeCode_var _arg_tc = _nv->value ()->type ();
        VALUE rtc = r2tao_Typecode_t2r (_arg_tc, _orb);
        return r2tao_Typecode_Any2Ruby(*_nv->value (), _arg_tc.in (), rtc, rtc, _orb);
      }
      R2TAO_CATCH;
    }
  }
  return Qnil;
}

VALUE r2tao_ServerRequest_set(VALUE self, VALUE key, VALUE val)
{
  if (DATA_PTR (self) != 0)
  {
    DSI_Data* dsi_data = static_cast<DSI_Data*> (DATA_PTR (self));
    if (CORBA::NVList::_nil () == dsi_data->_nvlist)
    {
      X_CORBA (BAD_INV_ORDER);
    }

    if (key == Qnil)
    {
      X_CORBA (BAD_PARAM);
    }

    if (rb_obj_is_kind_of (key, rb_cString) == Qtrue)
    {
      char* arg_name = RSTRING(key)->ptr;
      CORBA::ULong arg_num = dsi_data->_nvlist->count ();
      for (CORBA::ULong ix=0; ix<arg_num ;++ix)
      {
        CORBA::NamedValue_ptr _nv = dsi_data->_nvlist->item (ix);
        if (_nv->name () && ACE_OS::strcmp (arg_name, _nv->name ()) == 0)
        {
          R2TAO_TRY
          {
            CORBA::ORB_ptr _orb = dsi_data->_request->_tao_server_request ().orb ();

            CORBA::TypeCode_var _arg_tc = _nv->value ()->type ();
            r2tao_Typecode_Ruby2Any(*_nv->value (), _arg_tc.in (), val, _orb);
            return Qtrue;
          }
          R2TAO_CATCH;
        }
      }

      X_CORBA (BAD_PARAM);
    }
    else
    {
      CORBA::ULong ix = NUM2ULONG (key);
      if (dsi_data->_nvlist->count () <= ix)
      {
        X_CORBA (BAD_PARAM);
      }
      R2TAO_TRY
      {
        CORBA::ORB_ptr _orb = dsi_data->_request->_tao_server_request ().orb ();

        CORBA::NamedValue_ptr _nv = dsi_data->_nvlist->item (ix);
        CORBA::TypeCode_var _arg_tc = _nv->value ()->type ();
        r2tao_Typecode_Ruby2Any(*_nv->value (), _arg_tc.in (), val, _orb);
        return Qtrue;
      }
      R2TAO_CATCH;
    }
  }
  return Qnil;
}

//-------------------------------------------------------------------
//  R2TAO Servant class
//
//===================================================================

class DSI_Servant;

static VALUE srv_alloc(VALUE klass);
static void srv_free(void* ptr);
static void srv_save(VALUE self, DSI_Servant* obj);

class DSI_Servant : public PortableServer::DynamicImplementation
{
public:
  DSI_Servant (VALUE rbServant);
  // ctor
  virtual ~DSI_Servant ();
  // dtor

  virtual void invoke (CORBA::ServerRequest_ptr request);
      //ACE_THROW_SPEC ((CORBA::SystemException));

  virtual CORBA::RepositoryId _primary_interface (
      const PortableServer::ObjectId &oid,
      PortableServer::POA_ptr poa);

  virtual CORBA::Boolean _is_a (const char *logical_type_id);

  VALUE rbServant () {
    return this->rbServant_;
  }

  void detach_rbServant () {
    this->rbServant_ = Qnil;
  }

protected:
  void invoke_SI (CORBA::ServerRequest_ptr request);
  void invoke_DSI (CORBA::ServerRequest_ptr request);

  static VALUE _invoke_implementation(VALUE args);

private:
  VALUE rbServant_;
  // The Ruby Servant

  CORBA::String_var repo_id_;
};

DSI_Servant::DSI_Servant(VALUE rbServant)
 : rbServant_ (rbServant)
{
  srv_save (rbServant_, this);
}

DSI_Servant::~DSI_Servant()
{
  rbServant_ = Qnil;
}

// invocation helper for rb_protect()
VALUE DSI_Servant::_invoke_implementation(VALUE args)
{
  VALUE servant = rb_ary_entry (args, 0);
  VALUE operation = rb_ary_entry (args, 1);
  VALUE opargs = rb_ary_entry (args, 2);
  return rb_apply (servant, SYM2ID (operation), opargs);
}

void DSI_Servant::invoke (CORBA::ServerRequest_ptr request)
{
  // check if Ruby servant still attached
  if (this->rbServant_ == Qnil)
  {
    // we're detached so nothing is implemented anymore
    throw ::CORBA::NO_IMPLEMENT (0, CORBA::COMPLETED_NO);
  }

  if (ACE_OS::strcmp (request->operation (), "_is_a") == 0)
  {
    CORBA::ORB_ptr _orb = request->_tao_server_request ().orb ();

    CORBA::NVList_ptr nvlist;
    _orb->create_list (0, nvlist);

    CORBA::NamedValue_ptr _nv = nvlist->add (CORBA::ARG_IN);
    _nv->value ()->_tao_set_typecode (CORBA::_tc_string);

    // set ORB arguments (retrieves data for IN/INOUT args)
    request->arguments (nvlist);

    const char *tmp;
    (*_nv->value ()) >>= tmp;

    CORBA::Boolean f = this->_is_a (tmp);

    if (TAO_debug_level > 3)
      ACE_DEBUG ((LM_INFO, "R2TAO (%P|%t) _is_a (%s) -> %d\n", tmp, f));

    CORBA::Any _any;
    _any <<= CORBA::Any::from_boolean (f);
    request->set_result(_any);
  }
  else
  {
    if (rb_obj_is_kind_of (this->rbServant_, r2tao_cDynamicImp))
      this->invoke_DSI(request);
    else
      this->invoke_SI(request);
  }
}

void DSI_Servant::invoke_DSI (CORBA::ServerRequest_ptr request)
{
  // wrap request for Ruby; cleanup automatically
  ACE_Auto_Basic_Ptr<DSI_Data>  dsi_data(new DSI_Data(request));

  VALUE srvreq = Data_Wrap_Struct(r2tao_cServerRequest, 0, 0, dsi_data.get ());

  dsi_data.get()->_rData = srvreq;  // have DSI_Data clean up Ruby object at destruction time

  // invoke servant implementation
  VALUE rargs = rb_ary_new2 (1);
  rb_ary_push (rargs, srvreq);
  VALUE invoke_holder = rb_ary_new2 (3);
  rb_ary_push (invoke_holder, this->rbServant_);
  rb_ary_push (invoke_holder, ID2SYM (invoke_ID));
  rb_ary_push (invoke_holder, rargs);
  int invoke_state = 0;
  VALUE ret = rb_protect (RUBY_INVOKE_FUNC (DSI_Servant::_invoke_implementation),
                          invoke_holder,
                          &invoke_state);

  CORBA::ORB_ptr _orb = request->_tao_server_request ().orb ();

  if (invoke_state)
  {
    // handle exception
    VALUE rexc = rb_gv_get ("$!");
    if (rb_obj_is_kind_of(rexc, r2tao_cUserException) == Qtrue)
    {
      VALUE rextc = rb_eval_string ("R2CORBA::CORBA::Any.typecode_for_any ($!)");
      if (rextc != Qnil)
      {
        CORBA::Any _xval;
        CORBA::TypeCode_var _xtc = r2tao_Typecode_r2t (rextc, _orb);
        r2tao_Typecode_Ruby2Any(_xval, _xtc.in (), rexc, _orb);
        request->set_exception (_xval);

        return;
      }
    }

    if (rb_obj_is_kind_of(rexc, r2tao_cSystemException) == Qtrue)
    {
      VALUE rid = rb_funcall (rexc, rb_intern ("_interface_repository_id"), 0);
      CORBA::SystemException* _exc = TAO::create_system_exception (RSTRING(rid)->ptr);

      _exc->minor (
        static_cast<CORBA::ULong> (NUM2ULONG (rb_iv_get (rexc, "@minor"))));
      _exc->completed (
        static_cast<CORBA::CompletionStatus> (NUM2ULONG (rb_iv_get (rexc, "@completed"))));

      ACE_Auto_Basic_Ptr<CORBA::SystemException> e_ptr(_exc);
      _exc->_raise ();
    }
    else
    {
      rb_eval_string ("STDERR.puts $!.to_s+\"\\n\"+$!.backtrace.join(\"\\n\")");
      throw ::CORBA::UNKNOWN (0, CORBA::COMPLETED_MAYBE);
    }
  }
  else
  {
    // check for oneway (no results at all) or twoway
    if (!CORBA::is_nil (dsi_data.get()->_result_type.in ()))
    {
      // twoway
      if (TAO_debug_level > 3)
        ACE_DEBUG ((LM_INFO, "(%P|%t) checking return values of twoway invocation\n"));

      // handle OUT values
      long arg_out = 0;
      long ret_off =
          (dsi_data.get()->_result_type->kind () != CORBA::tk_void) ? 1 : 0;
      CORBA::ULong arg_len = dsi_data.get()->_nvlist->count ();
      for (CORBA::ULong arg=0; arg<arg_len ;++arg)
      {
        if (TAO_debug_level > 5)
          ACE_DEBUG ((LM_INFO, "(%P|%t) handling (IN)OUT arg %d\n", arg));

        CORBA::NamedValue_ptr _nv = dsi_data.get()->_nvlist->item (arg);
        if (ACE_BIT_DISABLED (_nv->flags (), CORBA::ARG_IN))
        {
          ++arg_out; // count number of (IN)OUT arguments

          VALUE retval = Qnil;
          if (rb_type (ret) == T_ARRAY && ret_off<RARRAY(ret)->len)
          {
            retval = rb_ary_entry (ret, ret_off++);
          }
          CORBA::TypeCode_var _arg_tc = _nv->value ()->type ();
          r2tao_Typecode_Ruby2Any(*_nv->value (), _arg_tc.in (), retval, _orb);

          if (TAO_debug_level > 5)
            ACE_DEBUG ((LM_INFO, "(%P|%t) converted (IN)OUT arg %d\n", arg));
        }
      }

      // handle return value
      if (dsi_data.get()->_result_type->kind () != CORBA::tk_void)
      {
        if (TAO_debug_level > 5)
          ACE_DEBUG ((LM_INFO, "(%P|%t) handling result value\n"));

        CORBA::Any _retval;
        VALUE retval = Qnil;
        if (arg_out == 0)
        {
          retval = ret;
        }
        else if (rb_type (ret) == T_ARRAY && 0<RARRAY(ret)->len)
        {
          retval = rb_ary_entry (ret, 0);
        }
        r2tao_Typecode_Ruby2Any(_retval, dsi_data.get()->_result_type.in (), retval, _orb);

        if (TAO_debug_level > 5)
          ACE_DEBUG ((LM_INFO, "(%P|%t) converted result value\n"));

        request->set_result (_retval);
      }
    }
  }
}

void DSI_Servant::invoke_SI (CORBA::ServerRequest_ptr request)
{
  // retrieve targeted operation
  VALUE ropsym = ID2SYM (rb_intern (request->operation ()));
  // retrieve operation signature
  VALUE ropsig = rb_funcall (this->rbServant_, get_operation_sig_ID, 1, ropsym);

  if (ropsig != Qnil && rb_type (ropsig) == T_HASH)
  {
    // check signature and create argument list for ORB
    VALUE arg_list = rb_hash_aref (ropsig, ID_arg_list);
    if (arg_list != Qnil && rb_type (arg_list) != T_ARRAY)
    {
      throw ::CORBA::BAD_PARAM (0, CORBA::COMPLETED_NO);
    }
    VALUE result_type = rb_hash_aref (ropsig, ID_result_type);
    if (result_type != Qnil && rb_obj_is_kind_of(result_type, r2tao_cTypecode) != Qtrue)
    {
      throw ::CORBA::BAD_PARAM (0, CORBA::COMPLETED_NO);
    }
    VALUE exc_list = rb_hash_aref (ropsig, ID_exc_list);
    if (exc_list != Qnil && rb_type (exc_list) != T_ARRAY)
    {
      throw ::CORBA::BAD_PARAM (0, CORBA::COMPLETED_NO);
    }
    VALUE alt_op_sym = rb_hash_aref (ropsig, ID_op_sym);
    if (alt_op_sym != Qnil && rb_type (alt_op_sym) == T_SYMBOL)
    {
      ropsym = alt_op_sym;
    }

    CORBA::ORB_ptr _orb = request->_tao_server_request ().orb ();

    CORBA::NVList_ptr nvlist;
    _orb->create_list (0, nvlist);

    long arg_len =
        arg_list == Qnil ? 0 : RARRAY (arg_list)->len;
    for (long arg=0; arg<arg_len ;++arg)
    {
      VALUE argspec = rb_ary_entry (arg_list, arg);
      if (argspec != Qnil && rb_type (argspec) != T_ARRAY)
      {
        throw ::CORBA::BAD_PARAM (0, CORBA::COMPLETED_NO);
      }
      char *_arg_name = RSTRING (rb_ary_entry (argspec, 0))->ptr;
      int _arg_type = NUM2INT (rb_ary_entry (argspec, 1));
      CORBA::TypeCode_var _arg_tc = r2tao_Typecode_r2t (rb_ary_entry (argspec, 2), _orb);

      CORBA::NamedValue_ptr _nv = nvlist->add_item (_arg_name, _arg_type == r2tao_IN_ARG ?
                                                    CORBA::ARG_IN :
                                                    (_arg_type == r2tao_INOUT_ARG ?
                                                      CORBA::ARG_INOUT : CORBA::ARG_OUT));
      // assign type info to Any
      _nv->value ()->_tao_set_typecode (_arg_tc.in ());
    }

    // set ORB arguments (retrieves data for IN/INOUT args)
    request->arguments (nvlist);

    // build argument list for servant implementation
    VALUE rargs = rb_ary_new ();
    for (long arg=0; arg<arg_len ;++arg)
    {
      CORBA::NamedValue_ptr _nv = nvlist->item (static_cast<CORBA::ULong> (arg));
      if (ACE_BIT_DISABLED (_nv->flags (), CORBA::ARG_OUT))
      {
        VALUE argspec = rb_ary_entry (arg_list, arg);
        VALUE rtc = rb_ary_entry (argspec, 2);
        CORBA::TypeCode_var _arg_tc = r2tao_Typecode_r2t (rtc, _orb);
        VALUE rval = r2tao_Typecode_Any2Ruby(*_nv->value (), _arg_tc.in (), rtc, rtc, _orb);
        rb_ary_push (rargs, rval);
      }
    }

    // invoke servant implementation
    VALUE invoke_holder = rb_ary_new2 (4);
    rb_ary_push (invoke_holder, this->rbServant_);
    rb_ary_push (invoke_holder, ropsym);
    rb_ary_push (invoke_holder, rargs);
    int invoke_state = 0;
    VALUE ret = rb_protect (RUBY_INVOKE_FUNC (DSI_Servant::_invoke_implementation),
                            invoke_holder,
                            &invoke_state);
    if (invoke_state)
    {
      // handle exception
      VALUE rexc = rb_gv_get ("$!");
      if (rb_obj_is_kind_of(rexc, r2tao_cUserException) == Qtrue)
      {
        if (exc_list != Qnil)
        {
          long exc_len = RARRAY (exc_list)->len;
          for (long x=0; x<exc_len ;++x)
          {
            VALUE exctc = rb_ary_entry (exc_list, x);
            VALUE exklass = rb_funcall (exctc, rb_intern ("get_type"), 0);
            if (rb_obj_is_kind_of(rexc, exklass) == Qtrue)
            {
              CORBA::Any _xval;
              CORBA::TypeCode_var _xtc = r2tao_Typecode_r2t (exctc, _orb);
              r2tao_Typecode_Ruby2Any(_xval, _xtc.in (), rexc, _orb);
              request->set_exception (_xval);

              return;
            }
          }
        }
      }

      if (rb_obj_is_kind_of(rexc, r2tao_cSystemException) == Qtrue)
      {
        VALUE rid = rb_funcall (rexc, rb_intern ("_interface_repository_id"), 0);
        CORBA::SystemException* _exc = TAO::create_system_exception (RSTRING(rid)->ptr);

        _exc->minor (
          static_cast<CORBA::ULong> (NUM2ULONG (rb_iv_get (rexc, "@minor"))));
        _exc->completed (
          static_cast<CORBA::CompletionStatus> (NUM2ULONG (rb_iv_get (rexc, "@completed"))));

        ACE_Auto_Basic_Ptr<CORBA::SystemException> e_ptr(_exc);
        _exc->_raise ();
      }
      else
      {
        rb_eval_string ("STDERR.puts $!.to_s+\"\\n\"+$!.backtrace.join(\"\\n\")");
        throw ::CORBA::UNKNOWN (0, CORBA::COMPLETED_MAYBE);
      }
    }
    else
    {
      // check for oneway (no results at all) or twoway
      if (result_type != Qnil)
      {
        if (TAO_debug_level > 3)
          ACE_DEBUG ((LM_INFO, "(%P|%t) checking return values of twoway invocation\n"));

        // twoway
        CORBA::TypeCode_var _result_tc = r2tao_Typecode_r2t (result_type, _orb);

        // handle OUT values
        long ret_off =
            (_result_tc->kind () != CORBA::tk_void) ? 1 : 0;
        long arg_out = 0;
        for (long arg=0; arg<arg_len ;++arg)
        {
          if (TAO_debug_level > 5)
            ACE_DEBUG ((LM_INFO, "(%P|%t) handling (IN)OUT arg %d\n", arg));

          CORBA::NamedValue_ptr _nv = nvlist->item (static_cast<CORBA::ULong> (arg));
          if (ACE_BIT_DISABLED (_nv->flags (), CORBA::ARG_IN))
          {
            ++arg_out; // count number of (IN)OUT arguments

            VALUE retval = Qnil;
            if (rb_type (ret) == T_ARRAY && ret_off<RARRAY(ret)->len)
            {
              retval = rb_ary_entry (ret, ret_off++);
            }
            VALUE argspec = rb_ary_entry (arg_list, arg);
            VALUE rtc = rb_ary_entry (argspec, 2);
            CORBA::TypeCode_var _arg_tc = r2tao_Typecode_r2t (rtc, _orb);
            r2tao_Typecode_Ruby2Any(*_nv->value (), _arg_tc.in (), retval, _orb);

            if (TAO_debug_level > 5)
              ACE_DEBUG ((LM_INFO, "(%P|%t) converted (IN)OUT arg %d\n", arg));
          }
        }

        // handle return value
        if (_result_tc->kind () != CORBA::tk_void)
        {
          if (TAO_debug_level > 5)
            ACE_DEBUG ((LM_INFO, "(%P|%t) handling result value\n"));

          CORBA::Any _retval;
          VALUE retval = Qnil;
          if (arg_out == 0)
          {
            retval = ret;
          }
          else if (rb_type (ret) == T_ARRAY && 0<RARRAY(ret)->len)
          {
            retval = rb_ary_entry (ret, 0);
          }
          r2tao_Typecode_Ruby2Any(_retval, _result_tc.in (), retval, _orb);

          if (TAO_debug_level > 5)
            ACE_DEBUG ((LM_INFO, "(%P|%t) converted result value\n"));

          request->set_result (_retval);
        }
      }
    }
  }
  else
  {
    throw ::CORBA::NO_IMPLEMENT (0, CORBA::COMPLETED_NO);
  }
}

CORBA::Boolean DSI_Servant::_is_a (const char *logical_type_id)
{
  // provide support for multiple interfaces
  if (rb_respond_to (this->rbServant_, is_a_ID) == Qtrue)
  {
    // call overloaded #_is_a? method in servant implementation
    return (Qtrue == rb_funcall (this->rbServant_, is_a_ID,
                                 1, rb_str_new2 (logical_type_id ? logical_type_id : "")));
  }
  else if (rb_const_defined (rb_class_of (this->rbServant_), repo_Ids) == Qtrue)
  {
    // check if requested interface included in servants Ids array
    return (Qtrue == rb_funcall (rb_const_get (rb_class_of (this->rbServant_), repo_Ids),
                                 include_ID, 1, rb_str_new2 (logical_type_id ? logical_type_id : "")));
  }
  else
  {
    return PortableServer::DynamicImplementation::_is_a (logical_type_id);
  }
}

CORBA::RepositoryId DSI_Servant::_primary_interface (
    const PortableServer::ObjectId & oid,
    PortableServer::POA_ptr poa)
{
  // check if Ruby servant still attached
  if (this->rbServant_ == Qnil)
  {
    return CORBA::string_dup ("");
  }

  if (rb_obj_is_kind_of (this->rbServant_, r2tao_cDynamicImp))
  {
    // invoke servant implementation
    VALUE rargs = rb_ary_new2 (1);
    rb_ary_push (rargs, r2tao_ObjectId_t2r (oid));
    VALUE rpoa = r2tao_Object_t2r(dynamic_cast<CORBA::Object_ptr> (poa));
    rpoa = rb_funcall (r2tao_nsPOA, rb_intern ("_narrow"), 1, rpoa);
    rb_ary_push (rargs, rpoa);
    VALUE invoke_holder = rb_ary_new2 (3);
    rb_ary_push (invoke_holder, this->rbServant_);
    rb_ary_push (invoke_holder, ID2SYM (primary_interface_ID));
    rb_ary_push (invoke_holder, rargs);
    int invoke_state = 0;
    VALUE ret = rb_protect (RUBY_INVOKE_FUNC (DSI_Servant::_invoke_implementation),
                            invoke_holder,
                            &invoke_state);
    if (invoke_state || ret==Qnil || rb_obj_is_kind_of(ret, rb_cString)==Qfalse)
    {
      ACE_ERROR ((LM_ERROR, "(%P|%t) FAILED TO RETRIEVE REPO-ID FOR SERVANT!\n"));
      return CORBA::string_dup ("");
    }
    else
    {
      return CORBA::string_dup (RSTRING (ret)->ptr);
    }
  }
  else
  {
    if (this->repo_id_.in () == 0)
    {
      if (rb_const_defined (rb_class_of (rbServant_), repo_Id) == Qtrue)
      {
        this->repo_id_ = CORBA::string_dup (
          RSTRING(rb_const_get (rb_class_of (rbServant_), repo_Id))->ptr);
      }
      else
      {
        ACE_ERROR ((LM_ERROR, "(%P|%t) FAILED TO RETRIEVE REPO-ID FOR SERVANT!\n"));
        this->repo_id_ = CORBA::string_dup ("");
      }
    }
    return CORBA::string_dup (this->repo_id_.in ());
  }
}

VALUE r2tao_Servant_default_POA(VALUE self)
{
  R2TAO_TRY
  {
    bool _new_srv = false;
    DSI_Servant* _servant;
    if (DATA_PTR (self) == 0)
    {
      // create new C++ servant object
      _servant = new DSI_Servant (self);
      _new_srv = true;
    }
    else
    {
      // get existing C++ servant object
      _servant = static_cast<DSI_Servant*> (DATA_PTR (self));
    }

    // get default POA
    PortableServer::POA_var _poa = _servant->_default_POA ();
    VALUE rpoa = r2tao_Object_t2r(dynamic_cast<CORBA::Object_ptr> (_poa.in ()));
    return rb_funcall (r2tao_nsPOA, rb_intern ("_narrow"), 1, rpoa);
  }
  R2TAO_CATCH;
  return Qnil;
}

VALUE r2tao_Servant_this(VALUE self)
{
  R2TAO_TRY
  {
    bool _new_srv = false;
    DSI_Servant* _servant;
    if (DATA_PTR (self) == 0)
    {
      // create new C++ servant object
      _servant = new DSI_Servant (self);
      _new_srv = true;
    }
    else
    {
      // get existing C++ servant object
      _servant = static_cast<DSI_Servant*> (DATA_PTR (self));
    }
  
    // Check if we're called from the context of an invocation of this
    // servant or not. We check the POA_Current_Impl in TSS for this.
    if (!_new_srv)
    {
      TAO::Portable_Server::POA_Current_Impl *poa_current_impl =
        static_cast <TAO::Portable_Server::POA_Current_Impl *>
                        (TAO_TSS_Resources::instance ()->poa_current_impl_);

      if (poa_current_impl != 0
          && poa_current_impl->servant () == _servant)
        {
          // in an invocation we can safely use _this()
          CORBA::Object_var _obj = _servant->_this ();
          return r2tao_Object_t2r(_obj.in ());
        }
    }

    // register with default POA and return object ref
    VALUE rpoa = rb_funcall (self, rb_intern ("_default_POA"), 0);
    PortableServer::POA_var _poa = r2tao_POA_r2t (rpoa);
    PortableServer::ObjectId_var _oid = _poa->activate_object (_servant);
    CORBA::Object_var _obj = _poa->id_to_reference (_oid.in ());
    return r2tao_Object_t2r(_obj.in ());
  }
  R2TAO_CATCH;
  return Qnil;
}

//-------------------------------------------------------------------
//  Ruby <-> TAO servant conversions
//
//===================================================================

static VALUE
srv_alloc(VALUE klass)
{
  VALUE obj;
  // we start off without the C++ representation
  obj = Data_Wrap_Struct(klass, 0, srv_free, 0);
  return obj;
}

static void
srv_free(void* ptr)
{
  if (ptr)
  {
    // detach from Ruby servant object
    static_cast<DSI_Servant*> (ptr)->detach_rbServant ();
    // decrement ref count
    static_cast<DSI_Servant*> (ptr)->_remove_ref ();
  }
}

static void
srv_save(VALUE self, DSI_Servant* obj)
{
  // increment ref count
  obj->_add_ref ();

  DATA_PTR(self) = obj;
}

//-------------------------------------------------------------------
//  ObjectId functions
//
//===================================================================

static VALUE r2tao_ObjectId_t2r(const PortableServer::ObjectId& oid)
{
  return rb_funcall (r2tao_cObjectId,
                     new_ID,
                     1,
                     rb_str_new ((char*)oid.get_buffer (), (long)oid.length ()));
}

static PortableServer::ObjectId* r2tao_ObjectId_r2t(VALUE oid)
{
  VALUE oidstr =
    rb_type (oid) == T_STRING ? oid : rb_str_to_str (oid);
  CORBA::ULong buflen = static_cast<CORBA::ULong> (RSTRING (oidstr)->len);
  CORBA::Octet* buf =
      PortableServer::ObjectId::allocbuf (buflen);
  ACE_OS::memcpy (buf, RSTRING (oidstr)->ptr, static_cast<size_t> (buflen));
  return new PortableServer::ObjectId (buflen, buflen, buf, true);
}

//-------------------------------------------------------------------
//  Ruby PortableServer class methods
//
//===================================================================

VALUE r2tao_PS_string_to_ObjectId(VALUE /*self*/, VALUE string)
{
  string = rb_check_convert_type(string, T_STRING, "String", "to_s");
  R2TAO_TRY
  {
    PortableServer::ObjectId_var oid =
        PortableServer::string_to_ObjectId (RSTRING(string)->ptr);
    return r2tao_ObjectId_t2r (oid);
  }
  R2TAO_CATCH;
  return Qnil;
}

VALUE r2tao_PS_ObjectId_to_string(VALUE /*self*/, VALUE oid)
{
  R2TAO_TRY
  {
    PortableServer::ObjectId_var _oid = r2tao_ObjectId_r2t(oid);
    CORBA::String_var str = PortableServer::ObjectId_to_string (_oid);
    return rb_str_new2 (str.in ());
  }
  R2TAO_CATCH;
  return Qnil;
}

//-------------------------------------------------------------------
//  Ruby POA functions
//
//===================================================================

PortableServer::POA_ptr r2tao_POA_r2t(VALUE obj)
{
  CORBA::Object_ptr _obj = r2tao_Object_r2t (obj);
  return PortableServer::POA::_narrow (_obj);
}

VALUE r2tao_POA_destroy(VALUE self, VALUE etherealize, VALUE wait_for_completion)
{
  R2TAO_TRY
  {
    PortableServer::POA_var _poa = r2tao_POA_r2t (self);
    _poa->destroy (etherealize == Qtrue, wait_for_completion == Qtrue);
  }
  R2TAO_CATCH;
  return Qnil;
}
VALUE r2tao_POA_the_name(VALUE self)
{
  VALUE rpoaname = Qnil;
  R2TAO_TRY
  {
    PortableServer::POA_var _poa = r2tao_POA_r2t (self);
    CORBA::String_var _poaname = _poa->the_name ();
    rpoaname = rb_str_new2 (_poaname.in ());
  }
  R2TAO_CATCH;
  return rpoaname;
}
VALUE r2tao_POA_the_POAManager(VALUE self)
{
  VALUE rpoa_man = Qnil;
  R2TAO_TRY
  {
    PortableServer::POA_var _poa = r2tao_POA_r2t (self);
    PortableServer::POAManager_var _poa_manager = _poa->the_POAManager ();

    CORBA::Object_ptr obj =
        dynamic_cast<CORBA::Object_ptr> (PortableServer::POAManager::_duplicate (_poa_manager));
    rpoa_man = r2tao_Object_t2r (obj);
    rpoa_man = rb_funcall (r2tao_nsPOAManager, rb_intern ("_narrow"), 1, rpoa_man);
  }
  R2TAO_CATCH;
  return rpoa_man;
}
VALUE r2tao_POA_the_parent(VALUE self)
{
  VALUE rpoa_parent = Qnil;
  R2TAO_TRY
  {
    PortableServer::POA_var _poa = r2tao_POA_r2t (self);
    PortableServer::POA_var _poa_parent = _poa->the_parent ();

    rpoa_parent = r2tao_Object_t2r(dynamic_cast<CORBA::Object_ptr> (_poa_parent.in ()));
    rpoa_parent = rb_funcall (r2tao_nsPOA, rb_intern ("_narrow"), 1, rpoa_parent);
  }
  R2TAO_CATCH;
  return rpoa_parent;
}
VALUE r2tao_POA_the_children(VALUE self)
{
  VALUE rpoa_list = Qnil;
  R2TAO_TRY
  {
    PortableServer::POA_var _poa = r2tao_POA_r2t (self);
    PortableServer::POAList_var _poa_list = _poa->the_children ();

    rpoa_list = rb_ary_new2 (ULONG2NUM (_poa_list->length ()));
    for (CORBA::ULong l=0; l<_poa_list->length () ;++l)
    {
      PortableServer::POA_ptr _poa_child = _poa_list[l];
      VALUE rpoa_child = r2tao_Object_t2r(dynamic_cast<CORBA::Object_ptr> (_poa_child));
      rb_ary_push (rpoa_list, rb_funcall (r2tao_nsPOA, rb_intern ("_narrow"), 1, rpoa_child));
    }
  }
  R2TAO_CATCH;
  return rpoa_list;
}
VALUE r2tao_POA_activate_object(VALUE self, VALUE servant)
{
  r2tao_check_type(servant, r2tao_cServant);

  R2TAO_TRY
  {
    PortableServer::POA_var _poa = r2tao_POA_r2t (self);

    DSI_Servant* _servant;
    if (DATA_PTR (servant) == 0)
    {
      _servant = new DSI_Servant (servant);
    }
    else
    {
      _servant = static_cast<DSI_Servant*> (DATA_PTR (servant));
    }
    PortableServer::ObjectId_var oid = _poa->activate_object (_servant);
    return r2tao_ObjectId_t2r (oid.in ());
  }
  R2TAO_CATCH;
  return Qnil;
}
VALUE r2tao_POA_activate_object_with_id(VALUE self, VALUE oid, VALUE servant)
{
  R2TAO_TRY
  {
    PortableServer::ObjectId_var _oid = r2tao_ObjectId_r2t(oid);
    PortableServer::POA_var _poa = r2tao_POA_r2t (self);

    DSI_Servant* _servant;
    if (DATA_PTR (servant) == 0)
    {
      _servant = new DSI_Servant (servant);
    }
    else
    {
      _servant = static_cast<DSI_Servant*> (DATA_PTR (servant));
    }
    _poa->activate_object_with_id (_oid.in (), _servant);
  }
  R2TAO_CATCH;
  return Qnil;
}

VALUE r2tao_POA_deactivate_object(VALUE self, VALUE oid)
{
  R2TAO_TRY
  {
    PortableServer::ObjectId_var _oid = r2tao_ObjectId_r2t(oid);
    PortableServer::POA_var _poa = r2tao_POA_r2t (self);

    _poa->deactivate_object (_oid.in ());
  }
  R2TAO_CATCH;
  return Qnil;
}
VALUE r2tao_POA_create_reference(VALUE self, VALUE repoid)
{
  Check_Type(repoid, T_STRING);
  R2TAO_TRY
  {
    PortableServer::POA_var _poa = r2tao_POA_r2t (self);

    CORBA::Object_var obj = _poa->create_reference (RSTRING (repoid)->ptr);
    return r2tao_Object_t2r(obj.in ());
  }
  R2TAO_CATCH;
  return Qnil;
}
VALUE r2tao_POA_create_reference_with_id(VALUE self, VALUE oid, VALUE repoid)
{
  Check_Type(repoid, T_STRING);
  R2TAO_TRY
  {
    PortableServer::ObjectId_var _oid = r2tao_ObjectId_r2t(oid);
    PortableServer::POA_var _poa = r2tao_POA_r2t (self);

    CORBA::Object_var obj = _poa->create_reference_with_id (_oid.in (), RSTRING (repoid)->ptr);
    return r2tao_Object_t2r(obj.in ());
  }
  R2TAO_CATCH;
  return Qnil;
}
VALUE r2tao_POA_servant_to_id(VALUE self, VALUE servant)
{
  r2tao_check_type(servant, r2tao_cServant);

  R2TAO_TRY
  {
    PortableServer::POA_var _poa = r2tao_POA_r2t (self);

    DSI_Servant* _servant = static_cast<DSI_Servant*> (DATA_PTR (servant));
    PortableServer::ObjectId_var _oid = _poa->servant_to_id (_servant);
    return r2tao_ObjectId_t2r (_oid.in ());
  }
  R2TAO_CATCH;
  return Qnil;
}
VALUE r2tao_POA_servant_to_reference(VALUE self, VALUE servant)
{
  r2tao_check_type(servant, r2tao_cServant);

  R2TAO_TRY
  {
    PortableServer::POA_var _poa = r2tao_POA_r2t (self);

    DSI_Servant* _servant = static_cast<DSI_Servant*> (DATA_PTR (servant));
    CORBA::Object_var _obj = _poa->servant_to_reference (_servant);
    return r2tao_Object_t2r(_obj.in ());
  }
  R2TAO_CATCH;
  return Qnil;
}
VALUE r2tao_POA_reference_to_servant(VALUE self, VALUE obj)
{
  R2TAO_TRY
  {
    CORBA::Object_ptr _obj = r2tao_Object_r2t (obj);
    PortableServer::POA_var _poa = r2tao_POA_r2t (self);

    PortableServer::Servant _srv = _poa->reference_to_servant (_obj);
    DSI_Servant* _servant = dynamic_cast<DSI_Servant*> (_srv);
    return _servant->rbServant ();
  }
  R2TAO_CATCH;
  return Qnil;
}
VALUE r2tao_POA_reference_to_id(VALUE self, VALUE obj)
{
  R2TAO_TRY
  {
    CORBA::Object_ptr _obj = r2tao_Object_r2t (obj);
    PortableServer::POA_var _poa = r2tao_POA_r2t (self);

    PortableServer::ObjectId_var _oid = _poa->reference_to_id (_obj);
    return r2tao_ObjectId_t2r (_oid.in ());
  }
  R2TAO_CATCH;
  return Qnil;
}
VALUE r2tao_POA_id_to_servant(VALUE self, VALUE oid)
{
  R2TAO_TRY
  {
    PortableServer::ObjectId_var _oid = r2tao_ObjectId_r2t(oid);
    PortableServer::POA_var _poa = r2tao_POA_r2t (self);

    PortableServer::Servant _srv = _poa->id_to_servant (_oid.in ());
    DSI_Servant* _servant = dynamic_cast<DSI_Servant*> (_srv);
    return _servant->rbServant ();
  }
  R2TAO_CATCH;
  return Qnil;
}
VALUE r2tao_POA_id_to_reference(VALUE self, VALUE oid)
{
  R2TAO_TRY
  {
    PortableServer::ObjectId_var _oid = r2tao_ObjectId_r2t(oid);
    PortableServer::POA_var _poa = r2tao_POA_r2t (self);

    CORBA::Object_var _obj = _poa->id_to_reference (_oid.in ());
    return r2tao_Object_t2r(_obj.in ());
  }
  R2TAO_CATCH;
  return Qnil;
}

VALUE r2tao_POA_create_POA(VALUE self, VALUE name, VALUE poaman, VALUE policies)
{
  VALUE poaret = Qnil;
  CORBA::ULong alen = 0;

  name = rb_check_convert_type(name, T_STRING, "String", "to_s");
  r2tao_check_type (poaman, r2tao_nsPOAManager);
  if (policies != Qnil)
  {
    VALUE rPolicyList_tc = rb_eval_string ("CORBA::PolicyList._tc");
    rb_funcall (rPolicyList_tc, rb_intern ("validate"), 1, policies);
    alen = static_cast<unsigned long> (RARRAY (policies)->len);
  }

  R2TAO_TRY
  {
    PortableServer::POA_var _poa = r2tao_POA_r2t (self);
    PortableServer::POAManager_var _poa_man = r2tao_POAManager_r2t (poaman);
    CORBA::PolicyList pollist(alen);
    pollist.length (alen);
    for (CORBA::ULong l=0; l<alen ;++l)
    {
      VALUE pol = rb_ary_entry (policies, l);
      CORBA::Object_ptr obj = r2tao_Object_r2t(pol);
      pollist[l] = CORBA::Policy::_duplicate (dynamic_cast<CORBA::Policy_ptr> (obj));
    }

    PortableServer::POA_var _newpoa =
        _poa->create_POA (RSTRING(name)->ptr, _poa_man.in (), pollist);

    poaret = r2tao_Object_t2r (dynamic_cast<CORBA::Object_ptr> (_newpoa.in ()));
    poaret = rb_funcall (r2tao_nsPOA, rb_intern ("_narrow"), 1, poaret);
  }
  R2TAO_CATCH;

  return poaret;
}

VALUE r2tao_POA_find_POA(VALUE self, VALUE name, VALUE activate)
{
  VALUE poaret = Qnil;

  name = rb_check_convert_type(name, T_STRING, "String", "to_s");

  R2TAO_TRY
  {
    PortableServer::POA_var _poa = r2tao_POA_r2t (self);
    PortableServer::POA_var _newpoa =
        _poa->find_POA (RSTRING(name)->ptr, activate == Qtrue);

    poaret = r2tao_Object_t2r (dynamic_cast<CORBA::Object_ptr> (_newpoa.in ()));
    poaret = rb_funcall (r2tao_nsPOA, rb_intern ("_narrow"), 1, poaret);
  }
  R2TAO_CATCH;

  return poaret;
}

VALUE r2tao_POA_id(VALUE self)
{
  VALUE rid = Qnil;
  R2TAO_TRY
  {
    PortableServer::POA_var _poa = r2tao_POA_r2t (self);
    CORBA::OctetSeq_var _id = _poa->id ();
    rid = rb_funcall (rb_eval_string ("CORBA::OctetSeq"),
                      new_ID,
                      1,
                      rb_str_new ((char*)_id->get_buffer (), (long)_id->length ()));
  }
  R2TAO_CATCH;
  return rid;
}

//-------------------------------------------------------------------
//  Ruby POAManager functions
//
//===================================================================

PortableServer::POAManager_ptr r2tao_POAManager_r2t(VALUE obj)
{
  CORBA::Object_ptr _obj = r2tao_Object_r2t (obj);
  return PortableServer::POAManager::_narrow (_obj);
}

VALUE r2tao_POAManager_activate(VALUE self)
{
  R2TAO_TRY
  {
    PortableServer::POAManager_var _poa_man = r2tao_POAManager_r2t (self);
    _poa_man->activate ();
  }
  R2TAO_CATCH;
  return Qnil;
}
VALUE r2tao_POAManager_hold_requests(VALUE self, VALUE wait_for_completion)
{
  R2TAO_TRY
  {
    PortableServer::POAManager_var _poa_man = r2tao_POAManager_r2t (self);
    _poa_man->hold_requests (wait_for_completion == Qtrue);
  }
  R2TAO_CATCH;
  return Qnil;
}
VALUE r2tao_POAManager_discard_requests(VALUE self, VALUE wait_for_completion)
{
  R2TAO_TRY
  {
    PortableServer::POAManager_var _poa_man = r2tao_POAManager_r2t (self);
    _poa_man->discard_requests (wait_for_completion == Qtrue);
  }
  R2TAO_CATCH;
  return Qnil;
}
VALUE r2tao_POAManager_deactivate(VALUE self, VALUE etherealize, VALUE wait_for_completion)
{
  R2TAO_TRY
  {
    PortableServer::POAManager_var _poa_man = r2tao_POAManager_r2t (self);
    _poa_man->deactivate (etherealize == Qtrue, wait_for_completion == Qtrue);
  }
  R2TAO_CATCH;
  return Qnil;
}
VALUE r2tao_POAManager_get_state(VALUE self)
{
  R2TAO_TRY
  {
    PortableServer::POAManager_var _poa_man = r2tao_POAManager_r2t (self);
    return ULONG2NUM (static_cast<unsigned long> (_poa_man->get_state ()));
  }
  R2TAO_CATCH;
  return Qnil;
}
VALUE r2tao_POAManager_get_id(VALUE self)
{
  R2TAO_TRY
  {
    PortableServer::POAManager_var _poa_man = r2tao_POAManager_r2t (self);
    return rb_str_new2 (_poa_man->get_id ());
  }
  R2TAO_CATCH;
  return Qnil;
}
VALUE r2tao_POAManager_get_orb(VALUE self)
{
  R2TAO_TRY
  {
    PortableServer::POAManager_var _poa_man = r2tao_POAManager_r2t (self);
    CORBA::ORB_var _orb = _poa_man->_get_orb ();
    return r2tao_ORB_t2r(_orb.in ());
  }
  R2TAO_CATCH;
  return Qnil;
}

//-------------------------------------------------------------------
//  Ruby IORTable functions
//
//===================================================================

class R2taoLocator : public IORTable::Locator
{
public:
  R2taoLocator(VALUE rbloc)
   : IORTable::Locator(), rb_locator_(rbloc) {}
  virtual char * locate (const char * object_key);

protected:
  static VALUE _invoke_implementation(VALUE args);
  
private:
  VALUE     rb_locator_;
};

// invocation helper for rb_protect()
VALUE R2taoLocator::_invoke_implementation(VALUE args)
{
  VALUE rblocator = rb_ary_entry (args, 0);
  VALUE operation = rb_ary_entry (args, 1);
  VALUE opargs = rb_ary_entry (args, 2);
  return rb_apply (rblocator, SYM2ID (operation), opargs);
}

char* R2taoLocator::locate (const char * object_key)
{
  // invoke locator implementation
  VALUE rargs = rb_ary_new2 (1);
  rb_ary_push (rargs, object_key ? rb_str_new2 (object_key) : Qnil);
  VALUE invoke_holder = rb_ary_new2 (3);
  rb_ary_push (invoke_holder, this->rb_locator_);
  rb_ary_push (invoke_holder, ID2SYM (locate_ID));
  rb_ary_push (invoke_holder, rargs);
  int invoke_state = 0;
  VALUE ior = rb_protect (RUBY_INVOKE_FUNC (R2taoLocator::_invoke_implementation),
                          invoke_holder,
                          &invoke_state);
  
  if (invoke_state)
  {
    // handle exception
    VALUE rexc = rb_gv_get ("$!");
    if (rb_obj_is_kind_of(rexc, r2tao_cIORTableNotFoundX) == Qtrue)
    {
      throw ::IORTable::NotFound();
    }
    else if(rb_obj_is_kind_of(rexc, r2tao_cSystemException) == Qtrue)
    {
      VALUE rid = rb_funcall (rexc, rb_intern ("_interface_repository_id"), 0);
      CORBA::SystemException* _exc = TAO::create_system_exception (RSTRING(rid)->ptr);

      _exc->minor (
        static_cast<CORBA::ULong> (NUM2ULONG (rb_iv_get (rexc, "@minor"))));
      _exc->completed (
        static_cast<CORBA::CompletionStatus> (NUM2ULONG (rb_iv_get (rexc, "@completed"))));

      ACE_Auto_Basic_Ptr<CORBA::SystemException> e_ptr(_exc);
      _exc->_raise ();
    }
    else
    {
      rb_eval_string ("STDERR.puts $!.to_s+\"\\n\"+$!.backtrace.join(\"\\n\")");
      throw ::CORBA::UNKNOWN (0, CORBA::COMPLETED_MAYBE);
    }
  }
  
  if (rb_type (ior) != T_STRING)
  { 
    throw CORBA::BAD_PARAM(0, CORBA::COMPLETED_NO); 
  }

  return CORBA::string_dup (RSTRING(ior)->ptr);
}

IORTable::Table_ptr r2tao_IORTable_r2t(VALUE obj)
{
  CORBA::Object_ptr _obj = r2tao_Object_r2t (obj);
  return IORTable::Table::_narrow (_obj);
}

VALUE r2tao_IORTable_bind(VALUE self, VALUE obj_key, VALUE ior)
{
  obj_key = rb_check_convert_type (obj_key, T_STRING, "String", "to_s");
  ior = rb_check_convert_type (ior, T_STRING, "String", "to_s");
  R2TAO_TRY
  {
    IORTable::Table_var _iortbl = r2tao_IORTable_r2t (self);
    _iortbl->bind (RSTRING(obj_key)->ptr, RSTRING(ior)->ptr);
  }
  R2TAO_CATCH;
  return Qnil;
}

VALUE r2tao_IORTable_rebind(VALUE self, VALUE obj_key, VALUE ior)
{
  obj_key = rb_check_convert_type (obj_key, T_STRING, "String", "to_s");
  ior = rb_check_convert_type (ior, T_STRING, "String", "to_s");
  R2TAO_TRY
  {
    IORTable::Table_var _iortbl = r2tao_IORTable_r2t (self);
    _iortbl->rebind (RSTRING(obj_key)->ptr, RSTRING(ior)->ptr);
  }
  R2TAO_CATCH;
  return Qnil;
}

VALUE r2tao_IORTable_unbind(VALUE self, VALUE obj_key)
{
  obj_key = rb_check_convert_type (obj_key, T_STRING, "String", "to_s");
  R2TAO_TRY
  {
    IORTable::Table_var _iortbl = r2tao_IORTable_r2t (self);
    _iortbl->unbind (RSTRING(obj_key)->ptr);
  }
  R2TAO_CATCH;
  return Qnil;
}

VALUE r2tao_IORTable_set_locator(VALUE self, VALUE locator)
{
  r2tao_check_type (locator, r2tao_cIORTableLocator);
  
  // store Ruby Locator instance (keeps reference)
  rb_iv_set (self, "@locator", locator);
  
  R2TAO_TRY
  {
    IORTable::Table_var _iortbl = r2tao_IORTable_r2t (self);
    
    IORTable::Locator_var _locvar = new R2taoLocator(locator);
    
    _iortbl->set_locator (_locvar.in ());
  }
  R2TAO_CATCH;
  return Qnil;
}
