load.from ("string", "modeconversion", NULL;err_handler = &__err_handler__);
load.from ("sys", "modetoint", NULL;err_handler = &__err_handler__);
load.from ("dir", "fswalk", NULL;err_handler = &__err_handler__);

private variable EXIT_CODE = 0;

private define chmod_it (file, mode)
{
  variable
    strmode,
    st = qualifier ("st", stat_file (file)),
    strcurmode = stat_mode_to_string (st.st_mode),
    cur_mode = modetoint (st.st_mode);

  if (-1 == chmod (file, mode))
    {
    IO.tostderr (sprintf (
      "%s: could not change mode bits, ERRNO: %s", file, errno_string (errno)));
    EXIT_CODE = 1;
    }
  else
    {
    strmode = stat_mode_to_string (stat_file (file).st_mode);
    if (cur_mode == mode)
      IO.tostdout (sprintf ("mode of `%s' retained as 0%o (%s)",
         file, mode, strmode));
    else
      IO.tostdout (sprintf ("mode of `%s' changed from 0%o (%s) to 0%o (%s)",
         file, cur_mode, strcurmode, mode, strmode));
    }
}

private define file_callback (file, st, mode)
{
  if (stat_is ("lnk", st.st_mode))
    return 1;

  chmod_it (file, mode);
  return 1;
}

private define dir_callback (dir, st, mode)
{
  if (NULL == mode)
    return 1;
 
  if (stat_is ("lnk", st.st_mode))
    return 1;

  chmod_it (dir, mode);
  return 1;
}

define main ()
{
  variable
    i,
    fs,
    files,
    strmode,
    directories = NULL,
    mode = NULL,
    recursive = NULL,
    c = cmdopt_new (&_usage);
 
  c.add ("mode", &mode;type = "str");
  c.add ("recursive", &recursive);
  c.add ("directories", &directories);
  c.add ("v|verbose", &verboseon);
  c.add ("help", &_usage);
  c.add ("info", &info);

  i = c.process (__argv, 1);

  if (i == __argc)
    {
    IO.tostderr (sprintf ("%s: it requires a filename", __argv[0]));
    exit_me (1);
    }
 
  if (NULL == mode)
    {
    IO.tostderr (sprintf ("%s: --mode was not given", __argv[0]));
    exit_me (1);
    }

  mode = mode_conversion (mode);

  if (NULL == mode)
    {
    variable err = ();
    IO.tostderr (err);
    exit_me (1);
    }
 
  files = __argv[[i:]];
  files = files[where (strncmp (files, "--", 2))];
 
  _for i (0, length (files) - 1)
    {
    if (-1 == access (files[i], F_OK))
      {
      IO.tostderr (sprintf ("%s: No such file", files[i]));
      continue;
      }

    if (_isdirectory (files[i]))
      {
      ifnot (NULL == recursive)
        {
        fs = fswalk_new (&dir_callback, &file_callback;
          dargs = {NULL == directories ? NULL : mode}, fargs = {mode});

        fs.walk (files[i]);
        }
      else
        if (stat_is ("lnk", stat_file (files[i]).st_mode))
          continue;
        else
          chmod_it (files[i], mode);

      continue;
      }
 
    if (stat_is ("lnk", stat_file (files[i]).st_mode))
      continue;

    chmod_it (files[i], mode);
    }

  exit_me (EXIT_CODE);
}
