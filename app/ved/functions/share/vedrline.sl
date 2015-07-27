private define quit ()
{
  variable rl = qualifier ("rl");

  rline->writehistory (rl.history, rl.histfile);

  variable s = qualifier ("ved");

  if (s._flags & VED_RDONLY || 0 == s._flags & VED_MODIFIED ||
      (0 == qualifier_exists ("force") && "q!" == qualifier ("argv0")))
    s.quit (0);
 
  send_msg_dr ("file is modified, save changes? y[es]|n[o]", 0, NULL, NULL);

  variable chr = getch ();
  while (0 == any (chr == ['y', 'n']))
    chr = getch ();
 
  s.quit (chr == 'y');
}

private define write_file ()
{
  variable
    s = qualifier ("ved"),
    file,
    args = __pop_list (_NARGS);
 
  ifnot (length (args))
    {
    if (s._flags & VED_RDONLY)
      {
      send_msg_dr ("file is read only", 1, s.ptr[0], s.ptr[1]);
      return;
      }

    file = s._absfname;
    }
  else
    {
    file = args[0];
    ifnot (access (file, F_OK))
      {
      if (any (["w", "W"] == qualifier ("argv0")))
        {
        send_msg_dr ("file exists, w! to overwrite, press any key to continue", 1,
          NULL, NULL);
        () = getch ();
        send_msg_dr (" ", 0, s.ptr[0], s.ptr[1]);
        return;
        }

      if (-1 == access (file, W_OK))
        {
        send_msg_dr ("file is not writable, press any key to continue", 1,
          NULL, NULL);
        () = getch ();
        send_msg_dr (" ", 0, s.ptr[0], s.ptr[1]);
        return;
        }
      }
    }
 
  variable retval = writetofile (file, s.lines, s._indent);
 
  ifnot (0 == retval)
    {
    send_msg_dr (sprintf ("%s, press any key to continue", errno_string (retval)), 1,
      NULL, NULL);
    () = getch ();
    send_msg_dr (" ", 0, s.ptr[0], s.ptr[1]);
    return;
    }
 
  if (file == s._absfname)
    s._flags &= ~VED_MODIFIED;
}

private define _read ()
{
  variable s = qualifier ("ved");
  ifnot (_NARGS)
    return;

  variable file = ();
  if (-1 == access (file, F_OK|R_OK))
    return;

  variable st = stat_file (file);

  ifnot (istype (st.st_mode, "reg"))
    return;

  ifnot (st.st_size)
    return;

  variable ar = getlines (file, s._indent, st);
 
  variable lnr = v_lnr (s, '.');

  s.lines = [s.lines[[:lnr]], ar, s.lines[[lnr + 1:]]];
  s._len = length (s.lines) - 1;
  s.st_.st_size += st.st_size;

  set_modified (s);
  s._i = s._ii;
  s.draw ();
}

private define write_quit ()
{
  variable s = qualifier ("ved");
  variable args = __pop_list (_NARGS);
  s.quit (1, __push_list (args));
}

private define _messages_ ()
{
  variable keep = VED_CB;
  variable s = ERR_VED;
  VED_ISONLYPAGER = 1;
  setbuf (s._absfname);
 
  topline (" -- pager -- ( MESSAGES BUF) --";row = s.ptr[0], col = s.ptr[1]);
 
  variable st = fstat (s._fd);
 
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
 
  variable len = length (s.rows) - 1;

  (s.ptr[1] = 0, s.ptr[0] = s._len + 1 <= len ? s._len + 1 : s.rows[-2]);
 
  s._i = s._len + 1 <= len ? 0 : s._len + 1 - len;

  s.draw ();

  s.vedloop ();

  VED_ISONLYPAGER = 0;

  setbuf (keep._absfname);
 
  topline (" -- pager --");
 
  keep._i = keep._ii;

  keep.draw ();
 
  keep.vedloop ();
}

define _exit_ ()
{
  quit (;;__qualifiers  ());
}

private define _idle_ ()
{
  smg->suspend ();

  variable retval = go_idled ();
 
  ifnot (retval)
    {
    smg->resume ();
    return;
    }

  quit (;;__qualifiers  ());
}

VED_CLINE["&"] = &_idle_;
VED_CLINE["w"] = &write_file;
VED_CLINE["W"] = &write_file;
VED_CLINE["w!"] = &write_file;
VED_CLINE["q"] = &quit;
VED_CLINE["Q"] = &quit;
VED_CLINE["q!"] = &quit;
VED_CLINE["wq"] = &write_quit;
VED_CLINE["Wq"] = &write_quit;
VED_CLINE["r"] = &_read;
VED_CLINE["messages"] = &_messages_;
