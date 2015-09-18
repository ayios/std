define txt_ved (s, fname)
{
  ifnot (SCRATCH == fname)
    txt_settype (s, fname, VED_ROWS, NULL);
 
  __vsetbuf (s._abspath);
 
  __vwrite_prompt (" ", 0);

  s.draw ();

  preloop (s);
 
  toplinedr (" -- pager --");

  s.vedloop ();
}
