loadfrom ("string", "repeat", NULL, &on_eval_err);
loadfrom ("wind", "topline", NULL, &on_eval_err);

private variable clr = getuid () ? 2 : 1;

define toplinedr (str)
{
  str += sprintf (" LANG (%s) ", input->getmapname ());

  _topline_ (&str, COLUMNS);
 
  smg->atrcaddnstrdr (str, clr, 0, 0, qualifier ("row", PROMPTROW),
     qualifier ("col", 0), COLUMNS);
}

define topline (str)
{
  str += sprintf (" LANG (%s) ", input->getmapname ());
 
  _topline_ (&str, COLUMNS);
 
  smg->atrcaddnstr (str, clr, 0, 0, COLUMNS);
}
