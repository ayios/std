load.from ("wind", "topline", NULL;err_handler = &__err_handler__);

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
