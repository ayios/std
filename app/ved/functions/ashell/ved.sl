define ved (s, fname)
{
  ashell_settype (s, fname, VED_ROWS, NULL);
 
  setbuf (s._absfname);
 
  write_prompt (" ", 0);

  s.draw ();

  variable func = get_func ();

  if (func)
    {
    VEDCOUNT = get_count ();
    (@pagerf[string (func)]) (s);
    }

  if (VED_DRAWONLY)
    return;
 
  toplinedr (" -- pager --");
  
  s.vedloop (s);
}
