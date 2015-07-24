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

  if (__is_initialized (&VED_CB))
    {
    send_msg_dr (msg, 1, NULL, NULL);
    VED_CB.vedloop ();
    }
  else
    exit_me (code);
}

variable fname;

if (1 == __argc)
  fname = SCRATCH;
else
  fname = __argv[-1];

private variable s_ = init_ftype (get_ftype (fname));

s_.ved (fname);
