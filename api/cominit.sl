loadfrom ("api", "eval", NULL, &on_eval_err);
private variable issmg = 0;

variable redirexists = NULL;
variable licom = 0;
variable icom = 0;
variable iarg;
variable SHELLLASTEXITSTATUS = 0;
variable RDFIFO = TEMPDIR + "/" + string (PID) +  "_SRV_FIFO.fifo";
variable WRFIFO = TEMPDIR + "/" + string (PID) +  "_CLNT_FIFO.fifo";

ifnot (access (RDFIFO, F_OK))
  if (-1 == remove (RDFIFO))
    on_eval_err ([RDFIFO + ": cannot remove " + errno_string (errno)], 1);

ifnot (access (WRFIFO, F_OK))
  if (-1 == remove (WRFIFO))
    on_eval_err ([WRFIFO + ": cannot remove, " + errno_string (errno)], 1);

if (-1 == mkfifo (RDFIFO, 0644))
  on_eval_err ([RDFIFO + ": cannot create, " + errno_string (errno)], 1);

if (-1 == mkfifo (WRFIFO, 0644))
  on_eval_err ([WRFIFO + ": cannot create, " + errno_string (errno)], 1);

define _precom_ ()
{
  icom++;
  ERR_VED.st_.st_size = fstat (STDERRFD).st_size;
}

define shell_pre_header (argv)
{
  iarg++;
  if (APP.realshell)
    tostdout (strjoin (argv, " ") + "\n");
}

define shell_post_header ()
{
  if (APP.realshell)
    tostdout ("[" + string (iarg) + "](" + getcwd + ")[" + string (SHELLLASTEXITSTATUS) + "]$ ");
}

ifnot (NULL == APP.excom)
  {
  loadfrom ("api", "clientfuncs", NULL, &on_eval_err);

  if (APP.excom.scratch)
    loadfrom ("api", "exscratch", NULL, &on_eval_err);
 
  if (APP.excom.edit)
    loadfrom ("api", "exedit", NULL, &on_eval_err);
 
  if (APP.excom.messages)
    loadfrom ("api", "exmessages", NULL, &on_eval_err);

  if (APP.excom.ved)
    loadfrom ("api", "exved", NULL, &on_eval_err);

  if (APP.excom.eval)
    loadfrom ("api", "eval", NULL, &on_eval_err);
  }

define _write_ (argv)
{
  if (any (["w", "w!", "W"]  == argv[0]))
    {
    __writefile (get_cur_buf (), "w!" == argv[0], [PROMPTROW, 1], argv[[1:]]);
    return;
    }
}

define _postexec_ (header)
{
  if (qualifier_exists ("draw") && qualifier ("draw") == 0)
    return;

  if (header)
    shell_post_header ();

  if (NEEDSWINDDRAW)
    {
    draw_wind ();
    NEEDSWINDDRAW = 0;
    }
  else
    draw (get_cur_buf ());
}

private define _ask_ (cmp_lnrs, wrfd, rdfd)
{
  variable i;
  variable ocmp_lnrs = @cmp_lnrs;
 
  sock->send_bit (wrfd, 1);
 
  variable str = sock->get_str (rdfd);

  () = widg->askprintstr (str, NULL, &cmp_lnrs);
 
  sock->send_bit (wrfd, 1);

  if (length (cmp_lnrs) < length (ocmp_lnrs))
    {
    _for i (0, length (ocmp_lnrs) - 1)
      ifnot (any (ocmp_lnrs[i] == cmp_lnrs))
        ocmp_lnrs[i] = -1;

    ocmp_lnrs = ocmp_lnrs[wherenot (ocmp_lnrs == -1)];
    smg->restore (ocmp_lnrs, NULL, 1);
    }

  return cmp_lnrs;
}

private define _sendmsgdr_ (wrfd, rdfd)
{
  sock->send_bit (wrfd, 1);
 
  variable str = sock->get_str (rdfd);
 
  send_msg_dr (str, 0, NULL, NULL);

  sock->send_bit (wrfd, 1);
}

private define _restorestate_ (cmp_lnrs, wrfd)
{
  if (length (cmp_lnrs))
    smg->restore (cmp_lnrs, NULL, 1);
 
  sock->send_bit (wrfd, 1);
}

