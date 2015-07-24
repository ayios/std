private define _vedloopcallback_ (s)
{
  (@VED_PAGER[string (s._chr)]) (s);
}

private define _vedloop_ (s)
{
  forever
    {
    VEDCOUNT = -1;
    s._chr = getch ();
 
    if ('0' <= s._chr <= '9')
      {
      VEDCOUNT = "";
 
      while ('0' <= s._chr <= '9')
        {
        VEDCOUNT += char (s._chr);
        s._chr = getch ();
        }

      VEDCOUNT = integer (VEDCOUNT);
      }

    s.vedloopcallback ();
 
    if (':' == s._chr && 0 == VED_ISONLYPAGER)
      {
      if (RECORD)
        RECORD = 0;

      topline (" -- command line --");
      rline->set (RLINE);
      rline->readline (RLINE;
        ved = s, draw = SCRATCH == s._absfname ? 0 : 1);

      if ('!' == RLINE.argv[0][0] && SCRATCH == s._absfname)
        {
        draw (s);
        continue;
        }

      topline (" -- pager --");
      smg->setrcdr (s.ptr[0], s.ptr[1]);
      }

    if ('q' == s._chr && VED_ISONLYPAGER)
      break;
    }
}

define initvedloop ()
{
  return struct
    {
    vedloop = &_vedloop_,
    vedloopcallback = &_vedloopcallback_
    };
}
