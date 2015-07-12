private define _vedloopcallback_ (s)
{
  (@pagerf[string (s._chr)]) (s);
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
 
    if (':' == s._chr)
      {
      if (RECORD)
        RECORD = 0;

      topline (" -- command line --");
      rline->set (RLINE);
      rline->readline (RLINE;ved = s);
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
