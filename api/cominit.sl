private variable issmg = 0;

variable redirexists = NULL;
variable licom = 0;
variable icom = 0;
variable iarg;
variable SHELLLASTEXITSTATUS = 0;
variable RDFIFO = Dir->Vget ("TEMPDIR") + "/" + string (Env->Vget ("PID")) +  "_SRV_FIFO.fifo";
variable WRFIFO = Dir->Vget ("TEMPDIR") + "/" + string (Env->Vget ("PID")) +  "_CLNT_FIFO.fifo";

ifnot (access (RDFIFO, F_OK))
  if (-1 == remove (RDFIFO))
    __err_handler__ (1;msg = RDFIFO + ": cannot remove " + errno_string (errno));

ifnot (access (WRFIFO, F_OK))
  if (-1 == remove (WRFIFO))
    __err_handler__ (1;msg = WRFIFO + ": cannot remove, " + errno_string (errno));

if (-1 == mkfifo (RDFIFO, 0644))
  __err_handler__ (1;msg = RDFIFO + ": cannot create, " + errno_string (errno));

if (-1 == mkfifo (WRFIFO, 0644))
  __err_handler__ (1;msg = WRFIFO + ": cannot create, " + errno_string (errno));

define precom ()
{
  icom++;
  ERR_VED.st_.st_size = fstat (STDERRFD).st_size;
}

define shell_pre_header (argv)
{
  iarg++;
  if (APP.realshell)
    IO.tostdout (strjoin (argv, " "));
  else
    toscratch (strjoin (argv, " ") + "\n");
}

define shell_post_header ()
{
  if (APP.realshell)
    IO.tostdout (sprintf ("[%d](%s)[%d]$ ", iarg, getcwd, SHELLLASTEXITSTATUS);
      n);
  else
    toscratch (sprintf ("[%d](%s)[%d]$ ", iarg, getcwd, SHELLLASTEXITSTATUS));
}

load.from ("api", "exscratch", NULL;err_handler = &__err_handler__);
load.from ("api", "exedit", NULL;err_handler = &__err_handler__);
load.from ("api", "exmessages", NULL;err_handler = &__err_handler__);
load.from ("api", "exved", NULL;err_handler = &__err_handler__);
load.from ("api", "eval", NULL;err_handler = &__err_handler__);

private define _write_ (argv)
{
  variable b = get_cur_buf ();
  variable lnrs = [0:b._len];
  variable range = NULL;
  variable append = NULL;
  variable ind = is_arg ("--range=", argv);
  variable lines;
  variable file;
  variable command;

  ifnot (NULL == ind)
    {
    variable arg = argv[ind];
    argv[ind] = NULL;
    argv = argv[wherenot (_isnull (argv))];
    if (NULL == (lnrs = __vparse_arg_range (b, arg, lnrs), lnrs))
      return;
    }

  ind = wherefirst (">>" == argv);
  ifnot (NULL == ind)
    {
    append = 1;
    argv[ind] = NULL;
    argv = argv[wherenot (_isnull (argv))];
    }

  command = argv[0];
  file = length (argv) - 1 ? argv[1] : NULL;

  if (any (["w", "w!", "W"]  == command))
    {
    __vwritefile (b, "w!" == command, [PROMPTROW, 1], file, append;
      lines = b.lines[lnrs]);
    }
}

private define _postexec_ (header)
{
  if (qualifier_exists ("draw") && qualifier ("draw") == 0)
    return;

  if (header)
    shell_post_header ();

  if (NEEDSWINDDRAW)
    {
    __vdraw_wind ();
    NEEDSWINDDRAW = 0;
    }
  else
    draw (get_cur_buf ());
}

