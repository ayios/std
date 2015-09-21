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
  variable rl = rline->init (NULL;pchar = ">");
  rline->set (rl);

  variable histfile = sprintf ("%s/%devalhistory", HISTDIR, getuid ());
  variable history = String_Type[0];

  ifnot (access (histfile, F_OK|R_OK))
    history = readfile (histfile);

  send_msg ("Type an expression" , 0);

  rl.argv = [""];

  variable
    res = NULL,
    index = -1;

  forever
    {
    rl._lin = ">" + rl.argv[0];
    rline->prompt (rl, rl._lin, rl._col);
    rl._chr = getch ();

    if (any (keys->rmap.histup == rl._chr))
      {
      ifnot (length (history))
        continue;

      index++;
      if (index >= length (history))
        index = 0;

      rl.argv[0] = history[index];
      () = _evalstr_ (rl.argv[0];send_msg);
      continue;
      }

    if (any (keys->rmap.histdown == rl._chr))
      {
      ifnot (length (history))
        continue;

      index--;
      if (index < 0)
        index = length (history) - 1;
      rl.argv[0] = history[index];
      () = _evalstr_ (rl.argv[0];send_msg);
      continue;
      }

    if (rl._chr == 033)
      break;

    if ('\r' == rl._chr)
      {
      if ('=' == rl.argv[0][0])
        res = _assign_ (substr (rl.argv[0], 2, -1));
      else
        res = _evalstr_ (rl.argv[0];send_msg);

      ifnot (NULL == res)
        history = [rl.argv[0], history];

      if (qualifier_exists ("return_str"))
        break;

      rl.argv[0] = "";
      continue;
      }

    rline->routine (rl;insert_ws);

    ifnot (strlen (rl.argv[0]))
      continue;

    _evalstr_ (rl.argv[0];send_msg);
    }

  if (length (history))
    () = writestring (histfile, strjoin (history, "\n"));

  send_msg (" ", 0);

  if (qualifier_exists ("return_str"))
    return res;
}