define waitfunc (wrfd, rdfd)
{
  variable buf;
  variable cmp_lnrs = Integer_Type[0];

  issmg = 0;

  forever
    {
    buf = sock->get_str (rdfd);
    buf = strtrim_end (buf);
 
    if ("exit" == buf)
      return;
 
    if ("restorestate" == buf)
      {
      _restorestate_ (cmp_lnrs, wrfd);
      cmp_lnrs = Integer_Type[0];
      continue;
      }
 
    if ("send_msg_dr" == buf)
      {
      _sendmsgdr_ (wrfd, rdfd);
      continue;
      }

    if ("ask" == buf)
      {
      cmp_lnrs = _ask_ (cmp_lnrs, wrfd, rdfd);
      continue;
      }

    if ("close_smg" == buf)
      {
      ifnot (issmg)
        {
        smg->suspend ();
        issmg = 1;
        }

      sock->send_bit (wrfd, 1);
      continue;
      }

    if ("restore_smg" == buf)
      {
      if (issmg)
        {
        smg->resume ();
        issmg = 0;
        }

      sock->send_bit (wrfd, 1);
      continue;
      }
    }
}

private define _waitpid_ (p)
{
  variable wrfd = open (WRFIFO, O_WRONLY);
  variable rdfd = open (RDFIFO, O_RDONLY);
 
  waitfunc (wrfd, rdfd);

  sock->send_bit (wrfd, 1);
 
  variable status = waitpid (p.pid, 0);
 
  p.atexit ();
 
  SHELLLASTEXITSTATUS = status.exit_status;
}

define _preexec_ (argv, header, issudo, env)
{
  _precom_ ();

  @header = strlen (argv[0]) > 1 && 0 == qualifier_exists ("no_header");
  @issudo = qualifier ("issudo");
  @env = [proc->defenv (), "PPID=" + string (PID)];

  variable p = proc->init (@issudo, 0, 1);

  p.issu = @issudo ? 0 : 1;

  if (@header)
    shell_pre_header (argv);
 
  if ('!' == argv[0][0])
    argv[0] = substr (argv[0], 2, -1);

  argv = [SLSH_BIN, p.loadcommand, argv];

  if (@issudo)
    {
    p.stdin.in = qualifier ("passwd");
    if (NULL == p.stdin.in)
      {
      SHELLLASTEXITSTATUS = 1;

      if (@header)
        shell_post_header ();

      return NULL;
      }

    argv = [SUDO_BIN, "-S", "-E", "-p", "", argv];
    }

  return argv, p;
}

define parse_redir (lastarg, file, flags)
{
  variable index = 0;
  variable chr = lastarg[index];
  variable redir = chr == '>';
 
  ifnot (redir)
    return 0;
 
  variable lfile;
  variable lflags = ">";
  variable len = strlen (lastarg);

  index++;

  if (len == index)
    return -1;
 
  chr = lastarg[index];

  if (chr == '>' || chr == '|')
    {
    lflags += char (chr);
    index++;
 
    if (len == index)
      return -1;
    }

  chr = lastarg[index];

  if (chr == '|')
    {
    lflags += char (chr);
    index++;
 
    if (len == index)
      return -1;
    }
 
  lfile = substr (lastarg, index + 1, -1);
 
  ifnot (access (lfile, F_OK))
    {
    ifnot ('|' == lflags[-1])
      if (NULL == redirexists || (NULL != redirexists && licom + 1 != icom))
        {
        if (">" == lflags)
          {
          licom = icom;
          redirexists = 1;
          tostderr (lfile + ": file exists, use >|");
          return -1;
          }
        }
      else
        if (">" == lflags)
          {
          redirexists = NULL;
          licom = 0;
          lflags = ">|";
          }
 
    if (-1 == access (lfile, W_OK))
      {
      tostderr (lfile + ": is not writable");
      return -1;
      }

    ifnot (isreg (lfile))
      {
      tostderr (lfile + ": is not a regular file");
      return -1;
      }
    }
 
  @flags = lflags;
  @file = lfile;
  return 1;
}

define parse_argv (argv, isbg)
{
  variable flags = ">>|";
  variable file = isbg ? STDOUTBG : APP.realshell ? get_cur_buf()._absfname : SCRATCH;
  variable retval = parse_redir (argv[-1], &file, &flags);
 
  return file, flags, retval;
}

