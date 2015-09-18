define draw (s)
{
  variable st = NULL == s._fd ? lstat_file (s._abspath) : fstat (s._fd);

  if (NULL == st)
    {
    s._i = s._ii;
    s.draw ();
    return;
    }

  if (s.st_.st_size)
    if (st.st_atime == s.st_.st_atime && st.st_size == s.st_.st_size)
      {
      s._i = s._ii;
      s.draw ();
      return;
      }

  s.st_ = st;

  s.lines = __vgetlines (s._abspath, s._indent, st);

  s._len = length (s.lines) - 1;

  variable _i = qualifier ("_i");
  variable pos = qualifier ("pos");
  variable len = length (s.rows) - 1;

  ifnot (NULL == pos)
    (s.ptr[0] = pos[0], s.ptr[1] = pos[1]);
  else
    (s.ptr[1] = 0, s.ptr[0] = s._len + 1 <= len ? s.rows[0] : s.rows[-2]);

  ifnot (NULL == _i)
    s._i = _i;
  else
    s._i = s._len + 1 <= len ? 0 : s._len + 1 - len;

  s.draw ();
}

define viewfile (s, type, pos, _i)
{
  variable ismsg = 0;
  __vsetbuf (s._abspath);

  topline (" -- pager -- (" + type + " BUF) --";row =  s.ptr[0], col = s.ptr[1]);

  ifnot (NULL == pos)
    (s.ptr[0] = pos[0], s.ptr[1] = pos[1]);

  draw (s;pos = pos, _i = _i);

  forever
    {
    VEDCOUNT = -1;
    s._chr = getch (;disable_langchange);

    if ('1' <= s._chr <= '9')
      {
      VEDCOUNT = "";

      while ('0' <= s._chr <= '9')
        {
        VEDCOUNT += char (s._chr);
        s._chr = getch (;disable_langchange);
        }

      try
        VEDCOUNT = integer (VEDCOUNT);
      catch SyntaxError:
        {
        ismsg = 1;
        send_msg_dr ("count: too many digits >= " +
          string (256 * 256 * 256 * 128), 1, s.ptr[0], s.ptr[1]);
        continue;
        }
      }

    s.vedloopcallback ();

    if (ismsg)
      {
      send_msg_dr (" ", 0, s.ptr[0], s.ptr[1]);
      ismsg = 0;
      }

    if (any ([':', 'q'] == s._chr))
      break;
    }
}
