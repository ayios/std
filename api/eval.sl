private define _assign_ (line)
{
  variable _v_ = strchop (line, '=', 0);
  if (1 == length (_v_))
    return -1;
 
  _v_ = _v_[0];

  try
    {
    eval (line);
    send_msg (string (eval (string (_v_))), 0);
    }
  catch AnyError:
    send_msg (__get_exception_info.message, 0);
 
  return 1;
}

private define _evalstr_ (line)
{
  variable res;

  try
    {
    ifnot ('=' == line[0])
      res = string (eval (line));
    else
      return;
    }
  catch AnyError:
    res = __get_exception_info.message;

  send_msg (res, 0);
}

define _eval_ (argv)
{
  variable rl = qualifier ("rl");
  variable line = "";
  variable histfile = sprintf ("%s/%devalhistory", HISTDIR, getuid ());
  variable history = String_Type[0];
  variable addh = 1;

  ifnot (access (histfile, F_OK|R_OK))
    history = readfile (histfile);

  send_msg ("Type an expression" , 0);

  variable
    index = -1,
    chr;

  forever
    {
    rline->prompt (rl, ">" + line, strlen (line) + 1);
    chr = getch ();
 
    if (any (keys->rmap.histup == chr))
      {
      ifnot (length (history))
        continue;

      index++;
      if (index >= length (history))
        index = 0;

      line = history[index];
      _evalstr_ (line);
      continue;
      }

    if (any (keys->rmap.histdown == chr))
      {
      ifnot (length (history))
        continue;

      index--;
      if (index < 0)
        index = length (history) - 1;

      line = history[index];
      _evalstr_ (line);
      continue;
      }

    if (chr == 033)
      break;
 
    if (any (keys->rmap.backspace == chr))
      {
      ifnot (strlen (line))
        continue;

      line = substr (line, 1, strlen (line) - 1);
      if (strlen (line))
        _evalstr_ (line);
      else
        send_msg (" ", 0);

      continue;
      }

    if ('\r' == chr)
      {
      if ('=' == line[0])
        addh = _assign_ (substr (line, 2, -1));
 
      if (1 == addh)
        history = [line, history];

      line = "";
      addh = 1;
      continue;
      }

    line+= char (chr);

    ifnot (strlen (line))
      continue;

    _evalstr_ (line);
    }
 
  if (length (history))
    () = writestring (histfile, strjoin (history, "\n"));

  send_msg (" ", 0);
}
