define send_exit ()
{
  sock->send_int (SOCKET, GO_ATEXIT);
}

define exit_me (exit_code)
{
  at_exit ();
  send_exit ();
  exit (exit_code);
}

define on_eval_err (err, code)
{
  at_exit ();
  () = array_map (Integer_Type, &fprintf, stderr, "%s\n", err);
  send_exit ();
  exit (code);
}
