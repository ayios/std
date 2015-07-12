variable app = "ved";
variable stdouttype = "txt";
variable VED_LIB = 0;
variable loaddir = path_dirname (__FILE__) + "/functions";

loaddir = loaddir + char (path_get_delimiter) + loaddir + "/share";

define on_eval_err (err, code)
{
  () = array_map (Integer_Type, &fprintf, stderr, "%s\n", err);
  exit (code);
}

loadfrom ("os", "appclient", NULL, &on_eval_err);

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
