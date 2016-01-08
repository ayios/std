variable VED_CLINE = Assoc_Type[Ref_Type];

define addfname (fname)
{
  variable absfname;
  variable s;

  ifnot (path_is_absolute (fname))
    absfname = getcwd + fname;
  else
    absfname = fname;

  if (_isdirectory (fname))
    return;

  variable w = get_cur_wind ();

  ifnot (any (w.bufnames == absfname))
    {
    variable ft = get_ftype (fname);
    s = init_ftype (ft);
    variable func = __get_reference (sprintf ("%s_settype", ft));
    (@func) (s, fname, w.frame_rows[get_cur_frame ()], NULL);
    }
  else
    {
    s = w.buffers[absfname];
    s._i = s._ii;
    }

  __vsetbuf (s._abspath);
  __vwrite_prompt (" ", 0);
  s.draw (;dont_draw);
}

private define _edit_other ()
{
  ifnot (_NARGS)
    {
    __vreread (get_cur_buf ());
    return;
    }

  variable fname = ();
  addfname (fname);
}

private define _buffer_other_ ()
{
  variable dir = qualifier ("argv0") == "bn";
  variable w = get_cur_wind ();
  variable cb = get_cur_bufname ();
  variable ar = String_Type[0];
  variable ind;
  variable b;
  variable i;

  _for i (0, length (w.bufnames) - 1)
    {
    b = w.bufnames[i];
    ifnot (any (b == SPECIAL))
      ar = [ar, b];
    }

  if (1 == length (ar))
    return;

  ind = where (ar == cb)[0];

  ifnot (dir)
    if (0 == ind)
      ind = length (ar) - 1;
    else
      ind--;
  else
    if (ind == length (ar) - 1)
      ind = 0;
    else
      ind++;

  b = ar[ind];

  b = w.buffers[b];
  b._i = b._ii;

  __vsetbuf (b._abspath);
  __vwrite_prompt (" ", 0);
  b.draw (;dont_draw);
}

private define _bdelete ()
{
  variable force = qualifier ("argv0")[-1] != '!';
  variable s;

  ifnot (_NARGS)
    s = get_cur_buf ();
  else
    {
    variable bufname = ();
    variable w = get_cur_wind ();

    ifnot (any (bufname == w.bufnames))
      return;

    s = w.buffers[bufname];
    }

  if (force && s._flags & VED_MODIFIED)
    {
    send_msg_dr (sprintf ("%s is modified: save changes? y[es]/n[o]",
      s._abspath), 0, NULL, NULL);
    variable chr;
    while (chr = getch (), 0 == any (chr == ['y', 'n']));

    if ('n' == chr)
      force = 0;

    send_msg_dr (" ", 0, NULL, NULL);
    }

  bufdelete (s, s._abspath, force);
}

VED_CLINE["e"] = &_edit_other;
VED_CLINE["b"] = &_edit_other;
VED_CLINE["bd"] = &_bdelete;
VED_CLINE["bd!"] = &_bdelete;

private define my_commands ()
{
  variable i;
  variable a = (@__get_reference ("init_commands")) (;ex);
  variable keys = assoc_get_keys (VED_CLINE);

  _for i (0, length (keys) - 1)
    {
    a[keys[i]] = @Argvlist_Type;
    a[keys[i]].func = VED_CLINE[keys[i]];
    a[keys[i]].type = "Func_Type";
    }

  a["substitute"] = @Argvlist_Type;
  a["substitute"].func = &__substitute;
  a["substitute"].type = "Func_Type";
  a["substitute"].args =
    ["--global void do global substitutions",
     "--pat= pattern pcre pattern (required)",
     "--sub= pattern substitution (required)",
     "--dont-ask-when-subst void dont ask when substitute (yes by default)",
     "--range= int first linenr, last linenr"];

  return a;
}

private define _filter_bufs_ (v)
{
  variable ar = String_Type[0];
  variable w = get_cur_wind ();
  variable i;
  variable b;

  _for i (0, length (w.bufnames) - 1)
    {
    b = w.bufnames[i];
    ifnot (any (b == [v._abspath, SPECIAL]))
      ar = [ar, b];
    }

  return ar[array_sort (ar)];
}

private define tabhook (s)
{
  ifnot (any (s.argv[0] == ["b", "bd", "bd!"]))
    return -1;

  variable bufnames = _filter_bufs_ (qualifier ("ved"));
  variable args = array_map (String_Type, &sprintf, "%s void ", bufnames);
  return rline->argroutine (s;args = args, accept_ws);
}

define rlineinit ()
{
  variable rl = rline->init (&my_commands;;struct {
    histfile = Dir->Vget ("HISTDIR") + "/" + string (getuid ()) + "vedhistory",
    historyaddforce = 1,
    tabhook = &tabhook,
    %totype = "Func_Type",
    @__qualifiers
    });

  (@__get_reference ("iarg")) = length (rl.history);

  return rl;
}

