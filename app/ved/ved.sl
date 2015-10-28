loadfrom ("api", "apiInit", 1, &on_eval_err);

APP = api->init (__FILE__;
  vedrline = 1,
  stdout = 0,
  vedlib = 0,
  excom = 1,
  os = 0,
  );

loadfrom ("api", "clientapi", NULL, &on_eval_err);

define tostdout (str)
{
  tostderr (str);
}

define on_eval_err (err, code)
{
  variable msg;

  if (Array_Type == typeof (err))
    {
    msg = substr (err[0], 1, COLUMNS);
    err = strjoin (err, "\n");
    }
  else
    msg = substr (err, 1, COLUMNS);

  tostderr (err);

  variable b = get_cur_buf ();

  ifnot (NULL == b)
    {
    send_msg_dr (msg, 1, NULL, NULL);
    b.vedloop ();
    }
  else
    exit_me (code);
}

private variable __stdin = any (__argv == "-");
private variable fn;
private variable ft;

if (1 == __argc)
  SCRATCH_VED.ved (SCRATCH);
else
  {
  ft = is_arg ("--ft=", __argv);
  ifnot (NULL == ft)
    {
    ft = strchop (__argv[ft], '=', 0);
    if (2 == length (ft))
      {
      ft = ft[1];

      ifnot (any (ft == assoc_get_keys (FTYPES)))
        ft = NULL;
      }
    }

  if (__stdin)
    {
    if (ft == NULL)
      ft = "txt";

    fn = VED_DIR + "/__stdin." + ft;
    __stdin = read_fd (fileno (stdin));
    ifnot (NULL == __stdin)
      () = writestring (fn, __stdin);
    }
  else
    {
    fn = __argv[-1];
    if (NULL == ft)
      ft = get_ftype (fn);
    }

  init_ftype (ft).ved (fn);
  }