define _getpasswd_ ()
{
  variable passwd, retval;

  ifnot (NULL == HASHEDDATA)
    {
    retval = os->confirmpasswd (HASHEDDATA, &passwd);

    if (NULL == retval)
      {
      passwd = NULL;
      send_msg_dr ("Authentication error", 1, NULL, NULL);
      }
    else
      passwd+= "\n";
    }
  else
    {
    passwd = getpasswd ();
 
    if (-1 == os->authenticate (USER, passwd))
      passwd = NULL;

    ifnot (NULL == passwd)
      {
      HASHEDDATA = os->encryptpasswd (passwd);
      passwd+= "\n";
      }
    }

  return passwd;
}

private define _sendsig_ (sig, pid, passwd)
{
  variable p = proc->init (1, 0, 0);
  p.stdin.in = passwd;

  variable status = p.execv ([SUDO_BIN, "-S", "-E", "-p", "", SLSH_BIN,
    STDDIR + "/proc/sendsignalassu.sl", sig, pid], NULL);
}

define _getbgstatus_ (pid)
{
  variable pidfile = BGDIR + "/" + pid + ".WAIT";
  variable force = qualifier_exists ("force");
  variable isnotsudo = BGPIDS[pid].issu;

  if (-1 == access (pidfile, F_OK))
    ifnot (force)
      return;
    else
      pidfile = BGDIR + "/" + pid + ".RUNNING";
 
  if (0 == isnotsudo && UID)
    {
    variable passwd = _getpasswd_ ();
    if (NULL == passwd)
      return;
 
    _sendsig_ (string (SIGKILL), pid, passwd);
    }
  else
    if (-1 == kill (atoi (pid), SIGALRM))
      {
      tostderr (pid + ": " + errno_string (errno) + "\n");
      return;
      }
 
  if (isnotsudo || (isnotsudo == 0 == UID))
    {
    variable rdfd = open (RDFIFO, O_RDONLY);
    variable buf = sock->get_str (rdfd);

    buf = strtrim_end (buf);

    ifnot ("exit" == buf)
      return;
    }

  variable status = waitpid (atoi (pid), 0);
 
  variable out = read_fd (STDOUTFDBG;pos = OUTBG.st_.st_size);

  ifnot (NULL == out)
    if (APP.realshell)
      tostdout ("\n" + pid + ": " + strjoin (BGPIDS[pid].argv, " ") + "\n" +  out);
    else
      toscratch ("\n" + pid + ": " + strjoin (BGPIDS[pid].argv, " ") + "\n" +  out);


  ifnot (force)
    if (APP.realshell)
      tostdout (pid + ": exit status " + string (status.exit_status) + "\n");
    else
      toscratch (pid + ": exit status " + string (status.exit_status) + "\n");
 

  BGPIDS[pid].atexit ();

  assoc_delete_key (BGPIDS, pid);
 
  () = remove (pidfile);
}

define _getbgjobs_ ()
{
  variable pids = assoc_get_keys (BGPIDS);

  ifnot (length (pids))
    return;

  variable i;

  _for i (0, length (pids) - 1)
    _getbgstatus_ (pids[i]);
}

define _forkbg_ (p, argv, env)
{
  env = [env, "BG=" + BGDIR];

  OUTBG.st_.st_size = fstat (STDOUTFDBG).st_size;

  variable pid = p.execve (argv, env, 1);

  ifnot (p.issu)
    p.argv = ["sudo", argv[[7:]]];
  else
    p.argv = argv[[2:]];
 
  BGPIDS[string (pid)] = p;
 
  if (APP.realshell)
    tostdout ("forked " + string (pid) + " &\n");
  else
    send_msg_dr ("forked " + string (pid) + " &", 0, PROMPTROW, 1);
}

define _fork_ (p, argv, env)
{
  variable errfd = @FD_Type (_fileno (STDERRFD));
 
  () = p.execve (argv, env, 1);

  _waitpid_ (p);
 
  variable err = read_fd (errfd;pos = ERR_VED.st_.st_size);

  ifnot (NULL == err)
    if (APP.realshell)
      tostdout (err);
    else
      toscratch (err);
}

