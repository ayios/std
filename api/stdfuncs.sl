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

define __err_handler__(__r__)
{
  at_exit ();

  variable err = qualifier ("msg");
  ifnot (NULL ==  err)
    IO.tostderr (err);

  variable code = 1;
  if (Integer_Type == typeof (__r__))
    code = __r__;
  else
    IO.tostderr (__r__.err);

  exit (code);
}

define exit_me (exit_code)
{
  at_exit ();
  exit (exit_code);
}
