define _exit_me_ (argv)
{
  variable rl = qualifier ("rl");

  ifnot (NULL == rl)
    rline->writehistory (rl.history, rl.histfile);
 
  variable i;

  _for i (0, length (_APPS_) - 1)
    {
    variable app = _APPS_[i];
    variable pids = assoc_get_keys (APPS[app]);
    variable ii;
    _for ii (0, length (pids) - 1)
      {
      variable pid = pids[ii];
      variable s = APPS[app][pid];

      sock->send_int (s._fd, 0);
      s._state &= ~IDLED;
      () = os->app_atexit (s);
      }
    }

  exit_me (0);
}

define _get_connected_app (app)
{
  ifnot (any (app == _APPS_))
    return String_Type[0];

  variable pids = assoc_get_keys (APPS[app]);

  return pids;
}

define _get_all_connected_apps ()
{
  variable i;
  variable ii;
  variable apps = {};

  _for i (0, length (_APPS_) - 1)
    {
    variable app = _APPS_[i];
    variable pids = _get_connected_app (app);
    if (length (pids))
      _for ii (0, length (pids) - 1)
        list_append (apps, [app, pids[ii]]);
    }
 
  return list_to_array (apps, Array_Type);
}

define _reconnect_app_ (appl, reset)
{
  variable pid = NULL;
 
  variable args = strtok (appl, "::");
 
  variable app = args[0];
 
  if (1 < length (args))
    pid = args[1];

  variable pids = _get_connected_app (app);

  ifnot (length (pids))
    return -1;

  ifnot (NULL == pid)
    ifnot (any (pid == pids))
      return -1;

  variable s = APPS[app][pid == NULL ? pids[0] : pid];
 
  s._state &= ~IDLED;

  if (reset)
    smg->reset ();

  sock->send_int (s._fd, RECONNECT);
 
  _log_ (s._appname + ": reconnected", LOGNORM);

  () = os->apploop (s);

  () = os->app_atexit (s);

  return 0;
}

private define reconnect_toapp (argv)
{
  if (1 == length (argv))
    return;
  
  if (-1 == _reconnect_app_ (argv[1]), 1)
    return;

  smg->init ();

  draw (ERR);
}

define init_commands ()
{
  variable
    i,
    a = Assoc_Type[Argvlist_Type, @Argvlist_Type],
    apps = assoc_get_keys (APPS);

  _for i (0, length (apps) - 1)
    {
    variable app = apps[i];;

    a[app] = @Argvlist_Type;
    a[app].func = &os->runapp;
    a[app].type = "Func_Type";
    }

  a["q"] = @Argvlist_Type;
  a["q"].func = &_exit_me_;

  a["reconnect"] = @Argvlist_Type;
  a["reconnect"].func = &reconnect_toapp;

  a["eval"] = @Argvlist_Type;
  a["eval"].func = &_eval_;
 
  a["messages"] = @Argvlist_Type;
  a["messages"].func = &_messages_;

  return a;
}

private define tabhook (s)
{
  ifnot (s._ind)
    return -1;

  ifnot (any (s.argv[0] == ["reconnect"]))
    return -1;
 
  variable pids = _get_all_connected_apps ();
 
  ifnot (length (pids))
    return -1;
 
  variable i;
  variable arg;
  variable args = String_Type[0];

  _for i (0, length (pids) - 1)
    {
    arg = pids[i];
    args = [args, arg[0] +  "::" + string (APPS[arg[0]][arg[1]].p_.pid) + " void " +
    strjoin (APPS[arg[0]][arg[1]].argv, " ") + " connect to application"];
    }

  return rline->argroutine (s;args = args, accept_ws);
}

define initrline ()
{
  variable rl = rline->init (&init_commands;
    histfile = HISTDIR + "/" + string (OSUID) + "oshistory",
    tabhook = &tabhook,
    on_lang = &toplinedr,
    on_lang_args = " -- OS CONSOLE --");
 
  return rl;
}
