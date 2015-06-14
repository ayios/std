loadfrom ("parse", "is_arg", NULL, &on_eval_err);

private variable SUDO_BIN = which ("sudo");

private define _glob_ (argv)
{
  variable
    i,
    ar,
    dirname,
    basename,
    glob = 0,
    args = argv[[1:]];

  argv = [argv[0]];

  _for i (0, length (args) - 1)
    {
    if ('-' == args[i][0])
      {
      argv = [argv, args[i]];
      continue;
      }

    if ('*' == args[i][-1])
      {
      glob = 1;
      basename = path_basename (args[i]);
      dirname = evaldir (path_dirname (args[i]));
      ar = listdir (dirname);

      if ("*" != basename)
        ar = ar[wherenot (array_map (Char_Type, &strncmp, ar, basename,
          strlen (basename) - 1))];

      ar = ar[array_sort (ar)];

      argv = [argv, array_map (String_Type, &path_concat, dirname, ar)];
      continue;
      }
 
   if (string_match (args[i], "*"))
      {
      glob = 1;
      basename = path_basename (args[i])[[1:]];
      dirname = evaldir (path_dirname (args[i]));
      ar = listdir (dirname);

      ar = ar[where (array_map (Integer_Type, &string_match, ar,
            sprintf ("%s$", basename) ))];

      ar = ar[array_sort (ar)];

      argv = [argv, array_map (String_Type, &path_concat, dirname, ar)];
      continue;
      }
 
   argv = [argv, args[i]];
   }
 
  return argv;
}

private define _execProc_Type_ (func, argv)
{
  variable issudo = 0;
  variable passwd = "";
  variable index = is_arg ("--sudo", argv);

  ifnot (NULL == index)
    {
    issudo = 1;
    argv[index] = NULL;
    argv = argv[wherenot (_isnull (argv))];
    passwd = widg->getpasswd ();
    
    variable p;
    variable status;
 
    () = system (sprintf ("%s -K 2>/dev/null", SUDO_BIN));
    
    p = proc->init (1, 1, 1);

    p.stdin.in = passwd;

    status = p.execv ([SUDO_BIN, "-S", "-p", "", "echo"], NULL);
    
    if (NULL == status || status.exit_status)
      {
      send_msg_dr (p.stderr.out, 1, NULL, NULL);
      passwd = NULL;
      }
    }
 
  argv = _glob_ (argv);
  
  (@func) (argv;;struct {@__qualifiers (), sudobin = SUDO_BIN, issudo = issudo, passwd = passwd});
}

private define _execProc_Type_nosudo (func, argv)
{
  argv = _glob_ (argv);
  (@func) (argv;;__qualifiers ());
}

static variable proctype;

ifnot (NULL == SUDO_BIN)
  proctype = &_execProc_Type_;
else
  proctype = &_execProc_Type_nosudo;