define __write_buffers ()
{
  variable
    w = get_cur_wind (),
    bts,
    s,
    i,
    fn,
    abort = 0,
    hasnewmsg = 0,
    chr;

  _for i (0, length (w.bufnames) - 1)
    {
    fn = w.bufnames[i];
    s = w.buffers[fn];

    if (s._flags & VED_RDONLY)
      ifnot (qualifier_exists ("force_rdonly"))
        continue;
      else
        if (-1 == access (fn, W_OK))
          {
          IO.tostderr (fn + " is not writable by you " + Env->Vget ("user"));
          hasnewmsg = 1;
          continue;
          }

    ifnot (s._flags & VED_MODIFIED)
      continue;

    if (0 == qualifier_exists ("force") ||
      (qualifier_exists ("force") && s._abspath != get_cur_bufname ()))
      {
      send_msg_dr (sprintf ("%s: save changes? y[es]/n[o]/c[cansel]", fn), 0, NULL, NULL);

      while (chr = getch (), 0 == any (chr == ['y', 'n', 'c']));

      if ('n' == chr)
        continue;

      if ('c' == chr)
        {
        IO.tostderr ("writting " + fn + " aborted");
        hasnewmsg = 1;
        abort = -1;
        continue;
        }
      }

    bts = 0;
    variable retval = __vwritetofile (s._abspath, s.lines, s._indent, &bts);

    ifnot (0 == retval)
      {
      send_msg_dr (sprintf ("%s, q to continue, without canseling function call", errno_string (retval)),
        1, NULL, NULL);

      if ('q' == getch ())
        continue;
      else
        {
        IO.tostderr (sprintf ("%s: %s", s._abspath, errno_string (retval)));
        hasnewmsg = 1;
        abort = -1;
        }
      }
    else
      IO.tostderr (s._abspath + ": " + string (bts) + " bytes written");
    }

  if (hasnewmsg)
    send_msg_dr ("you have new error messages", 1, NULL, NULL);

  return abort;
}

private define cl_quit ()
{
  variable force = 0;
  variable retval = 0;
  variable com = qualifier ("argv0");
  variable rl = qualifier ("rl");

  rline->writehistory (rl.history, rl.histfile);

  if (length (s_history))
    rline->writehistory (list_to_array (s_history), s_histfile);

  if (qualifier_exists ("force") || 'w' == com[0])
    force = 1;

  if (force)
    retval = __write_buffers (;force);
  else
    ifnot ("q!" == com)
      retval = __write_buffers ();

  ifnot (retval)
    exit_me (0);
}

private define _read_ ()
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

  variable ar = __vgetlines (file, s._indent, st);

  variable lnr = __vlnr (s, '.');

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
  % needs to write the current buffer and ask for the rest
  variable retval = __write_buffers (;force);
  ifnot (retval)
    exit_me (0);
}

define __vmessages ()
{
  variable keep = get_cur_buf ();
  variable s = (@__get_reference ("ERR_VED"));
  VED_ISONLYPAGER = 1;
  __vsetbuf (s._abspath);

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

  s.lines = __vgetlines (s._abspath, s._indent, st);

  s._len = length (s.lines) - 1;

  variable len = length (s.rows) - 1;

  (s.ptr[1] = 0, s.ptr[0] = s._len + 1 <= len ? s._len + 1 : s.rows[-2]);

  s._i = s._len + 1 <= len ? 0 : s._len + 1 - len;

  s.draw ();

  s.vedloop ();

  VED_ISONLYPAGER = 0;

  __vsetbuf (keep._abspath);

  __vdraw_wind ();
}

define _exit_ ()
{
  cl_quit (;;__qualifiers  ());
}

private define handle_comma (s)
{
  variable chr = getch ();
  variable refresh = 1;

  ifnot (any (['m', 'n', 'p'] == chr))
    return;

  if ('m' == chr)
    _buffer_other_ (;argv0 = "bp");
  else if ('n' == chr)
    _buffer_other_ (;argv0 = "bn");
  else if ('p' == chr)
    {
    refresh = 0;
    seltoX (get_cur_buf._abspath);
    }

  if (refresh)
    smg->refresh;
}

VED_PAGER[string (',')] = &handle_comma;

VED_CLINE["bp"] =       &_buffer_other_;
VED_CLINE["bn"] =       &_buffer_other_;
VED_CLINE["r"]  =       &_read_;
VED_CLINE["q"]  =       &cl_quit;
VED_CLINE["Q"]  =       &cl_quit;
VED_CLINE["q!"] =       &cl_quit;
VED_CLINE["wq"] =       &write_quit;
VED_CLINE["Wq"] =       &write_quit;
VED_CLINE["messages"] = &__vmessages;

private define _ved_ (t)
{
  return load.getref ("ftypes/" + t, "ved", NULL;err_handler = &__err_handler__, fun = t + "_ved");
}

define init_ftype (ftype)
{
  ifnot (FTYPES[ftype])
    FTYPES[ftype] = 1;

  variable type = @Ftype_Type;

  load.from ("ftypes/" + ftype, ftype + "_functions", NULL;err_handler = &__err_handler__);

  type._type = ftype;
  type.ved = _ved_ (ftype);

  return type;
}
