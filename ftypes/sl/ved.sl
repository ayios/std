define sl_ved (s, fname)
{
  sl_settype (s, fname, VED_ROWS, NULL);

  __vsetbuf (s._absfname);
 
  __vwrite_prompt (" ", 0);

  s.draw ();

  preloop (s);

  toplinedr (" -- pager --");

  s.vedloop ();
}
