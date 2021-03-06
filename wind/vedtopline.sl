load.from ("wind", "topline", NULL;err_handler = &__err_handler__);

private variable clr = getuid () ? 16 : 1;

private define _line_ (str)
{
  variable b = get_cur_buf ();

  @str += "(" + string (_stkdepth ()) + ")";
  @str += sprintf (" ftype (%s) LANG (%s) ", get_cur_buf ()._type,
    input->getmapname ());

  return b;
}

define topline (str)
{
  () = _line_ (&str);

  _topline_ (&str, COLUMNS);
  smg->atrcaddnstr (str, clr, 0, 0, COLUMNS);
}

define toplinedr (str)
{
  variable b = _line_ (&str);

  _topline_ (&str, COLUMNS);
  smg->atrcaddnstrdr (str, clr, 0, 0, b.ptr[0], b.ptr[1], COLUMNS);
}
