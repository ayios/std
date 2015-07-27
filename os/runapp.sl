private variable REC_CALLS = 0;

static define runapp ();

static define runapp ()
{
  APP_NEW = NULL;
  APP_CON_OTH = NULL;

  variable argv = __pop_list (_NARGS);

  argv = list_to_array (argv, String_Type);

  variable app = qualifier ("argv0");

  ifnot (any (app == _APPS_))
    {
    tostderr (app + ": No such application");
    return;
    }
 
  variable setid = struct
    {
    setid = 1,
    uid = UID,
    gid = GID,
    user = USER
    };

  variable issu = is_arg ("--su", argv);
  ifnot (NULL == issu)
    {
    setid.uid = 0;
    setid.gid = 0;
    setid.user = "root";
    argv[issu] = NULL;
    argv = argv[wherenot (_isnull (argv))];
    }

  variable args = {};
  variable i;
  variable oldpids = (@__get_reference ("_get_connected_app")) (app);

  _for i (0, length (argv) - 1)
    list_append (args, argv[i]);

  smg->reset ();
 
  loadfrom ("app/" + app, APPSINFO[app].init, app, &on_eval_err;force);
 
  variable ref = __get_reference (app + "->" + app);
  variable exit_code = (@ref) (__push_list (args);;setid);
  
  if (NULL != APP_NEW || NULL != APP_CON_OTH)
    {
    variable newpids = (@__get_reference ("_get_connected_app")) (app);
    _for i (0, length (newpids) - 1)
      {
      variable pid =newpids[i];  
      ifnot (any (pid == oldpids))
        break;
      }

    variable s = APPS[app][pid];
    }
    
  ifnot (NULL == APP_NEW)
    {
    REC_CALLS++;

    runapp (;argv0 = APP_NEW);
    
    s._state &= ~IDLED;
    
    sock->send_int (s._fd, RECONNECT);
 
    _log_ (s._appname + ": reconnected", LOGNORM);

    () = os->apploop (s);

    () = os->app_atexit (s);
    }

  ifnot (NULL == APP_CON_OTH)
    {
    () = (@__get_reference ("_reconnect_app_")) (APP_CON_OTH, 0);
    variable pids = (@__get_reference ("_get_connected_app")) (s._appname);
    if (length (pids))
      if (any (pid == pids))
        {
        s._state &= ~IDLED;
    
        sock->send_int (s._fd, RECONNECT);
 
        _log_ (s._appname + ": reconnected", LOGNORM);

        () = os->apploop (s);

        () = os->app_atexit (s);
        }
    }

  if (REC_CALLS)
    {
    REC_CALLS--;
    return;
    }

  smg->init ();
 
  draw (ERR);
}
