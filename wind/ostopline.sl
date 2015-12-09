load.from ("wind", "topline", NULL;err_handler = &__err_handler__);

define toplinedr (str)
{
  str += sprintf (" (OSADMIN: %s) (PID: %d) ", OSUSR, Env.vget ("PID"));

  _topline_ (&str, COLUMNS);

  smg->atrcaddnstrdr (str, 3, 0, 0, qualifier ("row", PROMPTROW),
     qualifier ("col", 0), COLUMNS);
}

define topline (str)
{
  str += sprintf (" (OSADMIN: %s) (PID: %d) ", OSUSR, Env.vget ("PID"));

  _topline_ (&str, COLUMNS);

  smg->atrcaddnstr (str, 3, 0, 0, COLUMNS);
}
