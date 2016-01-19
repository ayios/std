define mail_ved (s, fname)
{
  mail_settype (s, fname, VED_ROWS, NULL);

  __vsetbuf (s._abspath);

  __vwrite_prompt (" ", 0);

  s.draw ();

  preloop (s);

  toplinedr (" -- pager --");

  s.vedloop ();
}
