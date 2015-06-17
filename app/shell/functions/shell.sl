private define mainloop (rl, vd)
{
  forever
    {
    rline->set (rl);
    rline->readline (rl;ved = vd);
    topline (" -- shell --" + " depth ("+ string (_stkdepth ())+ ")");
    }
}

define shell (vd, rl)
{
  ashell_settype (vd, STDOUT, VED_ROWS, NULL);
  ashell_settype (SCRATCH, SCRATCHFILE, VED_ROWS, NULL);
  ashell_settype (MSG, STDERR, VED_ROWS, NULL);

  (@rl.argvlist["intro"].func) (["intro"];ved = vd, rl = rl);

  setbuf (vd._absfname);

  topline (" -- shell --");

  shell_post_header ();
 
  draw (vd);
 
  mainloop (rl, vd);
}

define on_eval_err (err, code)
{
  err = strjoin (err, "\n");

  tostderr (err);
  tostdout (err);

  SHELLLASTEXITSTATUS = code;

  variable vd = init_ftype ("ashell");
 
  ashell_settype (vd, STDOUT, VED_ROWS, NULL);
 
  setbuf (vd._absfname);
 
  shell_post_header ();

  draw (vd);

  variable rl = rlineinit ();

  mainloop (rl, vd);
}
