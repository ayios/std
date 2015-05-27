loadfrom ("dir", "are_same_files", NULL, &on_eval_err);

define _echo_ (argv)
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

define _cd_ (argv)
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

define _search_ (argv)
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

define _ved_ ()
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

define _which_ ()
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
