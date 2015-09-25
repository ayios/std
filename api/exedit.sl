define __edit (argv)
{
  precom ();

  variable b = get_cur_buf ();

  viewfile (b, b._fname, b.ptr, b._ii);
}
