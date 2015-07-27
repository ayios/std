define _osappnew_ (s)
{
}

define _osapprec_ (s)
{
}

define go_idled ()
{
  at_exit ();
  exit (0);
}

define on_eval_err (err, code)
{
  at_exit ();
  () = array_map (Integer_Type, &fprintf, stderr, "%s\n", err);
  exit (code);
}

define exit_me (exit_code)
{
  at_exit ();
  exit (exit_code);
}
