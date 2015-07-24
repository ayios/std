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
  setbuf (OUT_VED._absfname);
  
  ifnot (fileexists (TEMPDIR + "/" + strftime ("%m_%d-intro")))
    {
    runcom (["intro"], NULL);
    () = writestring (TEMPDIR + "/" + strftime ("%m_%d-intro"), "ok");
    }

  topline (" -- shell --");

  shell_post_header ();
 
  draw (OUT_VED);
 
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
