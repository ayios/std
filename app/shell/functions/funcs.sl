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
  tostdout ("[" + string (iarg) + "](" + getcwd + ")$ ");
}

define getlines ();
define draw (s)
{
  variable st = lstat_file (s._absfname);
  
  if (s.st_.st_size)
    if (st.st_atime == s.st_.st_atime && st.st_size == s.st_.st_size)
      return;

  s.st_ = st;
 
  s.lines = getlines (s, s._absfname, s._indent, st);

  s._len = length (s.lines) - 1;
 
  s.ptr[1] = 0;

  if (s._len + 1 <= length (s.rows) - 1)
    {
    s._i = 0;
    s.ptr[0] = s._len + 1;
    }
  else
    {
    s._i = s._len + 1 - length (s.rows) + 1;
    s.ptr[0] = s.rows[-2];
    }

  s.draw ();
}
