define shell (vd, rl)
{
  topline (" -- shell --");
  
  ashell_settype (vd, STDOUT, VED_ROWS, NULL);
  ashell_settype (SCRATCH, SCRATCHFILE, VED_ROWS, NULL);
  ashell_settype (MSG, STDERR, VED_ROWS, NULL);

  setbuf (vd._absfname);

  shell_post_header ();

  draw (vd);

  forever
    {
    rline->set (rl);
    rline->readline (rl;ved = vd);
    topline (" -- shell --");
    }
}
