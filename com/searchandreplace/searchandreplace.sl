loadfrom ("search", "searchandreplace", "search", &on_eval_err);
importfrom ("std", "fork", NULL, &on_eval_err);
loadfrom ("posix", "read_fd", NULL, &on_eval_err);
loadfrom ("stdio", "writefile", NULL, &on_eval_err);
loadfrom ("dir", "fswalk", NULL, &on_eval_err);
loadfrom ("proc", "procInit", NULL, &on_eval_err);

variable
  MAXDEPTH = 1,
  HIDDENDIRS = 0,
  HIDDENFILES = 0,
  SUBSTITUTEARRAY = Any_Type[0],
  WHENSUBST = NULL,
  WHENWRITE = NULL,
  BACKUP = NULL,
  SUFFIX = "~",
  GLOBAL = NULL,
  SUBSTITUTE = NULL,
  PAT = NULL,
  NEWLINES = 0,
  INPLACE = NULL,
  NUMCHANGES,
  DIFFEXEC = which ("diff"),
  RECURSIVE = NULL,
  EXIT_CODE = 0;

define assign_func (func)
{
  switch (func)

    {
    case "rmspacesfromtheend":
      PAT = "(.)\\s+$";
      SUBSTITUTE = "\\1";
      WHENSUBST = 1;
      WHENWRITE = 1;
      INPLACE = 1;
      GLOBAL = 1;
    }
}

define unified_diff (lines, fname)
{
  variable
    status,
    p = proc->init (1, 1, 1);

  p.stdin.in = strjoin (lines, "\n") + "\n";

  status = p.execv ([which ("diff"), "-u", fname, "-"], NULL);

  if (NULL == status)
    return NULL;

  ifnot (2 > status.exit_status)
    return NULL;
 
  ifnot (status.exit_status)
    return NULL;
 
  return p.stdout.out;
}

private define sed (file, s)
{
  variable
    ar,
    err,
    undiff,
    retval,
    st = qualifier ("st", stat_file (file));
   
  ifnot (stat_is ("reg", st.st_mode))
    {
    tostderr (sprintf
      ("cannot operate on special file `%s': Operation not permitted", file));
    return;
    }
  
  ar = readfile (file);
  
  ifnot (length (ar))
    return;
  
  s.fname = file;

  retval = search->search_and_replace (s, readfile (file));

  if (NULL == retval)
    {
    err = ();
    tostderr (err);
    EXIT_CODE = 1;
    }
  else if (0 == retval)
    ifnot (NULL == INPLACE)
      {
      ar = ();

      if (NULL == WHENWRITE)
        {
        undiff = unified_diff (ar, file);
        undiff = NULL == undiff ? NULL : strchop (undiff, '\n', 0);
      
        retval = ask ([
          sprintf ("@write changes to `%s' ? y/n", file),
          NULL == undiff ? "No diff available"
                         : ["    UNIFIED DIFF", repeat ("_", COLUMNS), undiff]
          ], ['y', 'n']);
 
        if ('n' == retval)
          return;
          }
 
      try
        {
        writefile (ar, file);
        tostdout (sprintf ("%s: was written, with %d changes", file, s.numchanges));
        }
      catch AnyError:
        {
        array_map (&tostderr, ["WRITTING ERROR", exception_to_array ()]);
        }
      }
}

private define file_callback (file, st, type)
{
  ifnot (HIDDENFILES)
    if ('.' == path_basename (file)[0])
      return 1;

  sed (file, type;st = st);

  return 1;
}

private define dir_callback (dir, st)
{
  ifnot (HIDDENDIRS)
    if ('.' == path_basename (dir)[0])
      return 0;

  if (length (strtok (dir, "/")) > MAXDEPTH)
    return 0;

  return 1;
}

define main ()
{
  variable
    i,
    fs,
    ia,
    err,
    files,
    maxdepth = 0,
    c = cmdopt_new (&_usage);

  c.add ("dont-ask-when-subst", &WHENSUBST);
  c.add ("dont-ask-when-write", &WHENWRITE);
  c.add ("hidden-dirs", &HIDDENDIRS);
  c.add ("hidden-files", &HIDDENFILES);
  c.add ("maxdepth", &maxdepth;type = "int");
  c.add ("rmspacesfromtheend", &assign_func, "rmspacesfromtheend");
  c.add ("pat", &PAT;type = "string");
  c.add ("sub", &SUBSTITUTE;type = "string");
  c.add ("in-place", &INPLACE);
  c.add ("recursive", &RECURSIVE);
  c.add ("backup", &BACKUP);
  c.add ("suffix", &SUFFIX;type = "string");
  c.add ("global", &GLOBAL);
  c.add ("v|verbose", &verboseon);
  c.add ("help", &_usage);
  c.add ("info", &info);

  i = c.process (__argv, 1);

  if (i == __argc)
    {
    tostderr (sprintf ("%s: argument (filename) is required", __argv[0]));
    exit_me (1);
    }
 
  if (NULL == PAT || NULL == SUBSTITUTE)
    {
    tostderr ("--pat and --sub can not be NULL");
    exit_me (1);
    }

  variable type = search->init (PAT, SUBSTITUTE;global = GLOBAL,
    askwhensubst = NULL == WHENSUBST ? 1 : 0);

  if (NULL == type)
    {
    tostderr (__get_exception_info.message);
    exit_me ();
    }

  if (NULL == DIFFEXEC)
    if (NULL == WHENWRITE)
      tostderr ("diff executable couldn't be found, unified diff will be disabled");

  if (NULL == RECURSIVE)
    maxdepth = 1;
  else
    ifnot (maxdepth)
      maxdepth = 1000;
    else
      maxdepth++;

  files = __argv[[i:]];
  files = files[where (strncmp (files, "--", 2))];

  _for i (0, length (files) - 1)
    {
    if (-1 == access (files[i], F_OK))
      {
      tostderr (sprintf ("%s: No such file", files[i]));
      continue;
      }

    if (-1 == access (files[i], R_OK))
      {
      tostderr (sprintf ("%s: Is not readable", files[i]));
      continue;
      }

    if (INPLACE)
      if (-1 == access (files[i], W_OK))
        {
        tostderr (sprintf ("%s: Is not writable", files[i]));
        continue;
        }

    if (_isdirectory (files[i]))
      {
      fs = fswalk_new (&dir_callback, &file_callback;fargs = {type});
      MAXDEPTH = length (strtok (files[i], "/")) + maxdepth;
      fs.walk (files[i]);

      continue;
      }

    sed (files[i], type);
    }

  exit_me (EXIT_CODE);
}