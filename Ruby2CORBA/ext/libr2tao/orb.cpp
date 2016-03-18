/*--------------------------------------------------------------------
# orb.cpp - R2TAO CORBA ORB support
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

#include "orb.h"
#include "exception.h"
#include "object.h"
#include "typecode.h"
#include "tao/corba.h"
#include "tao/ORB_Core.h"
#include "ace/Reactor.h"
#include "ace/Signal.h"
#include "ace/Sig_Handler.h"

#define RUBY_INVOKE_FUNC RUBY_ALLOC_FUNC

R2TAO_EXPORT VALUE r2tao_cORB = 0;
VALUE r2tao_nsPolicy = 0;

/* ruby */
static VALUE r2tao_ORB_hash(VALUE self);
static VALUE r2tao_ORB_eql(VALUE self, VALUE that);

/* orb.h */
static VALUE rCORBA_ORB_init(int _argc, VALUE *_argv0, VALUE klass);
static VALUE rCORBA_ORB_object_to_string(VALUE self, VALUE obj);
static VALUE rCORBA_ORB_string_to_object(VALUE self, VALUE str);
static VALUE rCORBA_ORB_get_default_context(VALUE self);
static VALUE rCORBA_ORB_get_service_information(VALUE self, VALUE service_type);
static VALUE rCORBA_ORB_get_current(VALUE self);
static VALUE rCORBA_ORB_list_initial_services(VALUE self);
static VALUE rCORBA_ORB_resolve_initial_references(VALUE self, VALUE identifier);
static VALUE rCORBA_ORB_register_initial_reference(VALUE self, VALUE identifier, VALUE obj);

static VALUE rCORBA_ORB_work_pending(int _argc, VALUE *_argv, VALUE self);
static VALUE rCORBA_ORB_perform_work(int _argc, VALUE *_argv, VALUE self);
static VALUE rCORBA_ORB_run(int _argc, VALUE *_argv, VALUE self);
static VALUE rCORBA_ORB_shutdown(int _argc, VALUE *_argv, VALUE self);
static VALUE rCORBA_ORB_destroy(VALUE self);

class R2CSigGuard : public ACE_Event_Handler
{
public:
  R2CSigGuard(CORBA::ORB_ptr orb);
  virtual ~R2CSigGuard();

  virtual int handle_signal (int signum,
                             siginfo_t * = 0,
                             ucontext_t * = 0);

protected:
  static VALUE signal_handler(VALUE args);

private:
  class Signal : public ACE_Event_Handler
  {
  public:
    Signal(int signum) : m_signum (signum) {}
    virtual ~Signal() {}

    virtual int handle_exception (ACE_HANDLE fd = ACE_INVALID_HANDLE);

  private:
    int m_signum;
  };

  VALUE           m_signums;
  ACE_SIGACTION  *m_sa;
  CORBA::ORB_var  m_orb;
  ACE_Sig_Handler m_sig_handler;
#if defined (WIN32)
  R2CSigGuard*    m_prev_guard;

public:
  static R2CSigGuard* c_sig_guard;
#endif
};

#if defined (WIN32)
R2CSigGuard* R2CSigGuard::c_sig_guard = 0;

BOOL WINAPI CtrlHandlerRoutine (DWORD dwCtrlType)
{
    if (R2CSigGuard::c_sig_guard)
    {
      R2CSigGuard::c_sig_guard->handle_signal (SIGINT);
    }
    return TRUE;
}
#endif

static void
_orb_free(void *ptr)
{
  CORBA::release ((CORBA::ORB_ptr)ptr);
}

R2TAO_EXPORT VALUE
r2tao_ORB_t2r(CORBA::ORB_ptr obj)
{
  VALUE ret;
  CORBA::ORB_ptr _orb;

  _orb = CORBA::ORB::_duplicate(obj);
  ret = Data_Wrap_Struct(r2tao_cORB, 0, _orb_free, _orb);

  return ret;
}

