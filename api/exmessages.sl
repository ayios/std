define _messages_ (argv)
{
  variable ved = @get_cur_buf ();

  viewfile (ERR_VED, "MSG", NULL, NULL);
  __vsetbuf (ved._absfname);

  __vdraw_wind ();
}

