
versioned_so=1
threads=1
ssl=0
exceptions=1
optimize=1
debug=0
fl_reactor=0
tk_reactor=0
boost = 0
no_hidden_visibility=1
include $(ACE_ROOT)/include/makeinclude/platform_linux.GNU
CCFLAGS += -Wwrite-strings -Wcast-align
CPPFLAGS += -DACE_USE_RCSID=0
  