R2TAO_EXPORT CORBA::ORB_ptr
r2tao_ORB_r2t(VALUE obj)
{
  CORBA::ORB_ptr ret;

  r2tao_check_type(obj, r2tao_cORB);
  Data_Get_Struct(obj, CORBA::ORB, ret);
  return ret;
}

void
r2tao_Init_ORB()
{
  VALUE k;
  VALUE nsCORBA_ORB;

  if (r2tao_cORB) return;
  r2tao_Init_Object();

  nsCORBA_ORB = rb_eval_string("::R2CORBA::CORBA::Portable::ORB");
  k = r2tao_cORB =
    rb_define_class_under (r2tao_nsCORBA, "ORB", rb_cObject);
  rb_include_module (r2tao_cORB, nsCORBA_ORB);

  rb_define_method(k, "==", RUBY_METHOD_FUNC(r2tao_ORB_eql), 1);
  rb_define_method(k, "hash", RUBY_METHOD_FUNC(r2tao_ORB_hash), 0);
  rb_define_method(k, "eql?", RUBY_METHOD_FUNC(r2tao_ORB_eql), 1);

  rb_define_singleton_method(k, "init", RUBY_METHOD_FUNC(rCORBA_ORB_init), -1);

#define DEF_METHOD(NAME, NUM)\
  rb_define_method(k, #NAME, RUBY_METHOD_FUNC( rCORBA_ORB_ ## NAME ), NUM);

  DEF_METHOD(object_to_string, 1);
  DEF_METHOD(string_to_object, 1);
  DEF_METHOD(get_default_context, 0);
  DEF_METHOD(get_service_information, 1);
  DEF_METHOD(get_current, 0);
  DEF_METHOD(list_initial_services, 0);
  DEF_METHOD(resolve_initial_references, 1);
  DEF_METHOD(register_initial_reference, 2);
  DEF_METHOD(work_pending, -1);
  DEF_METHOD(perform_work, -1);
  DEF_METHOD(shutdown, -1);
  DEF_METHOD(run, -1);
  DEF_METHOD(destroy, 0);
#undef DEF_METHOD

#if defined (WIN32)
  if (!::SetConsoleCtrlHandler(CtrlHandlerRoutine, TRUE))
  {
    ACE_DEBUG ((LM_ERROR, ACE_TEXT ("Failed to set Console Ctrl handler!\n")));
  }
#endif
}

static
VALUE r2tao_ORB_hash(VALUE self)
{
  return ULONG2NUM((unsigned long)self);
}

static
VALUE r2tao_ORB_eql(VALUE self, VALUE _other)
{
  CORBA::ORB_ptr other, obj;

  obj = r2tao_ORB_r2t (self);
  r2tao_check_type (_other, r2tao_cORB);
  other = r2tao_ORB_r2t (_other);

  if (obj == other)
    return Qtrue;
  else
    return Qfalse;
}

static
VALUE rCORBA_ORB_init(int _argc, VALUE *_argv, VALUE /*klass*/) {
  VALUE v0,v1, args0, id0;
  char *id;
  int argc;
  char **argv;
  int i;
  CORBA::ORB_var orb;

  rb_scan_args(_argc, _argv, "02", &v0, &v1);

  args0 = Qnil;
  id0 = Qnil;
  if (NIL_P(v0))  /* ORB.init() */
  {
    ;
  }
  else if (NIL_P(v1))
  {
    switch (rb_type(v0))
    {
      case T_STRING: /* ORB.init(String orb_identifier) */
        id0 = v0;
        break;
      case T_ARRAY: /* ORB.init(arg, arg, ...) */
        args0 = v0;
        break;
      default:
        rb_raise(rb_eTypeError, "invalid argument type.");
        break;
    }
  }
  else  /* ORB.init(args, orb_identifier) */
  {
    Check_Type(v0, T_ARRAY);
    Check_Type(v1, T_STRING);

    args0 = v0;
    id0 = v1;
  }

  if (NIL_P(id0))
  {
    id = 0;
  }
  else
  {
    id = STR2CSTR(id0);
  }

  if (NIL_P(args0))
  {
    argv = &(RSTRING(rb_argv0)->ptr); /* rb_argv0 is program name */
    argc = 1;
  }
  else
  {
    argc = RARRAY(args0)->len + 1;
    argv = (char**) malloc(argc * sizeof(char*));
    argv[0] = (RSTRING(rb_argv0)->ptr); /* rb_argv0 is program name */
    for (i=1; i<argc; i++)
    {
      VALUE av = RARRAY(args0)->ptr[i-1];
      av = rb_check_convert_type(av, T_STRING, "String", "to_s");
      argv[i] = StringValueCStr(av);
    }
  }

  R2TAO_TRY
  {
    orb = CORBA::ORB_init(argc, argv, id);
  }
  R2TAO_CATCH;

  return r2tao_ORB_t2r(orb.in ());
}

static
VALUE rCORBA_ORB_object_to_string(VALUE self, VALUE _obj)
{
  CORBA::Object_ptr obj;
  char *str=0;
  CORBA::ORB_ptr orb;

  orb = r2tao_ORB_r2t (self);
  obj = r2tao_Object_r2t (_obj);

  if (obj->_is_local ())
  {
    rb_raise (r2tao_cMARSHAL, "local object");
  }

  R2TAO_TRY
  {
    str = orb->object_to_string (obj);
  }
  R2TAO_CATCH;

  return rb_str_new2(str);
}

static
VALUE rCORBA_ORB_string_to_object(VALUE self, VALUE _str)
{
  CORBA::Object_var obj;
  char *str=0;
  CORBA::ORB_ptr orb;

  orb = r2tao_ORB_r2t (self);
  Check_Type(_str, T_STRING);
  str = RSTRING(_str)->ptr;

  R2TAO_TRY
  {
    obj = orb->string_to_object (str);
  }
  R2TAO_CATCH;

  return r2tao_Object_t2r(obj.in ());
}

static
VALUE rCORBA_ORB_get_default_context(VALUE /*self*/)
{
  X_CORBA(NO_IMPLEMENT);
  return Qnil;
}

static
VALUE rCORBA_ORB_get_service_information(VALUE /*self*/, VALUE /*service_type*/)
{
  X_CORBA(NO_IMPLEMENT);
  return Qnil;
}

static
VALUE rCORBA_ORB_get_current(VALUE /*self*/)
{
  X_CORBA(NO_IMPLEMENT);
  return Qnil;
}

static
VALUE rCORBA_ORB_list_initial_services(VALUE self)
{
  CORBA::ULong i;
  VALUE ary;
  CORBA::ORB::ObjectIdList_var list;
  CORBA::ORB_ptr orb;

  orb = r2tao_ORB_r2t (self);

  R2TAO_TRY
  {
    list = orb->orb_core ()->list_initial_references ();
  }
  R2TAO_CATCH;

  ary = rb_ary_new2(list->length ());
  for (i=0; i<list->length (); i++)
  {
    char const * id = list[i];
    rb_ary_push (ary, rb_str_new2 (id));
  }

  return ary;
}

static
VALUE rCORBA_ORB_resolve_initial_references(VALUE self, VALUE _id)
{
  CORBA::Object_var obj;
  char *id;
  CORBA::ORB_ptr orb;

  orb = r2tao_ORB_r2t (self);

  Check_Type(_id, T_STRING);
  id = RSTRING(_id)->ptr;

  R2TAO_TRY
  {
    obj = orb->resolve_initial_references(id);
  }
  R2TAO_CATCH;

  return r2tao_Object_t2r (obj.in ());
}

static
VALUE rCORBA_ORB_register_initial_reference(VALUE self, VALUE _id, VALUE _obj)
{
  CORBA::Object_var obj;
  char *id;
  CORBA::ORB_ptr orb;

  orb = r2tao_ORB_r2t (self);

  Check_Type(_id, T_STRING);
  id = RSTRING(_id)->ptr;
  obj = r2tao_Object_r2t(_obj);

  R2TAO_TRY
  {
    orb->register_initial_reference(id, obj.in ());
  }
  R2TAO_CATCH;

  return Qnil;
}

static
VALUE rCORBA_ORB_run(int _argc, VALUE *_argv, VALUE self)
{
  CORBA::ORB_ptr orb;
  VALUE rtimeout = Qnil;
  ACE_Time_Value timeout;
  double tmleft=0.0;

  rb_scan_args(_argc, _argv, "01", &rtimeout);
  if (rtimeout != Qnil)
  {
    if (rb_type (rtimeout) == T_FLOAT)
    {
      timeout.set (RFLOAT (rtimeout)->value);
    }
    else
    {
      unsigned long sec = NUM2ULONG (rtimeout);
      timeout.set (static_cast<time_t> (sec));
    }
    // convert to ACE_Time_Value
  }

  orb = r2tao_ORB_r2t (self);

  R2TAO_TRY
  {
    R2CSigGuard sg(orb);

    if (rtimeout == Qnil)
      orb->run ();
    else
    {
      orb->run (timeout);
      tmleft = (double)timeout.usec ();
      tmleft /= 1000000;
      tmleft += timeout.sec ();
    }
  }
  R2TAO_CATCH;

  return rtimeout == Qnil ? Qnil : rb_float_new (tmleft);
}

static
VALUE rCORBA_ORB_work_pending(int _argc, VALUE *_argv, VALUE self)
{
  CORBA::ORB_ptr orb;
  VALUE rtimeout = Qnil;
  ACE_Time_Value timeout;
  double tmleft=0.0;

  rb_scan_args(_argc, _argv, "01", &rtimeout);
  if (rtimeout != Qnil)
  {
    if (rb_type (rtimeout) == T_FLOAT)
    {
      timeout.set (RFLOAT (rtimeout)->value);
    }
    else
    {
      unsigned long sec = NUM2ULONG (rtimeout);
      timeout.set (static_cast<time_t> (sec));
    }
    // convert to ACE_Time_Value
  }

  orb = r2tao_ORB_r2t (self);

  CORBA::Boolean _rc = false;

  R2TAO_TRY
  {
    R2CSigGuard sg(orb);

    if (rtimeout == Qnil)
      _rc = orb->work_pending ();
    else
    {
      _rc = orb->work_pending (timeout);
      tmleft = (double)timeout.usec ();
      tmleft /= 1000000;
      tmleft += timeout.sec ();
    }
  }
  R2TAO_CATCH;

  if (rtimeout == Qnil)
  {
    return _rc ? Qtrue : Qfalse;
  }
  else
  {
    VALUE rcarr = rb_ary_new2 (2);
    rb_ary_push (rcarr, _rc ? Qtrue : Qfalse);
    rb_ary_push (rcarr, rb_float_new (tmleft));
    return rcarr;
  }
}

static
VALUE rCORBA_ORB_perform_work(int _argc, VALUE *_argv, VALUE self)
{
  CORBA::ORB_ptr orb;
  VALUE rtimeout = Qnil;
  ACE_Time_Value timeout;
  double tmleft=0.0;

  rb_scan_args(_argc, _argv, "01", &rtimeout);
  if (rtimeout != Qnil)
  {
    if (rb_type (rtimeout) == T_FLOAT)
    {
      timeout.set (RFLOAT (rtimeout)->value);
    }
    else
    {
      unsigned long sec = NUM2ULONG (rtimeout);
      timeout.set (static_cast<time_t> (sec));
    }
    // convert to ACE_Time_Value
  }

  orb = r2tao_ORB_r2t (self);

  R2TAO_TRY
  {
    R2CSigGuard sg(orb);

    if (rtimeout == Qnil)
      orb->perform_work ();
    else
    {
      orb->perform_work (timeout);
      tmleft = (double)timeout.usec ();
      tmleft /= 1000000;
      tmleft += timeout.sec ();
    }
  }
  R2TAO_CATCH;

  return rtimeout == Qnil ? Qnil : rb_float_new (tmleft);
}

static
VALUE rCORBA_ORB_shutdown(int _argc, VALUE *_argv, VALUE self)
{
  CORBA::ORB_ptr orb;
  VALUE rwait;
  bool wait = false;

  rb_scan_args(_argc, _argv, "01", &rwait);
  if (rwait == Qtrue)
    wait = true;

  orb = r2tao_ORB_r2t (self);

  R2TAO_TRY
  {
    R2CSigGuard sg(orb);

    orb->shutdown (wait);
  }
  R2TAO_CATCH;

  return Qnil;
}

static
VALUE rCORBA_ORB_destroy(VALUE self)
{
  CORBA::ORB_ptr orb;
  orb = r2tao_ORB_r2t (self);
  R2TAO_TRY
  {
    orb->destroy ();
  }
  R2TAO_CATCH;

  return Qnil;
}

R2CSigGuard::R2CSigGuard(CORBA::ORB_ptr orb)
  : m_orb (CORBA::ORB::_duplicate (orb))
{
  // get array of signal numbers known to Ruby
  m_signums = rb_funcall (r2tao_nsCORBA, rb_intern("signal_numbers"), 0);
  // signum count
  int nsig = RARRAY (m_signums)->len;
  // backup storage space
  m_sa = new ACE_SIGACTION[nsig];

  // initialize sigaction to set all signals to default (recording current handlers)
  ACE_SIGACTION sa_;
  sa_.sa_handler = SIG_DFL;
  ACE_OS::sigemptyset (&sa_.sa_mask);
  sa_.sa_flags = 0;

  // reset and backup all current signal handlers
  for (int i=0; i<nsig ;++i)
  {
    int signum = NUM2INT (rb_ary_entry (m_signums, i));
    ACE_OS::sigaction (signum, &sa_, &m_sa[i]);
  }

  // get array with signal numbers to handle (not DEFAULT)
  VALUE signum_arr = rb_funcall (r2tao_nsCORBA, rb_intern("handled_signals"), 0);
  // signum count
  nsig = RARRAY (signum_arr)->len;
  // set signal handler for handled signals
  bool fINT = false;
  for (int i=0; i<nsig ;++i)
  {
    int signum = NUM2INT (rb_ary_entry (signum_arr, i));
    fINT = fINT || (signum == SIGINT);
    m_sig_handler.register_handler (signum, this);
  }

#if defined (WIN32)
  m_prev_guard = c_sig_guard;
  c_sig_guard =  fINT ? this : 0;
#endif
}

R2CSigGuard::~R2CSigGuard()
{
#if defined (WIN32)
  c_sig_guard = m_prev_guard;
#endif

  // invalidate ORB
  m_orb = CORBA::ORB::_nil ();

  // signum count
  int nsig = RARRAY (m_signums)->len;
  // restore signal handlers
  for (int i=0; i<nsig ;++i)
  {
    int signum = NUM2INT (rb_ary_entry (m_signums, i));
    ACE_OS::sigaction (signum, &m_sa[i], 0);
  }
  // clean up
  delete m_sa;
  m_sa = 0;
  m_signums = 0;
}

int R2CSigGuard::handle_signal (int signum,
                                siginfo_t *,
                                ucontext_t *)
{
  if (!CORBA::is_nil (m_orb))
  {
    // do not handle signal here but reroute as notification to ORB reactor
    m_orb->orb_core ()->reactor ()->notify (new Signal (signum));
  }
  return 0;
}

VALUE R2CSigGuard::signal_handler(VALUE args)
{
  return rb_apply (r2tao_nsCORBA, rb_intern("handle_signal"), args);
}

int R2CSigGuard::Signal::handle_exception (ACE_HANDLE)
{
  VALUE rargs = rb_ary_new2 (1);
  rb_ary_push (rargs, INT2NUM(m_signum));
  int invoke_state = 0;
  rb_protect (RUBY_INVOKE_FUNC (R2CSigGuard::signal_handler),
              rargs,
              &invoke_state);
  if (invoke_state)
  {
    rb_eval_string ("STDERR.puts $!.to_s+\"\\n\"+$!.backtrace.join(\"\\n\")");
  }

  return 0;
}

// end of orb.cpp