define execute (argv)
{
  variable isbg = 0;
  if (argv[-1] == "&")
    {
    isbg = 1;
    argv = argv[[:-2]];
    }

  if (argv[-1][-1] == '&')
    {
    isbg = 1;
    argv[-1] = substr (argv[-1], 1, strlen (argv[-1]) - 1);
    }

  variable header, issudo, env, stdoutfile, stdoutflags;

  variable p = _preexec_ (argv, &header, &issudo, &env;;__qualifiers ());

  if (NULL == p)
    return;

  argv = ();

  variable isscratch = is_arg ("--pager", argv);
 
  ifnot (NULL == isscratch)
    {
    isbg = 0;
    argv[isscratch] = NULL;
    argv = argv[wherenot (_isnull (argv))];
    stdoutfile = SCRATCH;
    stdoutflags = ">|";
    }
  else
    {
    variable file, flags, retval;
    (file, flags, retval) = parse_argv (argv, isbg);

    if (-1 == retval)
      {
      variable err = read_fd (STDERRFD;pos = ERR_VED.st_.st_size);
 
      if (APP.realshell)
        tostdout (err + "\n");
      else
        toscratch (err + "\n");

      ERR_VED.st_.st_size += strbytelen (err) + 1;
      SHELLLASTEXITSTATUS = 1;
      _postexec_ (header);
      return;
      }
 
    if (1 == retval)
      {
      argv[-1] = NULL;
      argv = argv[wherenot (_isnull (argv))];
      }

    stdoutfile = file;
    stdoutflags = flags;
    }

  if (NULL == isscratch &&
  %%% CARE FOR CHANGES argv-index
    (any (argv[2] == ["man"]) && NULL == is_arg ("--buildcache", argv)))
    {
    isbg = 0;
    stdoutfile = SCRATCH;
    stdoutflags = ">|";
    isscratch = 1;
    }

  p.stderr.file = STDERR;
  p.stderr.wr_flags = ">>|";
 
  env = [env, "stdoutfile=" + stdoutfile, "stdoutflags=" + stdoutflags];
 
  ifnot (isbg)
    _fork_ (p, argv, env);
  else
    {
    _forkbg_ (p, argv, env);
    isscratch = NULL;
    }

  if (NULL != isscratch || 0 == APP.realshell)
    ifnot (SHELLLASTEXITSTATUS)
      _scratch_ (get_cur_buf ();;__qualifiers ());
    else
      ifnot (APP.realshell)
        _scratch_ (get_cur_buf;;__qualifiers ());

  ifnot (isbg)
    _getbgjobs_ ();

  _postexec_ (header;;__qualifiers ());
}

define _builtinpost_ ()
{
  variable err = read_fd (STDERRFD;pos = ERR_VED.st_.st_size);

  ifnot (NULL == err)
    if (APP.realshell)
      tostdout (err + "\n");
    else
      tostdout (err + "\n");

  shell_post_header ();

  draw (get_cur_buf ());
}

define _builtinpre_ (argv)
{
  _precom_ ();
  shell_pre_header (argv);
}

define _kill_bg_job (argv)
{
  shell_pre_header (argv);

  if (1 == length (argv))
    {
    shell_post_header ();
    draw (get_cur_buf ());
    return;
    }

  variable pid = argv[1];

  ifnot (assoc_key_exists (BGPIDS, pid))
    {
    shell_post_header ();
    draw (get_cur_buf ());
    return;
    }

  _getbgstatus_ (pid;force);
 
  if (APP.realshell)
    tostdout (pid + ": killed\n");
  else
    send_msg_dr (pid + ": killed", 0, PROMPTROW, 1);

  shell_post_header ();
  draw (get_cur_buf ());
}

define _list_bg_jobs_ (argv)
{
  shell_pre_header (argv);

  variable ar = String_Type[0];
  variable i;
  variable pids = assoc_get_keys (BGPIDS);

  ifnot (length (pids))
    {
    shell_post_header ();
    draw (get_cur_buf ());
    return;
    }
 
  _for i (0, length (pids) - 1)
    ar = [ar, pids[i] + ": " + strjoin (BGPIDS[pids[i]].argv, " ") + "\n"];
 
  array_map (&tostdout, ar);

  shell_post_header ();

  draw (get_cur_buf ());
}
 
define _cd_ (argv)
{
  _builtinpre_ (argv);

  if (1 == length (argv))
    {
    ifnot (getcwd () == "$HOME/"$)
      () = chdir ("$HOME"$);
    }
  else
    {
    variable dir = evaldir (argv[1]);
    ifnot (are_same_files (getcwd (), dir))
      if (-1 == chdir (dir))
        {
        tostderr (errno_string (errno) + "\n");
        SHELLLASTEXITSTATUS = 1;
        }
    }

  _builtinpost_ ();
}

