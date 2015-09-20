private define _assign_ (line)
{
  variable _v_ = strchop (line, '=', 0);
  if (1 == length (_v_))
    return 0;

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
  variable res, retval = NULL;;

  try
    {
    ifnot ('=' == line[0])
      res = string (eval (line));
    else
      return NULL;

    retval = res;
    }
  catch AnyError:
    res = __get_exception_info.message;

  if (qualifier_exists ("send_msg"))
    send_msg (res, 0);

  return retval;
}

define _eval_ (argv)
{
  variable rl = qualifier ("rl");
  variable line = "";
  variable histfile = sprintf ("%s/%devalhistory", HISTDIR, getuid ());
  variable history = String_Type[0];

  ifnot (access (histfile, F_OK|R_OK))
    history = readfile (histfile);

  send_msg ("Type an expression" , 0);

  variable
    res = NULL,
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
      () = _evalstr_ (line;send_msg);
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
      () = _evalstr_ (line;send_msg);
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
        () = _evalstr_ (line;send_msg);
      else
        send_msg (" ", 0);

      continue;
      }

    if ('\r' == chr)
      {
      if ('=' == line[0])
        res = _assign_ (substr (line, 2, -1));
      else
        res = _evalstr_ (line;send_msg);

      ifnot (NULL == res)
        history = [line, history];

      if (qualifier_exists ("return_str"))
        break;

      line = "";
      continue;
      }

    line+= char (chr);

    ifnot (strlen (line))
      continue;

    _evalstr_ (line;send_msg);
    }

  if (length (history))
    () = writestring (histfile, strjoin (history, "\n"));

  send_msg (" ", 0);

  if (qualifier_exists ("return_str"))
    return res;
}
