private define _vedloopcallback_ (s)
{
  (@pagerf[string (s._chr)]) (s);
}

private define _vedloop_ (s)
{
  variable rl = rlineinit ();
 
  forever
    {
  tostderr ("loop " + string (_stkdepth ()));
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
      topline (" -- command line --");
      rline->set (rl);
      rline->readline (rl;ved = s);
      smg->setrcdr (s.ptr[0], s.ptr[1]);
      toplinedr (" -- pager --");
      }

    if (s._chr == 'q')
      if (VED_ISONLYPAGER)
        (@clinef["q"]) (s;force);
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