private define _ask_ (cmp_lnrs, wrfd, rdfd)
{
  variable i;
  variable ocmp_lnrs = @cmp_lnrs;

  Sock.send_int (wrfd, 1);

  variable str = Sock.get_str (rdfd);
  Sock.send_int (wrfd, 1);
  i = Sock.get_int (rdfd);

  variable hl_reg = i ? Array_Type[i] : NULL;

  if (i)
    _for i (0, i - 1)
      {
      Sock.send_int (wrfd, 1);
      hl_reg[i] = Sock.get_int_ar (rdfd, wrfd);
      }

  () = widg->askprintstr (str, NULL, &cmp_lnrs;hl_region = hl_reg);

  Sock.send_int (wrfd, 1);

  if (length (cmp_lnrs) < length (ocmp_lnrs))
    {
    _for i (0, length (ocmp_lnrs) - 1)
      ifnot (any (ocmp_lnrs[i] == cmp_lnrs))
        ocmp_lnrs[i] = -1;

    ocmp_lnrs = ocmp_lnrs[wherenot (ocmp_lnrs == -1)];
    smg->restore (ocmp_lnrs, NULL, 1);
    }

  cmp_lnrs;
}

private define _sendmsgdr_ (wrfd, rdfd)
{
  Sock.send_int (wrfd, 1);

  variable str = Sock.get_str (rdfd);

  send_msg_dr (str, 0, NULL, NULL);

  Sock.send_int (wrfd, 1);
}

private define _restorestate_ (cmp_lnrs, wrfd)
{
  if (length (cmp_lnrs))
    smg->restore (cmp_lnrs, NULL, 1);

  Sock.send_int (wrfd, 1);
}

private define _waitfunc_ (wrfd, rdfd)
{
  variable buf;
  variable cmp_lnrs = Integer_Type[0];

  issmg = 0;

  forever
    {
    buf = Sock.get_str (rdfd);
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

      Sock.send_int (wrfd, 1);
      continue;
      }

    if ("restore_smg" == buf)
      {
      if (issmg)
        {
        smg->resume ();
        issmg = 0;
        }

      Sock.send_int (wrfd, 1);
      continue;
      }
    }
}

private define _waitpid_ (p)
{
  variable wrfd = open (WRFIFO, O_WRONLY);
  variable rdfd = open (RDFIFO, O_RDONLY);

  _waitfunc_ (wrfd, rdfd);

  Sock.send_int (wrfd, 1);

  variable status = waitpid (p.pid, 0);

  p.atexit ();

  SHELLLASTEXITSTATUS = status.exit_status;
}

private define _preexec_ (argv, header, issudo, env)
{
  precom ();

  @header = strlen (argv[0]) > 1 && 0 == qualifier_exists ("no_header");
  @issudo = qualifier ("issudo");
  @env = [proc->defenv (), "PPID=" + string (Env->Vget ("PID"))];

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

  argv, p;
}

private define _parse_redir_ (lastarg, file, flags)
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
    return 0;

  chr = lastarg[index];

  if (chr == '>' || chr == '|')
    {
    lflags += char (chr);
    index++;

    if (len == index)
      {
      IO.tostderr ("There is no file to redirect output");
      return -1;
      }
    }

  chr = lastarg[index];

  if (chr == '|')
    {
    lflags += char (chr);
    index++;

    if (len == index)
      {
      IO.tostderr ("There is no file to redirect output");
      return -1;
      }
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
          IO.tostderr (lfile + ": file exists, use >|");
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
      IO.tostderr (lfile + ": is not writable");
      return -1;
      }

    ifnot (isreg (lfile))
      {
      IO.tostderr (lfile + ": is not a regular file");
      return -1;
      }
    }

  @flags = lflags;
  @file = lfile;
  1;
}

private define _parse_argv_ (argv, isbg)
{
  variable flags = ">>|";
  variable file = isbg ? STDOUTBG : APP.realshell ? get_cur_buf()._abspath : SCRATCH;
  variable retval = _parse_redir_ (argv[-1], &file, &flags);

  file, flags, retval;
}

