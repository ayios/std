static define runapp ()
{
  variable argv = __pop_list (_NARGS);

  argv = list_to_array (argv, String_Type);

  variable app = qualifier ("argv0");

  ifnot (any (app == _APPS_))
    {
    tostderr (app + ": No such application");
    return;
    }

  variable setid = @Setid_Type;

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

  _for i (0, length (argv) - 1)
    list_append (args, argv[i]);

  smg->reset ();

  loadfrom ("app/" + app, APPSINFO[app].init, app, &on_eval_err;force);

  variable ref = __get_reference (app + "->" + app);
  () = (@ref) (__push_list (args);;setid);

  smg->init ();

  draw (ERR);
}

static define app_atexit (s)
{
  ifnot (s._state & IDLED)
    {
    variable status = waitpid (s.p_.pid, 0);

    s.p_.atexit ();

    ifnot (NULL == s._fd)
      () = close (s._fd);

    variable pid = s.p_.pid;

    assoc_delete_key (APPS[s._appname], string (s.p_.pid));

    variable ind = wherefirst_eq (CONNECTED_PIDS, pid);

    CONNECTED_PIDS[ind] = 0;
    CONNECTED_APPS[ind] = NULL;
    CONNECTED_PIDS = CONNECTED_PIDS[where (CONNECTED_PIDS)];
    CONNECTED_APPS = CONNECTED_APPS[wherenot (_isnull (CONNECTED_APPS))];
    CUR_IND = 0 == CUR_IND
      ? length (CONNECTED_APPS)
        ? length (CONNECTED_APPS) - 1
        : -1
      : CUR_IND - 1;

    _log_ (s._appname + ": exited, EXIT_STATUS: " + string (status.exit_status), LOGERR);

    return;
    }

  _log_ (s._appname + ": is in idled state", LOGERR);
}

private define _get_s_ ()
{
  variable pid = string (CONNECTED_PIDS[CUR_IND]);
  variable app = CONNECTED_APPS[CUR_IND];
  return APPS[app][pid];
}

static define apploop (s)
{
  variable retval;
  variable app;

  forever
    {
    retval = sock->get_int (s._fd);

    ifnot (Integer_Type == typeof (retval))
      {
      _log_ (sprintf ("%s loop: expected Integer_Type, received %S", s._appname, typeof (retval)), LOGERR);
      return; %don't handled, but it should never happen
      }

    if (retval == APP_GET_ALL)
      {
      sock->send_str (s._fd, strjoin (_APPS_, "\n"));
      continue;
      }

    if (retval == APP_GET_CONNECTED)
      {
      sock->send_str (s._fd, __get_con_apps ());
      continue;
      }

    if (retval == GO_ATEXIT)
      {
      s._state &= ~CONNECTED;

      if (1 == length (CONNECTED_APPS))
        {
        app_atexit (s);
        return;
        }

      app_atexit (s);

      s = _get_s_ ();

      __send_reconnect (s);
      continue;
      }

    if (retval == GO_IDLED)
      {
      __set_idled (s);
      return;
      }

    if (retval == APP_CON_NEW)
      {
      app = sock->send_bit_get_str (s._fd, 1);

      __set_idled (s);

      s = __new_app (app);

      ifnot (NULL == s)
        continue;

      s = _get_s_ ();

      __send_reconnect (s);
      continue;
      }

    if (retval == APP_RECON_OTH)
      {
      app = sock->send_bit_get_str (s._fd, 1);

      __set_idled (s);

      s = __reconnect_to_app (app);

      if (NULL == s)
        {
        s = _get_s_ ();

        __send_reconnect (s);
        continue;
        }

      __send_reconnect (s);
      continue;
      }
    }
}

static define addflags (p, s)
{
  p.stderr.file = TEMPDIR + "/" + string (PID) + "Srv" + s._appname + "err";
  p.stderr.wr_flags = ">|";
}

static define init_app (name, dir, argv)
{
  variable s = @App_Type;

  s._state = 0;
  s._appdir = dir;
  s._procfile = dir + "/proc";;
  s._appname = name;
  s.argv = argv;
  s._sockaddr = TEMPDIR + "/" + string (PID) + name + ".sock";

  _log_ ("initing " + s._appname + ", sockaddress: " + s._sockaddr, LOGALL);

  return s;
}

static define getargvenv (p, s, argv)
{
  argv = [SLSH_BIN, p.loadproc, s._procfile, argv];

  variable env = [proc->defenv (), sprintf ("SOCKADDR=%s", s._sockaddr)];

  ifnot (NULL == DISPLAY)
    env = [env, "DISPLAY=" + DISPLAY];

  ifnot (NULL == XAUTHORITY)
    env = [env, "XAUTHORITY=" + XAUTHORITY];

  return argv, env;
}

static define connect_to_child (s)
{
  if (-1 == __connect_to_app (s))
    return;

  apploop (s);
}

static define doproc (s, argv)
{
  variable p, env;

  if (p = proc->init (0, 0, 1;;__qualifiers ()), p == NULL)
    {
    _log_ (s._appname + ": inited failed", LOGERR);
    return -1;
    }

  addflags (p, s);

  (argv, env) = getargvenv (p, s, argv);

  s.p_ = p;

  if (NULL == p.execve (argv, env, 1))
    {
    _log_ (s._appname + ": fork failed", LOGERR);
    return -1;
    }

  _log_ (s._appname  + " pid: " + string (s.p_.pid), LOGNORM);

  return 0;
}
