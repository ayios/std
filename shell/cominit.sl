loadfrom ("shell", "eval", NULL, &on_eval_err);

variable redirexists = NULL;
variable licom = 0;
private variable issmg = 0;

variable icom = 0;
variable iarg;
variable SHELLLASTEXITSTATUS = 0;
variable RDFIFO = TEMPDIR + "/" + string (PID) +  "_SRV_FIFO.fifo";
variable WRFIFO = TEMPDIR + "/" + string (PID) +  "_CLNT_FIFO.fifo";
variable STDOUTBG = TEMPDIR + "/" + string (PID) + "_stdoutbg.ashell";
variable BGDIR    = TEMPDIR + "/" + string (PID) + "_procs";
variable BGPIDS   = Assoc_Type[Struct_Type];
variable OUTBG;
variable STDOUTFDBG;

ifnot (access (RDFIFO, F_OK))
  () = remove (RDFIFO);

ifnot (access (WRFIFO, F_OK))
  () = remove (WRFIFO);

() = mkfifo (RDFIFO, 0644);
() = mkfifo (WRFIFO, 0644);

define _precom_ ()
{
  icom++;
  ERR_VED.st_.st_size = fstat (STDERRFD).st_size;
}

define shell_pre_header (argv)
{
  iarg++;
  tostdout (strjoin (argv, " ") + "\n");
}

define shell_post_header ()
{
  tostdout ("[" + string (iarg) + "](" + getcwd + ")[" + string (SHELLLASTEXITSTATUS) + "]$ ");
}

define scratch (ved)
{
  viewfile (SCRATCH_VED, "SCRATCH", [1, 0], 0);

  variable f = __get_reference ("setbuf");
  
  VED_CB = ved;

  (@f) (VED_CB._absfname);
  VED_CB.draw ();
}

private define write_file (s, overwrite, ptr, argv)
{
  variable file;
 
  ifnot (length (argv))
    {
    if (s._flags & VED_RDONLY)
      return;

    file = s._fname;
    }
  else
    {
    file = argv[0];
    ifnot (access (file, F_OK))
      {
      ifnot (overwrite)
        {
        send_msg_dr ("file exists, w! to overwrite", 1, ptr[0], ptr[1]);
        return;
        }

      if (-1 == access (file, W_OK))
        {
        send_msg_dr ("file is not writable", 1, ptr[0], ptr[1]);
        return;
        }
      }
    }
 
  variable retval = writetofile (file, s.lines, s._indent);
 
  if (retval)
    {
    send_msg_dr (errno_string (retval), 1, ptr[0], ptr[1]);
    return;
    }
 
  if (file == s._fname)
    s._flags &= ~VED_MODIFIED;
}

define _write_ (argv)
{
  if ("w" == argv[0] || "w!" == argv[0])
    {
    write_file (VED_CB, "w!" == argv[0], [PROMPTROW, 1], argv[[1:]]);
    return;
    }
}

define _edit_ (argv)
{
  _precom_ ();

  viewfile (VED_CB, "STDOUT", VED_CB.ptr, VED_CB._ii);
}

define _postexec_ (header)
{
  if (header)
    shell_post_header ();

  draw (VED_CB);
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
  variable file = isbg ? STDOUTBG : STDOUT;
  variable retval = parse_redir (argv[-1], &file, &flags);
 
  return file, flags, retval;
}

define _getpasswd_ ()
{
  variable passwd;

  ifnot (NULL == HASHEDDATA)
    {
    passwd = os->confirmpasswd (HASHEDDATA);

    if (NULL == passwd)
      tostderr ("Authentication error");
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
    tostdout ("\n" + pid + ": " + strjoin (BGPIDS[pid].argv, " ") + "\n" +  out);

  ifnot (force)
    tostdout (pid + ": exit status " + string (status.exit_status) + "\n");

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
 
  tostdout ("forked " + string (pid) + " &\n");
}

define _fork_ (p, argv, env)
{
  variable errfd = @FD_Type (_fileno (STDERRFD));
 
  () = p.execve (argv, env, 1);

  _waitpid_ (p);
 
  variable err = read_fd (errfd;pos = ERR_VED.st_.st_size);

  ifnot (NULL == err)
    tostdout (err);
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
 
      tostdout (err + "\n");
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

  ifnot (NULL == isscratch)
    ifnot (SHELLLASTEXITSTATUS)
      scratch (VED_CB);

  ifnot (isbg)
    _getbgjobs_ ();

  _postexec_ (header);
}

define _builtinpost_ ()
{
  variable err = read_fd (STDERRFD;pos = ERR_VED.st_.st_size);

  ifnot (NULL == err)
    tostdout (err + "\n");

  shell_post_header ();

  draw (VED_CB);
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
    draw (VED_CB);
    return;
    }

  variable pid = argv[1];

  ifnot (assoc_key_exists (BGPIDS, pid))
    {
    shell_post_header ();
    draw (VED_CB);
    return;
    }

  _getbgstatus_ (pid;force);
 
  tostdout (pid + ": killed\n");
  shell_post_header ();
  draw (VED_CB);
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
    draw (VED_CB);
    return;
    }
 
  _for i (0, length (pids) - 1)
    ar = [ar, pids[i] + ": " + strjoin (BGPIDS[pids[i]].argv, " ") + "\n"];
 
  array_map (&tostdout, ar);

  shell_post_header ();

  draw (VED_CB);
}

define _messages_ (argv)
{
  variable ved = @VED_CB;

  viewfile (ERR_VED, "MSG", NULL, NULL);
 
  variable f = __get_reference ("setbuf");
  
  VED_CB = ved;

  (@f) (VED_CB._absfname);
  VED_CB.draw ();
}

define init_commands ()
{
  variable
    i,
    ii,
    c,
    d = [USRDIR, STDDIR, LCLDIR],
    a = Assoc_Type[Argvlist_Type, @Argvlist_Type];
 
  _for i (0, length (d) - 1)
    {
    c = listdir (d[i] + "/com");
 
    ifnot (NULL == c)
      _for ii (0, length (c) - 1)
        {
        a[c[ii]] = @Argvlist_Type;
        a[c[ii]].dir = d[i] + "/com/" + c[ii];
        a[c[ii]].func = &execute;
        }
    }
 
  a["@"] = @Argvlist_Type;
  a["@"].func = &_edit_;

  a["edit"] = @Argvlist_Type;
  a["edit"].func = &_edit_;

  a["w"] = @Argvlist_Type;
  a["w"].func = &_write_;

  a["w!"] = @Argvlist_Type;
  a["w!"].func = &_write_;

  a["messages"] = @Argvlist_Type;
  a["messages"].func = &_messages_;
 
  a["bgjobs"] = @Argvlist_Type;
  a["bgjobs"].func = &_list_bg_jobs_;

  a["killbgjob"] = @Argvlist_Type;
  a["killbgjob"].func = &_kill_bg_job;

  a["eval"] = @Argvlist_Type;
  a["eval"].func = &_eval_;
  
  return a;
}

