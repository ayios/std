loadfrom ("string", "modeconversion", NULL, &on_eval_err);

define main ()
{
  variable
    files,
    retval,
    exit_code = 0,
    mode = NULL,
    i,
    c = cmdopt_new (&_usage);

  c.add ("mode", &mode;type = "str");
  c.add ("v|verbose", &verboseon);
  c.add ("help", &_usage);
  c.add ("info", &info);

  i = c.process (__argv, 1);

  if (__argc == i)
    {
    tostderr (sprintf ("%s: a fifo name is required as argument", __argv[0]));
    exit_me (1);
    }

  files = __argv[[i:]];
  files = files[where (strncmp (files, "--", 2))];

  ifnot (NULL == mode)
    {
    mode = mode_conversion (mode);
    if (NULL == mode)
      {
      variable err = ();
      tostderr (err);
      exit_me (1);
      }
    }
  else
    mode = 420;

  _for i (0, length (files) - 1)
    {
    retval = mkfifo (files[i], mode);

    if (-1 == retval)
      {
      tostderr (sprintf ("Couldn't create fifo: %s", errno_string (errno)));
      exit_code = -1;
      }
    else
      tostdout (sprintf ("%s: fifo created, with access %s", files[i],
      stat_mode_to_string (stat_file (files[i]).st_mode)));
    }

  exit_me (exit_code);
}


