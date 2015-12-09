private define mainloop ()
{
  forever
    {
    rline->set (get_cur_rline ());
    rline->readline (get_cur_rline ());
    topline (" -- shell --" + " depth ("+ string (_stkdepth ())+ ")");
    }
}

define shell ()
{
  __vsetbuf (OUT_VED._abspath);

  ifnot (fileexists (Dir.vget ("TEMPDIR") + "/" + strftime ("%m_%d-intro")))
    {
    runcom (["intro"], NULL);
    () = writestring (Dir.vget ("TEMPDIR") + "/" + strftime ("%m_%d-intro"), "ok");
    }

  topline (" -- shell --");

  shell_post_header ();

  draw (OUT_VED);

  mainloop ();
}

define __err_handler__ (__r__)
{
  IO.tostderr (__r__.err);
  IO.tostdout (__r__.err);

  SHELLLASTEXITSTATUS = 1;

  shell_post_header ();

  draw (get_cur_buf ());

  mainloop ();
}
