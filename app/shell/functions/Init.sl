loadfile ("vars", NULL, &on_eval_err);

loadfrom ("crypt", "cryptInit", NULL, &on_eval_err);

define __on_err (err, code)
{
  % A TABLE ERR
  array_map (&tostderr, err);
}

define on_wind_change (w)
{
  topline (" -- shell --");
  setbuf (w.frame_names[w.cur_frame]);
  STDOUTFD = get_cur_buf._fd;
}

define on_wind_new (w)
{
  variable o = TEMPDIR + "/" + string (PID) + "_" + APP.appname +
    string (_time)[[5:]] + "_stdout.shell";
  
  variable oved =init_ftype (APP.stdouttype);

  oved._fd = initstream (o);

  (@__get_reference (APP.stdouttype + "_settype")) (oved, o, VED_ROWS, NULL);

  setbuf (o);
 
  STDOUTFD = oved._fd;

  topline (" -- shell --");

  shell_post_header ();
 
  (@__get_reference ("__initrline"));

  draw (oved);
}

define _change_frame_ (s)
{
  change_frame ();
  s = get_cur_buf ();
  STDOUTFD = s._fd;
}

define _del_frame_ (s)
{
  del_frame ();
  s = get_cur_buf ();
  STDOUTFD = s._fd;
}

define _new_frame_ (s)
{
  new_frame (TEMPDIR + "/" + string (PID) + "_" + APP.appname +
    string (_time)[[5:]] + "_stdout.shell");
  
  variable b = get_cur_buf ();
  b._fd = initstream (b._absfname;err_func = &__on_err);

  STDOUTFD = b._fd;
}

define intro ();

loadfile ("initrline", NULL, &on_eval_err);

loadfrom ("com/intro", "intro", NULL, &on_eval_err);

define shell ();

define init_shell ()
{
  if (-1 == access (STACKFILE, F_OK))
    writestring (STACKFILE, "STACK = {}");

  loadfile ("shell", NULL, &on_eval_err);

  shell ();
}
