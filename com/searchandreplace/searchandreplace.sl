Use ("Subst");

load.module ("std", "pcre", NULL;err_handler = &__err_handler__);
load.module ("std", "fork", NULL;err_handler = &__err_handler__);

Subst->New (;methods = "new,exec,new_lines,assign,askonsubst",
   funcs = ["__new__", "exec__", "new_lines__", "assign_", "askonsubst______"],
   refs = [NULL, NULL, NULL, NULL, NULL]);

load.from ("stdio", "writefile", NULL;err_handler = &__err_handler__);
load.from ("__/FS", "walk", NULL;err_handler = &__err_handler__);
load.from ("proc", "procInit", NULL;err_handler = &__err_handler__);
load.from ("file", "fileis", NULL;err_handler = &__err_handler__);

variable
  MAXDEPTH = 1,
  HIDDENDIRS = 0,
  HIDDENFILES = 0,
  EXCLUDEDIRS = {},
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
  DIFFEXEC = Sys.which ("diff"),
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
  lines = strjoin (lines, "\n") + "\n";

  variable
    status,
    isbigin = strbytelen (lines) >= 256 * 256,
    p = proc->init (isbigin ? 0 : 1, 1, 1),
    com = [Sys.which ("diff"), "-u", fname, "-"];

  if (isbigin)
    {
    variable fn = Dir->Vget ("TEMPDIR") + "/" + path_basename (fname) + "_" + string (Env->Vget ("PID")) + "_" +
      string (_time)[[5:]];
    writefile (lines, fn);
    com[-1] = fn;
    }
  else
    p.stdin.in = lines;

  status = p.execv (com, NULL);

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
    retval;

  ar = IO.readfile (file);

  ifnot (length (ar))
    return;

  s.fname = file;

  s.askwhensubst = NULL == WHENSUBST;
  retval = Subst.exec (s, IO.readfile (file));

  if (NULL == retval)
    {
    err = ();
    IO.tostderr (err);
    EXIT_CODE = 1;
    }
  else if (0 == retval)
    ifnot (NULL == INPLACE)
      {
      ar = ();

      if (NULL == WHENWRITE)
        {
        undiff = unified_diff (ar, file);
        undiff = NULL == undiff ? "No diff available" :
          ["    UNIFIED DIFF", repeat ("_", COLUMNS), strchop (undiff, '\n', 0)];

        retval = ask ([
          sprintf ("@write changes to `%s' ? y[es]/n[o]", file),
          undiff,
          ], ['y', 'n']);

        if ('n' == retval)
          return;
          }

      try
        {
        writefile (ar, file);
        IO.tostdout (sprintf ("%s: was written, with %d changes", file, s.numchanges));
        }
      catch AnyError:
        {
        IO.tostderr (["WRITTING ERROR", Err.efmt (NULL)]);
        }
      }
}

private define sanitycheck (file, st)
{
  if (INPLACE)
    if (-1 == access (file, W_OK))
      {
      IO.tostderr (sprintf ("%s: Is not writable", file));
      return -1;
      }

  ifnot (stat_is ("reg", st.st_mode))
    {
    IO.tostderr (sprintf
      ("cannot operate on special file `%s': Operation not permitted", file));
    return -1;
    }

  if (1 == iself (file))
    {
    IO.tostderr (sprintf
      ("cannot operate on binary file `%s': Operation not permitted", file));
    return -1;
    }

  return 0;
}

private define file_callback (file, st, type)
{
  ifnot (HIDDENFILES)
    if ('.' == path_basename (file)[0])
      return 1;

  if (-1 == access (file, R_OK))
    {
    IO.tostderr (sprintf ("%s: Is not readable", file));
    return 1;
    }

  if (-1 == sanitycheck (file, st))
    return 1;

  sed (file, type);

  return 1;
}

private define dir_callback (dir, st)
{
  ifnot (HIDDENDIRS)
    if ('.' == path_basename (dir)[0])
      return 0;

  if (any (path_basename (dir) == EXCLUDEDIRS))
    return 0;

  if (length (strtok (dir, "/")) > MAXDEPTH)
    return 0;

  return 1;
}

define main ()
{
  variable
    i,
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
  c.add ("excludedir", &EXCLUDEDIRS;type = "string", append);
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
    IO.tostderr (sprintf ("%s: argument (filename) is required", __argv[0]));
    exit_me (1);
    }

  if (NULL == PAT || NULL == SUBSTITUTE)
    {
    IO.tostderr ("--pat and --sub can not be NULL");
    exit_me (1);
    }

  variable type = Subst.new (PAT, SUBSTITUTE;global = GLOBAL,
    askwhensubst = NULL == WHENSUBST);

  if (NULL == type)
    {
    err = ();
    IO.tostderr (err);
    exit_me (1);
    }

  EXCLUDEDIRS = list_to_array (EXCLUDEDIRS, String_Type);

  if (NULL == DIFFEXEC)
    if (NULL == WHENWRITE)
      IO.tostderr ("diff executable couldn't be found, unified diff will be disabled");

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
      IO.tostderr (sprintf ("%s: No such file", files[i]));
      continue;
      }

    if (-1 == access (files[i], R_OK))
      {
      IO.tostderr (sprintf ("%s: Is not readable", files[i]));
      continue;
      }

    if (_isdirectory (files[i]))
      {
      MAXDEPTH = length (strtok (files[i], "/")) + maxdepth;
      FS.walk (files[i], &dir_callback, &file_callback;fargs = {type});

      continue;
      }

    variable st = lstat_file (files[i]);

    if (-1 == sanitycheck (files[i], st))
      continue;

    sed (files[i], type);
    }

  exit_me (EXIT_CODE);
}
