private define _exit_me_ (argv)
{
  variable i;
  variable s;
  variable ii;
  variable pid;
  variable app;
  variable pids;
  variable rl = qualifier ("rl");

  ifnot (NULL == rl)
    rline->writehistory (rl.history, rl.histfile);

  _for i (0, length (_APPS_) - 1)
    {
    app = _APPS_[i];
    pids = assoc_get_keys (APPS[app]);
    _for ii (0, length (pids) - 1)
      {
      pid = pids[ii];
      s = APPS[app][pid];

      sock->send_int (s._fd, 0);
      s._state &= ~IDLED;
      os->app_atexit (s);
      }
    }

  exit_me (0);
}

private define reconnect_toapp (argv)
{
  if (1 == length (argv))
    return;
  
  variable s = __reconnect_to_app (argv[1]);

  if (NULL == s)
    return;

  smg->reset ();

  __send_reconnect (s);

  os->apploop (s);

  smg->init ();

  draw (ERR);
}

private define init_commands ()
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
 
  variable pids = __get_all_connected_apps ();
 
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
