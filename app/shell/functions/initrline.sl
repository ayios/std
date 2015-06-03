private define _waitpid_ (p)
{
  variable buf = "";
  variable str;
  variable status;
  variable cmp_lnrs;

  WRFD = open (WRFIFO, O_WRONLY);
  RDFD = open (RDFIFO, O_RDONLY);

  forever
    {
    buf = sock->get_str (RDFD);
    buf = strtrim_end (buf);

    if ("exit" == buf)
      {
      sock->send_bit (WRFD, 1);
      status = waitpid (p.pid, 0);
      p.atexit ();
      SHELLLASTEXITSTATUS = status.exit_status;
      return;
      }
    
    if ("msgdr" == buf)
      {
      () = dup2_fd (p.stdout.keep, 1);

      sock->send_bit (WRFD, 1);
      
      str = sock->get_str (RDFD);

      send_msg_dr (str, 0, NULL, NULL); 

      () = dup2_fd (p.stdout.write, 1);

      sock->send_bit (WRFD, 1);

      continue;
      }

    if ("ask" == buf)
      {
      () = dup2_fd (p.stdout.keep, 1);

      sock->send_bit (WRFD, 1);
      
      str = sock->get_str (RDFD);

      () = widg->askprintstr (str, NULL, &cmp_lnrs);
      
      sock->send_bit (WRFD, 1);

      () = sock->get_bit (RDFD);

      smg->restore (cmp_lnrs, NULL, 1);
  
      () = dup2_fd (p.stdout.write, 1);

      sock->send_bit (WRFD, 1);
      }
    }
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

private define on_lang_change (args)
{
  toplinedr (args[1];row =  args[0][0], col = args[0][1]);
}

private define _viewfile_ (s, type, pos, _i)
{
  variable f = __get_reference ("setbuf");
  (@f) (s._absfname);
  
  topline (" -- pager -- (" + type + " BUF) --";row =  s.ptr[0], col = s.ptr[1]);
  
  ifnot (NULL == pos)
    (s.ptr[0] = pos[0], s.ptr[1] = pos[1]);

  draw (s;pos = pos, _i = _i);
  
  forever
    {
    VEDCOUNT = -1;
    s._chr = getch (;on_lang = &on_lang_change, on_lang_args = {s.ptr, "--pager -- (MSG BUF) --"});

    if ('1' <= s._chr <= '9')
      {
      VEDCOUNT = "";
 
      while ('0' <= s._chr <= '9')
        {
        VEDCOUNT += char (s._chr);
        s._chr = getch (;on_lang = &on_lang_change, on_lang_args = {s.ptr, "--pager -- (MSG BUF) --"});
        }

      VEDCOUNT = integer (VEDCOUNT);
      }
 
    (@pagerf[string (s._chr)]) (s);
 
    if (':' == s._chr || 'q' == s._chr)
      break;
    }
}

private define _scratch_ (ved)
{
  _viewfile_ (SCRATCH, "SCRATCH", [1, 0], 0);

  variable f = __get_reference ("setbuf");

  (@f) (ved._absfname);
  ved.draw ();
}

private define _messages_ ()
{
  _viewfile_ (MSG, "MSG", NULL, NULL);
  
  variable f = __get_reference ("setbuf");

  (@f) (qualifier ("ved")._absfname);
  qualifier ("ved").draw ();
}

private define edit ()
{
  variable s = qualifier ("ved");

  toplinedr (" -- pager --";row =  s.ptr[0], col = s.ptr[1]);

  forever
    {
    VEDCOUNT = -1;
    s._chr = getch (;on_lang = &on_lang_change, on_lang_args = {s.ptr, "--pager --"});

    if ('1' <= s._chr <= '9')
      {
      VEDCOUNT = "";
 
      while ('0' <= s._chr <= '9')
        {
        VEDCOUNT += char (s._chr);
        s._chr = getch (;on_lang = &on_lang_change, on_lang_args = {s.ptr, "--pager --"});
        }

      VEDCOUNT = integer (VEDCOUNT);
      }
 
    (@pagerf[string (s._chr)]) (s);
 
    if (':' == s._chr || 'q' == s._chr)
      return;
    }
}

private define _exit_ ()
{
  variable rl = qualifier ("rl");

  ifnot (NULL == rl)
    rline->writehistory (rl.history, rl.histfile);

  exit_me (0);
}


private define _echo_ (argv)
{
  shell_pre_header (argv);

  argv = argv[[1:]];

  variable len = length (argv);

  ifnot (len)
    return;

  if (1 == len)
    if ('$' == argv[0][0])
      if ('?' == argv[0][1])
        tostdout (string (SHELLLASTEXITSTATUS) + "\n");
      else
        tostdout (_$ (argv[0]) + "\n");

  shell_post_header ();

  draw (qualifier ("ved"));
}

private define _cd_ (argv)
{
  if (1 == length (argv))
    {
    if (getcwd () == "$HOME/"$)
      return;

    () = chdir ("$HOME"$);
    
    SHELLLASTEXITSTATUS = 0;
    }
  else
    if (are_same_files (getcwd (), argv[1]))
      return; 
    else
      if (-1 == chdir (argv[1]))
        {
        tostdout (errno_string (errno) + "\n");
        SHELLLASTEXITSTATUS = 1;
        }

  shell_pre_header (argv);

  shell_post_header ();

  draw (qualifier ("ved"));
}

private define _ved_ ()
{
  ifnot (_NARGS)
    return;

  variable fname = ();
  
  shell_pre_header ("ved " + fname);

  smg->suspend ();
 
  loadfrom ("app/ved", "vedInit", NULL, &on_eval_err);

  variable ved = __get_reference ("ved");

  (@ved) (fname);

  smg->resume ();

  shell_post_header ();
  
  draw (qualifier ("ved"));
}

private define _which_ ()
{
  ifnot (_NARGS)
    return;

  variable com = ();

  shell_pre_header ("which " + com);

  variable path = which (com);

  ifnot (NULL == path)
    tostdout (path + "\n");
  else
    tostdout (com + " hasn't been found in PATH\n");

  shell_post_header ();

  SHELLLASTEXITSTATUS = NULL == path;

  draw (qualifier ("ved"));
}

private define _preexec_ (argv, header, issudo, env)
{
  @header = strlen (argv[0]) > 1;
  @issudo = qualifier ("issudo");
  @env = [proc->getdefenv (), "PPID=" + string (MYPID)];

  variable p = proc->init (@issudo, 1, 1);

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
    {
    tostdout (err);
    MSG.st_.st_size += strbytelen (err);
    }
}

private define _postexec_ (header, ved)
{ 
  if (header)
    shell_post_header ();

  draw (ved);
}

private define _search_ (argv)
{
  variable header, issudo, env;

  variable p = _preexec_ (argv, &header, &issudo, &env;;__qualifiers ());

  if (NULL == p)
    return;

  argv = ();

  p.stdout.file = GREPILE;
  p.stdout.wr_flags = ">|";
  p.stderr.file = STDERR;
  p.stderr.wr_flags = ">>|";
  
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
  variable header, issudo, env;

  variable p = _preexec_ (argv, &header, &issudo, &env;;__qualifiers ());

  if (NULL == p)
    return;

  argv = ();

  variable isscratch = is_arg ("--pager", argv);
  
  ifnot (NULL == isscratch)
    {
    argv[isscratch] = NULL;
    argv = argv[wherenot (_isnull (argv))];
    p.stdout.file = SCRATCHFILE;
    p.stdout.wr_flags = ">|";
    }
  else
    {
    p.stdout.file = STDOUT;
    p.stdout.wr_flags = ">>|";
    }

  %%% CARE FOR CHANGES        argv-index
  if (NULL == isscratch && any (argv[2] == ["man"]))
    {
    p.stdout.file = SCRATCHFILE;
    p.stdout.wr_flags = ">|";
    isscratch = 1;
    }

  p.stderr.file = STDERR;
  p.stderr.wr_flags = ">>|";
  
  _fork_ (p, argv, env, qualifier ("ved"));

  ifnot (NULL == isscratch)
    ifnot (SHELLLASTEXITSTATUS)
      _scratch_ (qualifier ("ved"));

  _postexec_ (header, qualifier ("ved"));
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
  a["ved"].type = "Func_Type";
  
  a["search"] = @Argvlist_Type;
  a["search"].func = &_search_;
  a["search"].dir = STDDIR + "/com/search";

  a["cd"] = @Argvlist_Type;
  a["cd"].func = &_cd_;

  a["which"] = @Argvlist_Type;
  a["which"].func = &_which_;
  a["which"].type = "Func_Type";

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
    histfile = "$HOME/.ashellhistory"$,
    filtercommands = &filtercommands,
    filterargs = &filterargs,
    on_lang = &toplinedr,
    on_lang_args = " -- shell --");
 
  iarg = length (rl.history);

  return rl;
}

private define _rehash_ ()
{
  qualifier ("rl").argvlist = init_commands ();
}
