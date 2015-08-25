define on_eval_err (err, code)
{
  if (APP.os)
    $1 = open (TEMPDIR + "/_" + APP.appname + "_.initerr", O_WRONLY|O_CREAT, S_IRWXU);

  at_exit ();
 
  () = array_map (Integer_Type, &fprintf, stderr, "%s\n", err);

  exit (code);
}
