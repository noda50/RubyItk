
ACE_FILES  = [
    'ACE',
    'TAO',
    'TAO_TypeCodeFactory',
    'TAO_IFR_Client',
    'TAO_DynamicInterface',
    'TAO_Messaging',
    'TAO_PI',
    'TAO_CodecFactory',
    'TAO_Codeset',
    'TAO_DynamicAny',
    'TAO_Valuetype',
    'TAO_PortableServer',
    'TAO_AnyTypeCode',
    'TAO_BiDirGIOP',
    'TAO_IORTable'
]

if get_config('with-ssl')=='yes'
  ACE_FILES << 'ACE_SSL'
  ACE_FILES << 'TAO_Security'
  ACE_FILES << 'TAO_SSLIOP'
end
