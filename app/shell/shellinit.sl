define shell ()
{
  variable argv = __pop_list (_NARGS);

  argv = list_to_array (argv, String_Type);

  _log_ ("running shell", LOGALL);

  variable s = os->init_app ("shell", path_dirname (__FILE__));

  _log_ ("sockaddress: " + s._sockaddr, LOGALL);

  if (-1 == os->doproc (s, argv;;__qualifiers ()))
    {
    _log_ ("shell: fork failed", LOGERR);
    return -1;
    }
  
  _log_ ("shell pid: " + string (s.p_.pid), LOGNORM);

  os->connect_to_child (s);

  return os->app_atexit (s);
}
