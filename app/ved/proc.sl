loadfrom ("api", "apiInit", 1, &on_eval_err);

APP = api->init (__FILE__;
  stderr = 1,
  stdout = 0,
  scratch = 1,
  stdouttype = NULL,
  ved = 0,
  shell = 1,
  os = 1,
  );

public variable VED_CB;

define init_ftype ();

loadfrom ("api", "clientapi", NULL, &on_eval_err);

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
  fname = VED_SCRATCH_BUF;
else
  fname = __argv[-1];

private variable s_ = init_ftype (get_ftype (fname));

s_.ved (fname);
