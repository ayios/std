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

private define on_lang_change (args)
{
  toplinedr (args[1];row =  args[0][0], col = args[0][1]);
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

private define _write_ (argv)
{
  if ("w" == argv[0] || "w!" == argv[0])
    {
    write_file (qualifier ("ved"), "w!" == argv[0], [PROMPTROW, 1], argv[[1:]]);
    return;
    }
}

private define _ved_ (argv)
{
  if (1 == length (argv))
    return;

  variable fname = argv[1];
  
  shell_pre_header (argv);

  smg->suspend ();
 
  loadfrom ("app/ved", "vedInit", NULL, &on_eval_err);

  variable ved = __get_reference ("ved");
  (@ved) (fname);

  smg->resume ();

  shell_post_header ();
  
  draw (qualifier ("ved"));
}

private define _search_ (argv)
{
  variable fname = "/tmp/a.list";
  variable issudo = qualifier ("issudo");
  variable env = proc->getdefenv ();
  variable p = proc->init (issudo, 1, 1);
 
  shell_pre_header (argv);

  argv = [SLSH_BIN, p.loadcommand, argv];

  if (issudo)
    {
    p.stdin.in = widg->getpasswd ();
    argv = [qualifier ("sudobin"), "-S", "-E", "-p", "", argv];
    }
  
  p.stdout.file = fname;
  p.stdout.wr_flags = ">|";
  p.stderr.file = STDOUT;
  p.stderr.wr_flags = ">>";

  variable status = p.execve (argv, env, NULL);

  SHELLLASTEXITSTATUS = status.exit_status;
  
  ifnot (SHELLLASTEXITSTATUS)
    { 
    smg->suspend ();
 
    loadfrom ("app/ved", "vedInit", NULL, &on_eval_err);

    variable ved = __get_reference ("ved");
    (@ved) (fname);

    smg->resume ();
    }

  shell_post_header ();

  draw (qualifier ("ved"));
}

private define execute (argv)
{
  variable header = strlen (argv[0]) > 1;
  variable issudo = qualifier ("issudo");
  variable env = proc->getdefenv ();
  variable p = proc->init (issudo, 1, 1);
  
  if  (header) 
    shell_pre_header (argv);

  argv = [SLSH_BIN, p.loadcommand, argv];

  if (issudo)
    {
    p.stdin.in = widg->getpasswd ();
    argv = [qualifier ("sudobin"), "-S", "-E", "-p", "", argv];
    }
  
  p.stdout.file = STDOUT;
  p.stdout.wr_flags = ">>|";
  p.stderr.file = STDOUT;
  p.stderr.wr_flags = ">>";

  variable status = p.execve (argv, env, NULL);

  SHELLLASTEXITSTATUS = status.exit_status;
 
  if (header)
    shell_post_header ();

  draw (qualifier ("ved"));
}

private define _exit_ ()
{
  variable rl = qualifier ("rl");

  ifnot (NULL == rl)
    rline->writehistory (rl.history[[1:]], rl.histfile);

  exit_me (0);
}

private define _echo_ ()
{
  variable argv = ();
 
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
  a["q"] = @Argvlist_Type;
  a["q"].func = &_exit_;
  a["ved"] = @Argvlist_Type;
  a["ved"].func = &_ved_;
  a["search"] = @Argvlist_Type;
  a["search"].func = &_search_;
  a["cd"] = @Argvlist_Type;
  a["cd"].func = &_cd_;
  a["search"].dir = STDDIR + "/com/search";
  a["@"] = @Argvlist_Type;
  a["@"].func = &edit;
  a["edit"] = @Argvlist_Type;
  a["edit"].func = &edit;
  a["w"] = @Argvlist_Type;
  a["w"].func = &_write_;
  a["w!"].func = &_write_;
  
  return a;
}

private define filtercommands (ar)
{
  ar = ar[where (1 < strlen (ar))];
  return ar;
}

private define filterargs (args, type, desc)
{
  return [args, "--sudo"], [type, "void"], [desc, "execute command as superuser"];
}

define shell (v)
{
  variable rl = rline->init (&init_commands;
    histfile = "$HOME/.ashellhistory"$,
    filtercommands = &filtercommands,
    filterargs = &filterargs,
    on_lang = &toplinedr,
    on_lang_args = " -- shell --");
 
  iarg = length (rl.history);
  
  topline (" -- shell --");

  ashell_settype (v, STDOUT, VED_ROWS, NULL);

  VED_CB = v;

  shell_post_header ();

  draw (v);

  forever
    {
    rline->set (rl);
    rline->readline (rl;ved = v);
    topline (" -- shell --");
    }
}
