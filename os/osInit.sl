typedef struct
  {
  _sockaddr,
  _fd,
  _state,
  atexit,
  p_,
  uid,
  gid,
  _procfile,
  _appname,
  _appdir,
  argv,
  } App_Type;

typedef struct
  {
  init,
  help,
  info,
  } AppInfo_Type;

variable Setid_Type = struct
  {
  setid = 1,
  uid = UID,
  gid = GID,
  user = USER
  };

loadfrom ("proc", "envs", 1, &on_eval_err);
loadfrom ("sock", "sockInit", NULL, &on_eval_err);
loadfrom ("wind", "ostopline", NULL, &on_eval_err);
loadfrom ("stdio", "appendstr", NULL, &on_eval_err);
loadfrom ("api", "eval", NULL, &on_eval_err);
loadfrom ("api", "clientfuncs", NULL, &on_eval_err);

public variable RLINE;
public variable CONNECTED_APPS = String_Type[0];
public variable CONNECTED_PIDS = Integer_Type[0];
public variable CUR_IND = -1;
public variable CONNECTED = 0x1;
public variable IDLED = 0x2;
public variable GO_ATEXIT = 0x0C8;
public variable GO_IDLED =  0x012c;
public variable RECONNECT = 0x0190;
public variable APP_CON_NEW = 0x1f4;
public variable APP_RECON_OTH = 0x258;
public variable APP_GET_ALL = 0x2bc;
public variable APP_GET_CONNECTED = 0x320;
public variable APPS = Assoc_Type[Assoc_Type];
public variable APPSINFO = Assoc_Type[AppInfo_Type];
public variable _APPS_;

define _log_ (str, logtype)
{
  if (VERBOSITY & logtype)
    tostderr (str);
}

define __messages (argv)
{
  viewfile (ERR, "OS", NULL, NULL);
}

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

loadfrom ("os", "appinit", 1, &on_eval_err);

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
  a["eval"].func = &__eval;
  a["eval"].type = "Func_Type";

  a["messages"] = @Argvlist_Type;
  a["messages"].func = &__messages;

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
    on_lang_args = {"-- OS --"});

  return rl;
}

private define  _loop_ ()
{
  variable status = 0;
  try
  forever
    {
    rline->set (RLINE);
    rline->readline (RLINE);
    topline (" -- OS CONSOLE --" + " (depth " + string (_stkdepth ()) + ")");
    }
  catch AnyError:
    status = 1;

  if (status)
    throw RunTimeError, " ", __get_exception_info ();
}

define osloop ()
{
  try
    _loop_ ();
  catch RunTimeError:
    {
    array_map (&tostderr, err__.exc_to_array (__get_exception_info.object));
    smg->init ();
    draw (ERR); % new func: draw_and_take_some_action
    _loop_ ();
    }
}

private define _apptable_ ()
{
  variable i;
  variable ii;
  variable app;
  variable dir;
  variable apps;
  variable dirs = [USRDIR, STDDIR, LCLDIR];

  _for i (0, length (dirs) - 1)
    {
    dir = dirs[i];
    apps = listdir (dir + "/app");
    if (NULL == apps || (NULL != apps && 0 == length (apps)))
      continue;

    apps = apps[where (array_map (Integer_Type, &_isdirectory,
      array_map (String_Type, &path_concat, dir + "/app/", apps)))];

    _for ii (0, length (apps) - 1)
      {
      app = apps[ii];
      if (-1 == access (dir + "/app/" + app + "/" + app + "Init.sl", F_OK)
        &&-1 == access (dir + "/" + app + "/" + app + "Init.slc", F_OK))
        continue;

      APPSINFO[app] = @AppInfo_Type;

      APPSINFO[app].init = app + "Init";

      ifnot (access (dir + "/app/" + app + "help.txt", F_OK))
        APPSINFO[app].help = dir + "/app/" + app + "/help.txt";

      ifnot (access (dir + "/app/" + app + "info.txt", F_OK))
        APPSINFO[app].info = dir + "/app/" + app + "/info.txt";

      APPS[app] = Assoc_Type[App_Type];
      }
    }
}

(VED_RLINE, VED_MAXFRAMES, VED_ISONLYPAGER) = 0, 1, 1;
ERR = init_ftype ("txt");
txt_settype (ERR, STDERR, VED_ROWS, NULL);
__vsetbuf (ERR._abspath);
ERR._fd = STDERRFD;

_apptable_ ();

_APPS_ = assoc_get_keys (APPS);

RLINE = initrline ();
