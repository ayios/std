loadfrom ("shell", "cominit", NULL, &on_eval_err);

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

define _shell_ (argv)
{
  shell_pre_header ("shell");
  runapp ([argv], NULL;;__qualifiers ());
  shell_post_header ();
  draw (VED_CB);
}

private define _exit_ ()
{
  ifnot (NULL == RLINE)
    rline->writehistory (RLINE.history, RLINE.histfile);

  exit_me (0);
}

define _idle_ (argv)
{
  smg->suspend ();

  variable retval = go_idled ();
  
  ifnot (retval)
    {
    smg->resume ();
    return;
    }

  _exit_ (;;__qualifiers  ());
}

private define _ved_ (argv)
{
  _precom_ ();
 
  variable fname = 1 == length (argv) ? SCRATCH : argv[1];
 
  shell_pre_header ("ved " + fname);

  runapp (["ved", fname], proc->defenv ();;__qualifiers ());
 
  shell_post_header ();
 
  draw (VED_CB);
}

private define _search_ (argv)
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
    runapp (["ved", GREPFILE], [proc->defenv (), "return_code=1"]);
 
  shell_post_header ();
  draw (VED_CB);
}

private define _echo_ (argv)
{
  _builtinpre_ (argv);

  argv = argv[[1:]];

  variable hasnewline = wherefirst ("-n" == argv);
 
  ifnot (NULL == hasnewline)
    {
    argv[hasnewline] = NULL;
    argv = argv[wherenot (_isnull (argv))];
    hasnewline = "";
    }
  else
    hasnewline = "\n";

  variable len = length (argv);

  ifnot (len)
    return;

  if (1 == len)
    {
    if ('>' == argv[0][0])
      return;

    if ('$' == argv[0][0])
      if ('?' == argv[0][1])
        tostdout (string (SHELLLASTEXITSTATUS) + hasnewline);
      else
        tostdout (_$ (argv[0]) + hasnewline);
    else
      tostdout (argv[0] + hasnewline);
    }
  else
    {
    variable file, flags, retval;
    (file, flags, retval) = parse_argv (argv, 0);

    if (-1 == retval)
      {
      _builtinpost_ ();
      SHELLLASTEXITSTATUS = 1;
      return;
      }
 
    ifnot (retval)
      {
      tostdout (strjoin (argv, " ") + hasnewline);
      _builtinpost_ ();
      return;
      }

    argv[-1] = NULL;
    argv = argv[wherenot (_isnull (argv))];

    if (">>" == flags || 0 == access (file, F_OK))
      {
      if (-1 == appendstr (file, strjoin (argv, " ") + hasnewline))
       return;
      }
    else
      {
      variable fd = open (file, O_CREAT|O_WRONLY, PERM["__PUBLIC"]);
      if (NULL == fd)
        tostderr (file + ":" + errno_string (errno));
      else
        if (-1 == write (fd, strjoin (argv, " ") + hasnewline))
          tostderr (file + ":" + errno_string (errno));
        else
          if (-1 == close (fd))
            tostderr (file + ":" + errno_string (errno));
      }
    }
 
  _builtinpost_ ();
}

private define _cd_ (argv)
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

private define _which_ (argv)
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

private define _intro_ (argv)
{
  intro (RLINE, VED_CB);
}

private define _rehash_ ();

private define my_commands ()
{
  variable a = init_commands ();
 
  a["&"] = @Argvlist_Type;
  a["&"].func = &_idle_;

  a["echo"] = @Argvlist_Type;
  a["echo"].func = &_echo_;

  a["ved"] = @Argvlist_Type;
  a["ved"].func = &_ved_;
 
  a["search"] = @Argvlist_Type;
  a["search"].func = &_search_;
  a["search"].dir = STDDIR + "/com/search";

  a["cd"] = @Argvlist_Type;
  a["cd"].func = &_cd_;

  a["which"] = @Argvlist_Type;
  a["which"].func = &_which_;

  a["q"] = @Argvlist_Type;
  a["q"].func = &_exit_;

  a["rehash"] = @Argvlist_Type;
  a["rehash"].func = &_rehash_;
 
  a["intro"] = @Argvlist_Type;
  a["intro"].func = &_intro_;

  a["shell"] = @Argvlist_Type;
  a["shell"].func = &_shell_;

  return a;
}

private define filtercommands (ar)
{
  ar = ar[where (1 < strlen (ar))];
  return ar;
}

private define filterargs (args, type, desc)
{
  return [args, "--sudo", "--pager"], [type, "void", "void"],
    [desc, "execute command as superuser", "viewoutput in a scratch buffer"];
}

private define tabhook (s)
{
  ifnot (s._ind)
    return -1;
 
  ifnot (s.argv[0] == "killbgjob")
    return -1;

  variable pids = assoc_get_keys (BGPIDS);

  ifnot (length (pids))
    return -1;
 
  variable i;
  _for i (0, length (pids) - 1)
    pids[i] = pids[i] + " void " + strjoin (BGPIDS[pids[i]].argv, " ");

  return rline->argroutine (s;args = pids, accept_ws);
}

define rlineinit ()
{
  variable rl = rline->init (&my_commands;
    histfile = HISTDIR + "/" + string (getuid ()) + "shellhistory",
    filtercommands = &filtercommands,
    filterargs = &filterargs,
    tabhook = &tabhook,
    onnolength = &toplinedr,
    onnolengthargs = {""},
    on_lang = &toplinedr,
    on_lang_args = " -- shell --");
 
  iarg = length (rl.history);

  return rl;
}

private define _rehash_ (argv)
{
  RLINE.argvlist = init_commands ();
}

define runcom (argv, issudo)
{
  variable rl = rlineinit ();

  ifnot (any (assoc_get_keys (rl.argvlist) == argv[0]))
    {
    tostderr (argv[0] + ": no such command");
    return;
    }

  rl.argv = argv;

  (@rl.argvlist[argv[0]].func) (rl.argv;;struct {issudo = issudo, @__qualifiers ()});
}
