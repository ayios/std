define __messages (argv)
{
  variable ved = @get_cur_buf ();

  viewfile (ERR_VED, "MSG", NULL, NULL);
  __vsetbuf (ved._abspath);

  __vdraw_wind ();
}

