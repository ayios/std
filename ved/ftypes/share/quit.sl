private define doquit ()
{
  send_msg (" ", 0);
  exit_me (0);
}

define quit ()
{
  variable
    file,
    flags = MODIFIED,
    args = __pop_list (_NARGS - 1),
    write_on_exit = args[0];
 
  ifnot (write_on_exit)
    doquit ();

  if (1 == length (args) || (2 == length (args) && cf_._fname == args[1]))
    {
    file = cf_._fname;
    flags = cf_._flags;
    }
  else
    {
    file = args[1];
    ifnot (access (file, F_OK))
      {
      send_msg_dr ("file exists, press q to quit without saving", 1,
        cf_.ptr[0], cf_.ptr[1]);
      if ('q' == getch ())
        doquit ();

      smg->setrcdr (cf_.ptr[0], cf_.ptr[1]);
      return;
      }

    if (-1 == access (file, W_OK))
      {
      send_msg_dr ("file is not writable, press q to quit without saving", 1,
        cf_.ptr[0], cf_.ptr[1]);
      if ('q' == getch ())
        doquit ();

      smg->setrcdr (cf_.ptr[0], cf_.ptr[1]);
      return;
      }
    }
 
  if (flags & MODIFIED)
    {
    variable retval = writetofile (file, cf_.lines, cf_._indent);
    ifnot (0 == retval)
      {
      send_msg_dr (sprintf ("%s, press q to quit without saving", errno_string (retval)),
        1, NULL, NULL);
      if ('q' == getch ())
        doquit ();

      smg->setrcdr (cf_.ptr[0], cf_.ptr[1]);
      return;
      }
    }

  doquit ();
}
