define _exit_me_ (argv)
{
  variable rl = qualifier ("rl");

  ifnot (NULL == rl)
    rline->writehistory (rl.history, rl.histfile);
  
  variable apps = assoc_get_keys (APPS);
  variable i;

  _for i (0, length (apps) - 1)
    {
    variable app = apps[i];
    variable pids = assoc_get_keys (APPS[app]);
    variable ii;
    _for ii (0, length (pids) - 1)
      {
      variable pid = pids[ii];
      variable s = APPS[app][pid];

      () = sock->send_int (s._fd, 0);
      s._status = s._status & ~IDLED;
      () = os->app_atexit (s);
      }
    }

  exit_me (0);
}

private define reconnect_toapp (argv)
{
  if (1 == length (argv))
    return;

  variable app = argv[1];

  ifnot (any (app == _APPS_))
    return;

  variable pids = assoc_get_keys (APPS[app]);

  ifnot (length (pids))
    return;

  variable s = APPS[app][pids[0]];
  
  s._state = s._state & ~IDLED;

  smg->reset ();

  sock->send_int (s._fd, RECONNECT);
  
  _log_ (s._appname + ": reconnected", LOGNORM);

  os->apploop (s);

  () = os->app_atexit (s);

  smg->init ();

  osdraw (ERR);
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

define initrline ()
{
  variable rl = rline->init (&init_commands;
    histfile = HISTDIR + "/" + string (OSUID) + "oshistory",
    on_lang = &toplinedr,
    on_lang_args = " -- OS CONSOLE --");
 
  return rl;
}
