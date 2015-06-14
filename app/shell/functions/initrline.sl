private variable redirexists = NULL;
private variable licom = 0;

if (-1 == access (STACKFILE, F_OK))
  writestring (STACKFILE, "STACK = {}");

private define _precom_ ()
{
  icom++;
  MSG.st_.st_size = stat_file (STDERR).st_size;;
}

private define parse_redir (lastarg, file, flags)
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

private define parse_argv (argv)
{
  variable flags = ">>|";
  variable file = STDOUT;
  variable retval = parse_redir (argv[-1], &file, &flags);
  
  return file, flags, retval;
}

private define _waitpid_ (p)
{
  variable wrfd = open (WRFIFO, O_WRONLY);
  variable rdfd = open (RDFIFO, O_RDONLY);
  
  waitfunc (p, wrfd, rdfd);

  sock->send_bit (wrfd, 1);
  
  variable status = waitpid (p.pid, 0);
  
  p.atexit ();
  
  SHELLLASTEXITSTATUS = status.exit_status;
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
 
  ifnot (0 == retval)
    {
    send_msg_dr (errno_string (retval), 1, ptr[0], ptr[1]);
    return;
    }
 
  if (file == s._fname)
    s._flags = s._flags & ~VED_MODIFIED;
}

private define _write_ (argv)
{
  if ("w" == argv[0] || "w!" == argv[0])
    {
    write_file (qualifier ("ved"), "w!" == argv[0], [PROMPTROW, 1], argv[[1:]]);
    return;
    }
}

private define edit ()
{
  _precom_ ();

  variable s = qualifier ("ved");

  viewfile (s, "STDOUT", s.ptr, s._ii);
}

private define _exit_ ()
{
  variable rl = qualifier ("rl");

  ifnot (NULL == rl)
    rline->writehistory (rl.history, rl.histfile);

  exit_me (0);
}

private define _ved_ (argv)
{
  _precom_ ();
  
  variable fname = 1 == length (argv) ? SCRATCHFILE : argv[1];
  
  shell_pre_header ("ved " + fname);

  smg->suspend ();
 
  variable issudo = qualifier ("issudo");

  loadfrom ("app/ved", "vedInit", NULL, &on_eval_err);

  variable ved = issudo ? __get_reference ("vedsudo") : __get_reference ("ved");

  (@ved) (fname;;__qualifiers ());

  smg->resume ();

  shell_post_header ();
  
  draw (qualifier ("ved"));
}

private define _preexec_ (argv, header, issudo, env)
{
  _precom_ ();

  @header = strlen (argv[0]) > 1 && 0 == qualifier_exists ("no_header");
  @issudo = qualifier ("issudo");
  @env = [proc->getdefenv (), "PPID=" + string (MYPID)];

  variable p = proc->init (@issudo, 0, 1);

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

    argv = [qualifier ("sudobin"), "-S", "-E", "-p", "", argv];
    }

  return argv, p;
}

private define _fork_ (p, argv, env, ved)
{
  variable errfd = @FD_Type (_fileno (ERRFD));
  
  () = p.execve (argv, env, 1);

  _waitpid_ (p);
  
  variable err = read_fd (errfd;pos = MSG.st_.st_size);

  ifnot (NULL == err)
    tostdout (err);
}

private define _postexec_ (header, ved)
{ 
  if (header)
    shell_post_header ();

  draw (ved);
}

private define _search_ (argv)
{
  _precom_ ();

  variable header, issudo, env, stdoutfile, stdoutflags;

  variable p = _preexec_ (argv, &header, &issudo, &env;;__qualifiers ());

  if (NULL == p)
    return;

  argv = ();

  stdoutfile = GREPILE;
  stdoutflags = ">|";
  p.stderr.file = STDERR;
  p.stderr.wr_flags = ">>|";
  
  env = [env, "stdoutfile=" + stdoutfile, "stdoutflags=" + stdoutflags];

  _fork_ (p, argv, env, qualifier ("ved"));

  ifnot (SHELLLASTEXITSTATUS)
    {
    smg->suspend ();
 
    loadfrom ("app/ved", "vedInit", NULL, &on_eval_err);

    variable ved = __get_reference ("ved");

    (@ved) (GREPILE);

    smg->resume ();
    }
  
  _postexec_ (header, qualifier ("ved"));
}

