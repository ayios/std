define _messages_ (argv)
{
  variable ved = @get_cur_buf ();

  viewfile (ERR_VED, "MSG", NULL, NULL);
 
  variable f = __get_reference ("setbuf");

  (@f) (ved._absfname);

  draw_wind ();
}

