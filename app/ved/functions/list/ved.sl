define ved (s, fname)
{
  variable mys = struct
    {
    fname = fname,
    lnr = 1,
    col = 0,
    };

  list_set (s, mys);

  clear (s, 1, LINES);

  smg->hlregion (VED_INFOCLRBG, s.rows[0] - 1, 0, 1, COLUMNS);
 
  s.draw ();

  variable func = get_func ();

  if (func)
    {
    VEDCOUNT = get_count ();
  
    (@pagerf[string (func)]) (s);

    (@list_pagerf[string (func)]) (s);
    }

  if (VED_DRAWONLY)
    return;

  toplinedr (" -- pager --");
 
  s.vedloop ();
}
