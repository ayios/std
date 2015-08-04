define _myframesize_ (frames)
{
  variable f = Array_Type[2];
  f[0] = [1:LINES - 9];
  f[1] = [LINES - 8:LINES - 3];
  return f;
}

define ved (s, fname)
{
  VED_MAXFRAMES = 2;
  wind_init ("a", 2;force, framesize_func = &_myframesize_);

  variable mys = struct
    {
    fname = fname,
    lnr = 1,
    col = 0,
    };

  list_set (s, mys);

  smg->hlregion (VED_INFOCLRBG, s.rows[0] - 1, 0, 1, COLUMNS);
 
  s.draw ();

  preloop (s);

  toplinedr (" -- pager --");
 
  s.vedloop ();
}