private define execute (argv)
{
  variable header, issudo, env, stdoutfile, stdoutflags;

  variable p = _preexec_ (argv, &header, &issudo, &env;;__qualifiers ());

  if (NULL == p)
    return;

  argv = ();

  variable isscratch = is_arg ("--pager", argv);
  
  ifnot (NULL == isscratch)
    {
    argv[isscratch] = NULL;
    argv = argv[wherenot (_isnull (argv))];
    stdoutfile = SCRATCHFILE;
    stdoutflags = ">|";
    }
  else
    {
    variable file, flags, retval;
    (file, flags, retval) = parse_argv (argv);

    if (-1 == retval)
      {
      variable err = read_fd (ERRFD;pos = MSG.st_.st_size);
    
      tostdout (err + "\n");
      MSG.st_.st_size += strbytelen (err) + 1;
      SHELLLASTEXITSTATUS = 1;
      _postexec_ (header, qualifier ("ved"));
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

  %%% CARE FOR CHANGES        argv-index
  if (NULL == isscratch && any (argv[2] == ["man"]))
    {
    stdoutfile = SCRATCHFILE;
    stdoutflags = ">|";
    isscratch = 1;
    }

  p.stderr.file = STDERR;
  p.stderr.wr_flags = ">>|";
 
  env = [env, "stdoutfile=" + stdoutfile, "stdoutflags=" + stdoutflags];

  _fork_ (p, argv, env, qualifier ("ved"));

  ifnot (NULL == isscratch)
    ifnot (SHELLLASTEXITSTATUS)
      scratch (qualifier ("ved"));

  _postexec_ (header, qualifier ("ved"));
}

private define _builtinpre_ (argv)
{
  _precom_ ();
  shell_pre_header (argv);
}

private define _builtinpost_ (vd)
{
  variable err = read_fd (ERRFD;pos = MSG.st_.st_size);

  ifnot (NULL == err)
    tostdout (err + "\n");

  shell_post_header ();

  draw (vd);
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
    (file, flags, retval) = parse_argv (argv);

    if (-1 == retval)
      {
      _builtinpost_ (qualifier ("ved"));
      SHELLLASTEXITSTATUS = 1;
      return;
      }
    
    ifnot (retval)
      {
      tostdout (strjoin (argv, " ") + hasnewline);
      _builtinpost_ (qualifier ("ved"));
      return;
      }

    argv[-1] = NULL;
    argv = argv[wherenot (_isnull (argv))];

    if (">>" == flags || 0 == access (file, F_OK))
      _appendstr (file, strjoin (argv, " ") + hasnewline);
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
  
  _builtinpost_ (qualifier ("ved"));
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

  _builtinpost_ (qualifier ("ved"));
}

private define _which_ (argv)
{
  _builtinpre_ (argv);

  if (1 == length (argv))
    {
    tostderr ("argument is required\n");
    _builtinpost_ (qualifier ("ved"));
    return;
    }

  variable com = argv[1];

  variable path = which (com);

  ifnot (NULL == path)
    tostdout (path + "\n");
  else
    tostdout (com + " hasn't been found in PATH\n");

  SHELLLASTEXITSTATUS = NULL == path;

  _builtinpost_ (qualifier ("ved"));
}

private define _intro_ (argv)
{
  variable rl = qualifier ("rl");
  variable vd = qualifier ("ved");
 
  intro (rl, vd); 
}

private define _rehash_ ();

private define init_commands ()
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

  a["@"] = @Argvlist_Type;
  a["@"].func = &edit;

  a["edit"] = @Argvlist_Type;
  a["edit"].func = &edit;

  a["w"] = @Argvlist_Type;
  a["w"].func = &_write_;

  a["w!"] = @Argvlist_Type;
  a["w!"].func = &_write_;

  a["messages"] = @Argvlist_Type;
  a["messages"].func = &_messages_;
  
  a["rehash"] = @Argvlist_Type;
  a["rehash"].func = &_rehash_;
  
  a["intro"] = @Argvlist_Type;
  a["intro"].func = &_intro_;

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

define rlineinit ()
{
  variable rl = rline->init (&init_commands;
    histfile = LCLDATADIR + "/." + string (getuid ()) + "ashellhistory",
    filtercommands = &filtercommands,
    filterargs = &filterargs,
    on_lang = &toplinedr,
    on_lang_args = " -- shell --");
 
  iarg = length (rl.history);

  return rl;
}

private define _rehash_ (argv)
{
  qualifier ("rl").argvlist = init_commands ();
}
