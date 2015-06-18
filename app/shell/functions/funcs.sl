define tostdout (str)
{
  () = lseek (OUTFD, 0, SEEK_END);
  () = write (OUTFD, str);
}

define tostderr (str)
{
  () = lseek (ERRFD, 0, SEEK_END);
  () = write (ERRFD, str);
}

define shell_pre_header (argv)
{
  iarg++;
  tostdout (strjoin (argv, " ") + "\n");
}

define shell_post_header ()
{
  tostdout ("[" + string (iarg) + "](" + getcwd + ")[" + string (SHELLLASTEXITSTATUS) + "]$ ");
}

define getlines ();

define draw (s)
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

define on_lang_change (args)
{
  toplinedr (args[1];row =  args[0][0], col = args[0][1]);
}

define viewfile (s, type, pos, _i)
{
  variable f = __get_reference ("setbuf");
  (@f) (s._absfname);
  VED = s;
 
  topline (" -- pager -- (" + type + " BUF) --";row =  s.ptr[0], col = s.ptr[1]);
 
  ifnot (NULL == pos)
    (s.ptr[0] = pos[0], s.ptr[1] = pos[1]);

  draw (s;pos = pos, _i = _i);
 
  forever
    {
    VEDCOUNT = -1;
    s._chr = getch (;on_lang = &on_lang_change, on_lang_args = {s.ptr, "--pager -- (MSG BUF) --"});

    if ('1' <= s._chr <= '9')
      {
      VEDCOUNT = "";
 
      while ('0' <= s._chr <= '9')
        {
        VEDCOUNT += char (s._chr);
        s._chr = getch (;on_lang = &on_lang_change, on_lang_args = {s.ptr, "--pager -- (MSG BUF) --"});
        }

      VEDCOUNT = integer (VEDCOUNT);
      }
 
    (@pagerf[string (s._chr)]) (s);
 
    if (':' == s._chr || 'q' == s._chr)
      break;
    }
}

define scratch (ved)
{
  viewfile (SCRATCH, "SCRATCH", [1, 0], 0);

  variable f = __get_reference ("setbuf");
  
  (@f) (ved._absfname);
  VED = ved;
  ved.draw ();
}

define _messages_ ()
{
  viewfile (MSG, "MSG", NULL, NULL);
 
  variable f = __get_reference ("setbuf");
  variable ved = qualifier ("ved");

  (@f) (ved._absfname);
  VED = ved;
  ved.draw ();
}

define _appendstr (file, str)
{
  variable err = "";
  appendstr (file, str, &err);
  if (strlen (err))
    tostderr (err);
}
