define ved ()
{
  variable argv = __pop_list (_NARGS);

  argv = list_to_array (argv, String_Type);

  _log_ ("running ved", LOGALL);

  variable s = os->init_app ("ved", path_dirname (__FILE__), argv);

  _log_ ("sockaddress: " + s._sockaddr, LOGALL);

  if (-1 == os->doproc (s, argv;;__qualifiers ()))
    {
    _log_ ("ved: fork failed", LOGERR);
    return;
    }
 
  _log_ ("ved pid: " + string (s.p_.pid), LOGNORM);

  os->connect_to_child (s);

  return os->app_atexit (s);
}
