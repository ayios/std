loadfrom ("stdio", "getlines", NULL, &on_eval_err);

ERR = init_ftype ("txt");
txt_settype (ERR, STDERR, VED_ROWS, NULL);
setbuf (ERR._absfname);

define osdraw (s)
{
  variable st = lstat_file (s._absfname);
 
  if (s.st_.st_size)
    if (st.st_atime == s.st_.st_atime && st.st_size == s.st_.st_size)
      {
      s._i = s._ii;

      s.draw ();
      return;
      }

  s.st_ = st;
 
  s.lines = getlines (s._absfname, s._indent, st);

  s._len = length (s.lines) - 1;
 
  variable _i = qualifier ("_i");
  variable pos = qualifier ("pos");
  variable len = length (s.rows) - 1;

  ifnot (NULL == pos)
    (s.ptr[0] = pos[0], s.ptr[1] = pos[1]);
  else
    (s.ptr[1] = 0, s.ptr[0] = s._len + 1 <= len ? s._len + 1 : s.rows[-2]);
 
  ifnot (NULL == _i)
    s._i = _i;
  else
    s._i = s._len + 1 <= len ? 0 : s._len + 1 - len;

  s.draw ();
}

define viewfile (s, type, pos, _i)
{
  topline (" -- pager -- (" + type + " BUF) --";row =  s.ptr[0], col = s.ptr[1]);
 
  ifnot (NULL == pos)
    (s.ptr[0] = pos[0], s.ptr[1] = pos[1]);
  
  osdraw (s;pos = pos, _i = _i);
  
  forever
    {
    VEDCOUNT = -1;
    s._chr = getch (;on_lang = &toplinedr, on_lang_args = {s.ptr, "--pager -- (OS BUF) --"});

    if ('1' <= s._chr <= '9')
      {
      VEDCOUNT = "";
 
      while ('0' <= s._chr <= '9')
        {
        VEDCOUNT += char (s._chr);
        s._chr = getch (;on_lang = &toplinedr, on_lang_args = {s.ptr, "--pager -- (OS BUF) --"});
        }

      VEDCOUNT = integer (VEDCOUNT);
      }
 
    (@pagerf[string (s._chr)]) (s);
 
    if (':' == s._chr || 'q' == s._chr)
      break;
    }
}

define _messages_ (argv)
{
  viewfile (ERR, "OS", NULL, NULL);
}