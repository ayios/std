loadfrom ("string", "repeat", NULL, &on_eval_err);
loadfrom ("wind", "topline", NULL, &on_eval_err);

private variable clr = getuid () ? 16 : 1;

define topline (str)
{
  str += "(" + string (_stkdepth ()) + ")";
  str += sprintf (" ftype (%s) LANG (%s) ", VED_CB._type,
    input->getmapname ());

  _topline_ (&str, COLUMNS);
  smg->atrcaddnstr (str, clr, 0, 0, COLUMNS);
}

define toplinedr (str)
{
  str += "(" + string (_stkdepth ()) + ")";
  str += sprintf (" ftype (%s) LANG (%s) ", VED_CB._type,
    input->getmapname ());

  _topline_ (&str, COLUMNS);
  smg->atrcaddnstrdr (str, clr, 0, 0, VED_CB.ptr[0],
    VED_CB.ptr[1], COLUMNS);
}
