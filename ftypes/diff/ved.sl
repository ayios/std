define diff_ved (s, fname)
{
  ifnot (SCRATCH == fname)
    diff_settype (s, fname, VED_ROWS, NULL);
 
  __vsetbuf (s._absfname);
 
  __vwrite_prompt (" ", 0);

  s.draw ();

  preloop (s);
 
  toplinedr (" -- pager --");

  s.vedloop ();
}
