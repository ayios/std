loadfrom ("wind", "topline", NULL, &on_eval_err);

define toplinedr (str)
{
  str += sprintf (" (OSADMIN: %s) (PID: %d) ", OSUSR, PID);

  _topline_ (&str, COLUMNS);
 
  smg->atrcaddnstrdr (str, 3, 0, 0, qualifier ("row", PROMPTROW),
     qualifier ("col", 0), COLUMNS);
}

define topline (str)
{
  str += sprintf (" (OSADMIN: %s) (PID: %d) ", OSUSR, PID);
 
  _topline_ (&str, COLUMNS);
 
  smg->atrcaddnstr (str, 3, 0, 0, COLUMNS);
}