define _search_ (argv)
{
  _precom_ ();

  variable header, issudo, env, stdoutfile, stdoutflags;

  variable p = _preexec_ (argv, &header, &issudo, &env;;__qualifiers ());

  if (NULL == p)
    return;

  argv = ();

  stdoutfile = GREPFILE;
  stdoutflags = ">|";
  p.stderr.file = STDERR;
  p.stderr.wr_flags = ">>|";
 
  env = [env, "stdoutfile=" + stdoutfile, "stdoutflags=" + stdoutflags];

  _fork_ (p, argv, env);

  ifnot (SHELLLASTEXITSTATUS)
    runapp (["ved", GREPFILE], proc->defenv ());
 
  shell_post_header ();
  draw (get_cur_buf ());
}

define _which_ (argv)
{
  _builtinpre_ (argv);

  if (1 == length (argv))
    {
    tostderr ("argument is required\n");
    _builtinpost_ ();
    return;
    }

  variable com = argv[1];

  variable path = which (com);

  ifnot (NULL == path)
    tostdout (path + "\n");
  else
    tostdout (com + " hasn't been found in PATH\n");

  SHELLLASTEXITSTATUS = NULL == path;

  _builtinpost_ ();
}

define runapp (argv, env)
{
  smg->suspend ();
 
  argv[0] = ROOTDIR + "/bin/" + argv[0];

  variable issudo = qualifier ("issudo");
 
  variable p = proc->init (issudo, 0, 0);
  if (issudo)
    {
    p.stdin.in = qualifier ("passwd");
    argv = [SUDO_BIN, "-S", "-E", "-p", "", argv];
    }
 
  variable status;
 
  ifnot (NULL == env)
    status = p.execve (argv, env, NULL);
  else
    status = p.execv (argv, NULL);

  smg->resume ();
}

private define _build_comlist (a)
{
  variable
    ex = qualifier_exists ("ex"),
    i,
    ii,
    c,
    d = [USRDIR, STDDIR, LCLDIR];
 
  _for i (0, length (d) - 1)
    {
    c = listdir (d[i] + "/com");
 
    ifnot (NULL == c)
      _for ii (0, length (c) - 1)
        {
        a[(ex ? "!" : "") + c[ii]] = @Argvlist_Type;
        a[(ex ? "!" : "") + c[ii]].dir = d[i] + "/com/" + c[ii];
        a[(ex ? "!" : "") + c[ii]].func = &execute;
        }
    }
}

define init_commands ()
{
  variable
    a = Assoc_Type[Argvlist_Type, @Argvlist_Type];
 
  _build_comlist (a;;__qualifiers ());

  ifnot (NULL == APP.excom)
    {
    if (APP.excom.scratch)
      {
      a["@"] = @Argvlist_Type;
      a["@"].func = __get_reference ("scratch");
      }

    if (APP.excom.edit)
      {
      a["edit"] = @Argvlist_Type;
      a["edit"].func = __get_reference ("_edit_");
      }

    if (APP.excom.messages)
      {
      a["messages"] = @Argvlist_Type;
      a["messages"].func = __get_reference ("_messages_");
      }

    if (APP.excom.ved)
      {
      a["ved"] = @Argvlist_Type;
      a["ved"].func = __get_reference ("_ved_");
      }

    if (APP.excom.eval)
      {
      a["eval"] = @Argvlist_Type;
      a["eval"].func = __get_reference ("_eval_");
      }
    }
 
  a["&"] = @Argvlist_Type;
  a["&"].func = &_idle_;

  a["w"] = @Argvlist_Type;
  a["w"].func = &_write_;

  a["w!"] = @Argvlist_Type;
  a["w!"].func = &_write_;

  a["bgjobs"] = @Argvlist_Type;
  a["bgjobs"].func = &_list_bg_jobs_;

  a["killbgjob"] = @Argvlist_Type;
  a["killbgjob"].func = &_kill_bg_job;
  
  a["q"] = @Argvlist_Type;
  a["q"].func = APP.func.exit;

  a["cd"] = @Argvlist_Type;
  a["cd"].func = &_cd_;

  a["which"] = @Argvlist_Type;
  a["which"].func = &_which_;

  a["search"] = @Argvlist_Type;
  a["search"].func = &_search_;
  a["search"].dir = STDDIR + "/com/search";

  return a;
}
