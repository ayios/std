private define _vedloopcallback_ (s)
{
  tostderr ("loop ba " + string (_stkdepth ()));
  (@pagerf[string (s._chr)]) (s);
  tostderr ("loop bab " + string (_stkdepth ()));
}

private define _vedloop_ (s)
{
  variable rl = rlineinit ();
 
  forever
    {
  tostderr ("loop a" + string (_stkdepth ()));
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
    
  tostderr ("loop b " + string (_stkdepth ()));
    if (':' == s._chr)
      {
      if (RECORD)
        RECORD = 0;

      topline (" -- command line --");
      rline->set (rl);
      rline->readline (rl;ved = s);
      smg->setrcdr (s.ptr[0], s.ptr[1]);
      toplinedr (" -- pager --");
      }
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
