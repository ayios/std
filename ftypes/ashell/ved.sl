define ashell_ved (s, fname)
{
  ashell_settype (s, fname, VED_ROWS, NULL);
 
  __vsetbuf (s._absfname);
 
  __vwrite_prompt (" ", 0);

  s.draw ();

  preloop (s);
 
  toplinedr (" -- pager --");
 
  s.vedloop (s);
}
