private define _getpasswd_ ()
{
  variable passwd;

  ifnot (NULL == HASHEDDATA)
    {
    passwd = os->confirmpasswd (HASHEDDATA);
    if (NULL == passwd)
      send_msg_dr ("Authentication error", 1, NULL, NULL);
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

    ifnot (UID)
      issudo = 0;
    else
      passwd = _getpasswd_ ();
    }
 
  argv = _glob_ (argv);
 
  (@func) (argv;;struct {@__qualifiers (), issudo = issudo, passwd = passwd});
}

static variable proctype;

proctype = &_execProc_Type_;
