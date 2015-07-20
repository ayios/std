private define mainloop ()
{
  forever
    {
    rline->set (RLINE);
    rline->readline (RLINE);
    topline (" -- shell --" + " depth ("+ string (_stkdepth ())+ ")");
    }
}

define shell ()
{
  ashell_settype (SHELL_VED, STDOUT, VED_ROWS, NULL);
  ashell_settype (OUTBG, STDOUTBG, VED_ROWS, NULL);
  
  VED_CB = SHELL_VED;

  VED_CB._fd = STDOUTFD;
  OUTBG._fd = STDOUTFDBG;

  setbuf (VED_CB._absfname);
  
  ifnot (fileexists (TEMPDIR + "/" + strftime ("%m_%d-intro")))
    {
    runcom (["intro"], NULL);
    () = writestring (TEMPDIR + "/" + strftime ("%m_%d-intro"), "ok");
    }

  topline (" -- shell --");

  shell_post_header ();
 
  draw (VED_CB);
 
  mainloop ();
}

define on_eval_err (err, code)
{
  err = strjoin (err, "\n");

  tostderr (err);
  tostdout (err);

  SHELLLASTEXITSTATUS = code;

  shell_post_header ();

  draw (VED_CB);

  mainloop ();
}
