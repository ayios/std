define send_exit ()
{
  Sock.send_int (SOCKET, GO_ATEXIT);
}

define exit_me (exit_code)
{
  at_exit ();
  send_exit ();
  exit (exit_code);
}

define __err_handler__ (__r__)
{
  at_exit ();

  variable err = qualifier ("msg");
  ifnot (NULL ==  err)
    IO.tostderr (err);

  variable code = 1;
  if (Integer_Type == typeof (__r__))
    code = __r__;
  else
    IO.stderr (__r__.err);

  send_exit ();
  exit (code);
}
