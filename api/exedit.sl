define _edit_ (argv)
{
  _precom_ ();

  variable b = get_cur_buf ();
 
  viewfile (b, b._fname, b.ptr, b._ii);
}
