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

private define sigalrm_handler (sig)
{
  variable fifofile = "/tmp/shellfifo";
  forever
    ifnot (access (fifofile, F_OK))
      break;
%  
  variable fd = open (fifofile, O_RDWR);
%  %variable func = get_str (fd);
%
%  variable func;
%  variable b;
%   () = read (fd, &b, 3);
%  tostderr ("s\nno?");
%  tostderr ("s\n" + b);
%
%  %if (func == "ask")
%  %  {
%    send_int (fd, 1);
%    variable ar =get_str_ar (fd);
%    send_int (fd, 1);
%    variable charar = get_int_ar (fd);
variable ar = ["gui", "remove", "bbbbbbba"];
variable charar = ['y', 'n'];
    variable chr = widg->ask (ar, charar, NULL);
    () = write (fd, "ok");
%%    send_int (chr);
   % }
}

private define execute (argv)
{
  variable header = strlen (argv[0]) > 1;
  variable issudo = qualifier ("issudo");
  variable env = [proc->getdefenv (), "PID=" + string (getpid ())];
  variable p = proc->init (issudo, 1, 1);
  
  if  (header) 
    shell_pre_header (argv);

  argv = [SLSH_BIN, p.loadcommand, argv];
  
  signal (SIGALRM, &sigalrm_handler);

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
    rline->writehistory (rl.history, rl.histfile);

  exit_me (0);
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
