loadfrom ("wind", "topline", NULL, &on_eval_err);

private variable clr = getuid () ? 16 : 1;

define topline (str)
{
  str += "(" + string (_stkdepth ()) + ")";
  str += sprintf (" ftype (%s) LANG (%s) ", get_cur_buf ()._type,
    input->getmapname ());

  _topline_ (&str, COLUMNS);
  smg->atrcaddnstr (str, clr, 0, 0, COLUMNS);
}

define toplinedr (str)
{
  variable b = get_cur_buf ();
  
  str += "(" + string (_stkdepth ()) + ")";
  str += sprintf (" ftype (%s) LANG (%s) ", b._type, input->getmapname ());

  _topline_ (&str, COLUMNS);
  smg->atrcaddnstrdr (str, clr, 0, 0, b.ptr[0],
    b.ptr[1], COLUMNS);
}
