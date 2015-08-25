define __get_connected_app (app)
{
  ifnot (any (app == _APPS_))
    return String_Type[0];

  variable pids = assoc_get_keys (APPS[app]);

  return pids;
}

define __reconnect_to_app (appl)
{
  variable pid = NULL;

  variable args = strtok (appl, "::");
 
  if (1 == length (args))
    return NULL;

  variable app = args[0];
 
  if (1 < length (args))
    pid = args[1];

  variable pids = __get_connected_app (app);

  ifnot (length (pids))
    return NULL;

  ifnot (NULL == pid)
    ifnot (any (pid == pids))
      return NULL;

  variable s = APPS[app][pid == NULL ? pids[0] : pid];
 
  s._state &= ~IDLED;

  return s;
}

define __set_idled (s)
{
  s._state |= IDLED;
  _log_ (s._appname + ": is in idled state", LOGERR);
}

define __send_reconnect (s)
{
  s._state &= ~IDLED;

  sock->send_int (s._fd, RECONNECT);
 
  _log_ (s._appname + ": with pid :" + string (s.p_.pid) + " reconnected", LOGNORM);
}

define __get_all_connected_apps ()
{
  variable i;
  variable ii;
  variable apps = {};

  _for i (0, length (_APPS_) - 1)
    {
    variable app = _APPS_[i];
    variable pids = __get_connected_app (app);
    if (length (pids))
      _for ii (0, length (pids) - 1)
        list_append (apps, [app, pids[ii]]);
    }
 
  return list_to_array (apps, Array_Type);
}

define __get_con_apps ()
{
  variable pids = __get_all_connected_apps ();
  variable str = "";
  variable i;
  variable pid;

  _for i (0, length (pids) - 1)
    {
    pid = pids[i];
    str += sprintf ("%s::%d\n", pid[0], APPS[pid[0]][pid[1]].p_.pid);
    }

  return str;
}

define __connect_to_app (s)
{
  while (-1 == access (TEMPDIR + "/_" + s._appname + "_.init", F_OK))
    {
    ifnot (access (TEMPDIR + "/_" + s._appname + "_.initerr", F_OK))
      {
      () = remove (TEMPDIR + "/_" + s._appname + "_.initerr");

      s.p_.atexit ();

      () = kill (s.p_.pid, SIGKILL);
 
      _log_ (s._appname +": evaluation err", LOGERR);
 
      array_map (&tostderr, readfile (s.p_.stderr.file));
 
      return -1;
      }
    }

  s._fd = s.p_.connect (s._sockaddr);

  if (NULL == s._fd)
    {
    s.p_.atexit ();

    () = kill (s.p_.pid, SIGKILL);
 
    _log_ (s._appname +": failed to connect to socket", LOGERR);
 
    return -1;
    }
 
  s._state |= CONNECTED;
 
  _log_ (s._appname + ": connected to socket", LOGNORM);

  APPS[s._appname][string (s.p_.pid)] = s;

  CUR_IND++;
  CONNECTED_APPS = [CONNECTED_APPS, s._appname];
  CONNECTED_PIDS = [CONNECTED_PIDS, s.p_.pid];
 
  return 0;
}

define __new_app (app)
{
  variable pids;

  ifnot (any (app == _APPS_))
    {
    tostderr (app + ": No such application");
    return NULL;
    }
 
  variable setid = @Setid_Type;

  loadfrom ("app/" + app, APPSINFO[app].init, app, &on_eval_err;force);
 
  variable ref = __get_reference (app + "->" + app);
  variable s = (@ref) (;;struct {@setid, dont_connect});
 
  if (NULL == s)
    return NULL;

  if (-1 == __connect_to_app (s))
    return NULL;

  return s;
}
