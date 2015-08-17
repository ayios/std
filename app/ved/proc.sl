loadfrom ("api", "apiInit", 1, &on_eval_err);

APP = api->init (__FILE__;
  vedrline = 1,
  stdout = 0,
  vedlib = 0,
  excom = 1,
  os = 1,
  );

define tostdout ();

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

if (1 == __argc)
  SCRATCH_VED.ved (SCRATCH);
else
  {
  variable fname = __argv[-1];
  init_ftype (get_ftype (fname)).ved (fname);
  }