private define _getpasswd_ ()
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

    if (-1 == os->authenticate (Env->Vget ("user"), passwd))
      passwd = NULL;

    ifnot (NULL == passwd)
      {
      HASHEDDATA = os->encryptpasswd (passwd);
      passwd+= "\n";
      }
    }

  passwd;
}

private define _sendsig_ (sig, pid, passwd)
{
  variable p = proc->init (1, 0, 0);
  p.stdin.in = passwd;

  () = p.execv ([SUDO_BIN, "-S", "-E", "-p", "", SLSH_BIN,
    Dir->Vget ("STDDIR") + "/proc/sendsignalassu.sl", sig, pid], NULL);
}

private define _getbgstatus_ (pid)
{
  variable pidfile = BGDIR + "/" + pid + ".WAIT";
  variable force = qualifier_exists ("force");
  variable isnotsudo = BGPIDS[pid].issu;

  if (-1 == access (pidfile, F_OK))
    ifnot (force)
      return;
    else
      pidfile = BGDIR + "/" + pid + ".RUNNING";

  if (0 == isnotsudo && Env->Vget ("uid"))
    {
    variable passwd = _getpasswd_ ();
    if (NULL == passwd)
      return;

    _sendsig_ (string (SIGKILL), pid, passwd);
    }
  else
    if (-1 == kill (atoi (pid), SIGALRM))
      {
      IO.tostderr (pid + ": " + errno_string (errno));
      return;
      }

  if (isnotsudo || (isnotsudo == 0 == Env->Vget ("uid")))
    {
    variable rdfd = open (RDFIFO, O_RDONLY);
    variable buf = Sock.get_str (rdfd);

    buf = strtrim_end (buf);

    ifnot ("exit" == buf)
      return;
    }

  variable status = waitpid (atoi (pid), 0);

  variable out = IO.readfd (STDOUTFDBG;offset = OUTBG.st_.st_size);

  ifnot (NULL == out)
    if (APP.realshell)
      IO.tostdout ("\n" + pid + ": " + strjoin (BGPIDS[pid].argv, " ") + "\n" +  out);
    else
      toscratch ("\n" + pid + ": " + strjoin (BGPIDS[pid].argv, " ") + "\n" +  out);

  ifnot (force)
    if (APP.realshell)
      IO.tostdout (pid + ": exit status " + string (status.exit_status));
    else
      toscratch (pid + ": exit status " + string (status.exit_status) + "\n");

  BGPIDS[pid].atexit ();

  assoc_delete_key (BGPIDS, pid);

  () = remove (pidfile);
}

private define _getbgjobs_ ()
{
  variable pids = assoc_get_keys (BGPIDS);

  ifnot (length (pids))
    return;

  variable i;

  _for i (0, length (pids) - 1)
    _getbgstatus_ (pids[i]);
}

private define _forkbg_ (p, argv, env)
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
    IO.tostdout ("forked " + string (pid) + " &");
  else
    send_msg_dr ("forked " + string (pid) + " &", 0, PROMPTROW, 1);
}

private define _fork_ (p, argv, env)
{
  variable errfd = @FD_Type (_fileno (STDERRFD));

  () = p.execve (argv, env, 1);

  _waitpid_ (p);

  variable err = IO.readfd (errfd;offset = ERR_VED.st_.st_size);

  if (strlen (err))
    if (APP.realshell)
      IO.tostdout (err;n);
    else
      toscratch (err);
}

private define _execute_ (argv)
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
    (file, flags, retval) = _parse_argv_ (argv, isbg);

    if (-1 == retval)
      {
      variable err = IO.readfd (STDERRFD;offset = ERR_VED.st_.st_size);

      if (APP.realshell)
        IO.tostdout (err);
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
      _scratch_ (get_cur_buf ());
    else
      ifnot (APP.realshell)
        _scratch_ (get_cur_buf ());

  ifnot (isbg)
    _getbgjobs_ ();

  _postexec_ (header;;__qualifiers ());
}

