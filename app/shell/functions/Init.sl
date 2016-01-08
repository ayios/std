load.from (APP.loaddir, "vars", NULL;err_handler = &__err_handler__);

load.from ("crypt", "cryptInit", NULL;err_handler = &__err_handler__);

define __on_err (err, code)
{
  % A TABLE ERR
  IO.tostderr (err);
}

define on_wind_change (w)
{
  topline (" -- shell --");
  __vsetbuf (w.frame_names[w.cur_frame]);
  STDOUTFD = get_cur_buf._fd;
}

define on_wind_new (w)
{
  variable o = Dir->Vget ("TEMPDIR") + "/" + string (Env->Vget ("PID")) + "_" + APP.appname +
    string (_time)[[5:]] + "_stdout.shell";

  variable oved =init_ftype (APP.stdouttype);

  oved._fd = initstream (o);

  (@__get_reference (APP.stdouttype + "_settype")) (oved, o, VED_ROWS, NULL);

  __vsetbuf (o);

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
  new_frame (Dir->Vget ("TEMPDIR") + "/" + string (Env->Vget ("PID")) + "_" + APP.appname +
    string (_time)[[5:]] + "_stdout.shell");

  variable b = get_cur_buf ();
  b._fd = initstream (b._abspath;err_func = &__on_err);

  STDOUTFD = b._fd;
}

define intro ();

load.from (APP.loaddir, "initrline", NULL;err_handler = &__err_handler__);

load.from ("com/intro", "intro", NULL;err_handler = &__err_handler__);

define shell ();

define init_shell ()
{
  if (-1 == access (STACKFILE, F_OK))
    String.write (STACKFILE, "STACK = {}");

  load.from (APP.loaddir, "shell", NULL;err_handler = &__err_handler__);

  shell ();
}
