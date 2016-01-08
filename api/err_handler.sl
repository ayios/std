define __err_handler__(__r__)
{
  if (APP.os)
    $1 = open (Dir->Vget ("TEMPDIR") + "/_" + APP.appname + "_.initerr", O_WRONLY|O_CREAT, S_IRWXU);

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