private define _kill_bg_job (argv)
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
    IO.tostdout (pid + ": killed");
  else
    send_msg_dr (pid + ": killed", 0, PROMPTROW, 1);

  shell_post_header ();
  draw (get_cur_buf ());
}

private define _list_bg_jobs_ (argv)
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

  IO.tostdout (ar);

  shell_post_header ();

  draw (get_cur_buf ());
}

private define _builtinpre_ (argv)
{
  SHELLLASTEXITSTATUS = 0;
  precom ();
  shell_pre_header (argv);
}

private define _builtinpost_ ()
{
  variable err = IO.readfd (STDERRFD;offset = ERR_VED.st_.st_size);

  ifnot (NULL == err)
    if (APP.realshell)
      IO.tostdout (err);
    else
      toscratch (err + "\n");

  shell_post_header ();

  draw (get_cur_buf ());
}

private define _echo_ (argv)
{
  _builtinpre_ (argv);

  argv = argv[[1:]];

  variable hasnewline = wherefirst ("-n" == argv);
  variable s = @Struct_Type ("");
  ifnot (NULL == hasnewline)
    {
    argv[hasnewline] = NULL;
    argv = argv[wherenot (_isnull (argv))];
    s = @Struct_Type ("n");
    hasnewline = "";
    }
  else
    hasnewline = "\n";

  variable len = length (argv);

  ifnot (len)
    return;

  variable tostd = APP.realshell ? IO->Fget ("__tostdout__").func : &toscratch;

  if (1 == len)
    {
    if ('>' == argv[0][0])
      {
      SHELLLASTEXITSTATUS = 1;
      _builtinpost_ ();
      return;
      }

    if ('$' == argv[0][0])
      if ('?' == argv[0][1])
        (@tostd) (string (SHELLLASTEXITSTATUS);;s);
      else
        (@tostd) (_$ (argv[0]);;s);
    else
      (@tostd) (argv[0];;s);
    }
  else
    {
    variable file, flags, retval;
    (file, flags, retval) = _parse_argv_ (argv, 0);

    if (-1 == retval)
      {
      SHELLLASTEXITSTATUS = 1;
      _builtinpost_ ();
      return;
      }

    ifnot (retval)
      {
      (@tostd) (strjoin (argv, " ");;s);
      _builtinpost_ ();
      return;
      }

    argv[-1] = NULL;
    argv = argv[wherenot (_isnull (argv))];

    if (">>" == flags)
      {
      if (-1 == String.append (file, strjoin (argv, " ") + hasnewline))
        SHELLLASTEXITSTATUS = 1;
      }
    else
      {
      variable fd = open (file, O_CREAT|O_WRONLY, File->Vget ("PERM")["__PUBLIC"]);
      if (NULL == fd)
        {
        SHELLLASTEXITSTATUS = 1;
        IO.tostderr (file + ":" + errno_string (errno));
        }
      else
        if (-1 == write (fd, strjoin (argv, " ") + hasnewline))
          {
          SHELLLASTEXITSTATUS = 1;
          IO.tostderr (file + ":" + errno_string (errno));
          }
        else
          if (-1 == close (fd))
            {
            SHELLLASTEXITSTATUS = 1;
            IO.tostderr (file + ":" + errno_string (errno));
            }
      }
    }

  _builtinpost_ ();
}

private define _cd_ (argv)
{
  if (1 == length (argv))
    {
    ifnot (getcwd () == "$HOME/"$)
      () = chdir ("$HOME"$);
    }
  else
    {
    variable dir = Dir.eval (argv[1]);
    ifnot (File.are_same (getcwd (), dir))
      if (-1 == chdir (dir))
        {
        IO.tostderr (errno_string (errno));
        SHELLLASTEXITSTATUS = 1;
        }
    }

  _builtinpost_ ();
}

private define _search_ (argv)
{
  precom ();

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

private define _which_ (argv)
{
  _builtinpre_ (argv);

  if (1 == length (argv))
    {
    IO.tostderr ("argument is required");
    _builtinpost_ ();
    return;
    }

  variable com = argv[1];

  variable path = Sys.which (com);

  variable msg = NULL != path ? path : com + " hasn't been found in PATH";

  if (APP.realshell)
    IO.tostdout (msg;n);
  else
    toscratch (msg);

  SHELLLASTEXITSTATUS = NULL == path;

  _builtinpost_ ();
}

define runapp (argv, env)
{
  smg->suspend ();

  argv[0] = Dir->Vget ("ROOTDIR") + "/bin/" + argv[0];

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

private define _build_comlist_ (a)
{
  variable
    i,
    c,
    ii,
    ex = qualifier_exists ("ex"),
    d = [Dir->Vget ("USRDIR"), Dir->Vget ("STDDIR"), Dir->Vget ("LCLDIR")];

  _for i (0, length (d) - 1)
    {
    c = listdir (d[i] + "/com");

    ifnot (NULL == c)
      _for ii (0, length (c) - 1)
        {
        a[(ex ? "!" : "") + c[ii]] = @Argvlist_Type;
        a[(ex ? "!" : "") + c[ii]].dir = d[i] + "/com/" + c[ii];
        a[(ex ? "!" : "") + c[ii]].func = &_execute_;
        }
    }
}

private define _lock_ (argv)
{
  smg->cls ();
  smg->atrcaddnstr (" --- locked -- ", 1, LINES / 2, COLUMNS / 2 - 10,
    COLUMNS);

  while (NULL == __getpasswd);

  __vdraw_wind ();
}

define runcom (argv, issudo)
{
  variable rl = get_cur_rline ();

  ifnot (any (assoc_get_keys (rl.argvlist) == argv[0]))
    {
    IO.tostderr (argv[0] + ": no such command");
    return;
    }

  rl.argv = argv;
  (@rl.argvlist[argv[0]].func) (rl.argv;;struct {issudo = issudo, @__qualifiers ()});
}

define __rehash ();

define init_commands ()
{
  variable
    a = Assoc_Type[Argvlist_Type, @Argvlist_Type];

  _build_comlist_ (a;;__qualifiers ());

  ifnot (NULL == APP.excom)
    {
    a["@"] = @Argvlist_Type;
    a["@"].func = __get_reference ("__scratch");

    a["edit"] = @Argvlist_Type;
    a["edit"].func = __get_reference ("__edit");

    a["messages"] = @Argvlist_Type;
    a["messages"].func = __get_reference ("__messages");

    a["ved"] = @Argvlist_Type;
    a["ved"].func = __get_reference ("__ved");

    a["eval"] = @Argvlist_Type;
    a["eval"].func = __get_reference ("my_eval");
    a["eval"].type = "Func_Type";
    }

  a["rehash"] = @Argvlist_Type;
  a["rehash"].func = &__rehash;
  a["rehash"].type = "Func_Type";

  a["echo"] = @Argvlist_Type;
  a["echo"].func = &_echo_;

  a["lock"] = @Argvlist_Type;
  a["lock"].func = &_lock_;

  a["&"] = @Argvlist_Type;
  a["&"].func = &_idle_;

  a["w"] = @Argvlist_Type;
  a["w"].func = &_write_;
  a["w"].args = ["--range= int first linenr, last linenr"];

  a["w!"] = a["w"];

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
  a["search"].dir = Dir->Vget ("STDDIR") + "/com/search";

  variable pj = "PROJECT_" + strup (APP.appname);
  variable f = __get_reference (pj);
  ifnot (NULL == f)
    {
    a["project_new"] = @Argvlist_Type;
    a["project_new"].func = f;
    a["project_new"].args = ["--from-file= filename read from filename"];
    }
  a;
}
