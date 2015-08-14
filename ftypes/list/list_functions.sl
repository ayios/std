
variable orig_dir = getcwd ();

private variable
  fnames = Assoc_Type[Ftype_Type],
  exists = 0x01;

private define add (self, s, rows)
{
  variable w = get_cur_wind ();

  if (any (s.fname == w.bufnames))
    return exists;

  variable ftype = get_ftype (s.fname);

  variable c;

  ifnot ("list" == ftype)
    {
    w.cur_frame = 0;
    fnames[s.fname] = init_ftype (ftype);
    c = fnames[s.fname];

    loadfrom ("ftypes/" + ftype, ftype + "_settype", NULL, &on_eval_err);
    variable func = __get_reference (sprintf ("%s_settype", ftype));
    (@func) (c, s.fname, rows, NULL);
    
    c._i = c._len >= s.lnr - 1 ? s.lnr - 1 : 0;
    c.ptr[0] = 1;
    c.ptr[1] = s.col - 1 + c._indent;
    c._index = c.ptr[1];
    setbuf (c._absfname);
    w.frame_names[0] = c._absfname;
    return 0;
    }

  c = self;
 
  w.cur_frame = 1;
  w.frame_names[1] = c._absfname;
  variable lines = readfile (s.fname);
  if (NULL == lines)
    lines = [sprintf ("%s\000", c._indent)];

  variable def = deftype ();
  def._autochdir = 0;
  initbuf (c, s.fname, rows, lines, def);
 
  c._len = length (lines) - 1;
  c._i = c._len >= s.lnr - 1 ? s.lnr - 1 : 0;
  c.ptr[0] = qualifier ("row", 1);
  c.ptr[1] = qualifier ("col", s.col - 1);
  c._index = c.ptr[1];
  
  setbuf (c._absfname);

  return 0;
}

private define getitem (s)
{
  variable
    line = v_lin (s, '.'),
    tok = strchop (line, '|', 0),
    col = atoi (strtok (tok[1])[2]),
    lnr = atoi (strtok (tok[1])[0]),
    fname;

  ifnot (path_is_absolute (tok[0]))
    fname = path_concat (orig_dir, tok[0]);
  else
    fname = tok[0];

  if (-1 == access (fname, F_OK))
    {
    tostderr (fname + ": No such filename");
    return NULL;
    }

  return struct {lnr = lnr, col = col, fname = fname};
}

private define drawfile (s)
{
  ifnot (get_cur_frame ())
    return;

  variable l = getitem (s);

  if (NULL == l)
    return;
 
  if (".list" == path_extname (l.fname))
    return;
  
  variable w = get_cur_wind ();

  variable retval = add (NULL, l, w.frame_rows[0];force);

  s = get_cur_buf ();
 
  if (exists == retval)
    {
    change_frame ();
    s = get_cur_buf ();
    s._i = s._len >= l.lnr - 1 ? l.lnr - 1 : 0;
    s.ptr[0] = 1;
    s.ptr[1] = l.col - 1 + s._indent;
    s._findex = s._indent;
    s._index = s.ptr[1];
    }
  else
    {
    variable lb =w.buffers[w.frame_names[1]];
    lb.clrs[-1] = VED_INFOCLRBG;
    smg->hlregion (VED_INFOCLRBG, lb.rows[-1], 0, 1, COLUMNS);
    SMGIMG[lb.rows[-1]][1] = VED_INFOCLRBG;
    }
 
  s.draw ();
  s.vedloop ();
}

private define myquit ()
{
  variable
    s,
    fn,
    chr,
    fns = assoc_get_keys (fnames);

  _for fn (0, length (fns) - 1)
    {
    s = fnames[fns[fn]];
    if (s._flags & VED_RDONLY || 0 == s._flags & VED_MODIFIED ||
        (0 == qualifier_exists ("force") && "q!" == qualifier ("argv0")))
      continue;

    send_msg_dr (sprintf ("%s: save changes? y[es]|n[o]", s._fname), 0, NULL, NULL);

    chr = getch ();
    while (0 == any (chr == ['y', 'n']))
      chr = getch ();
 
    if ('n' == chr)
      continue;
 
    variable retval = writetofile (s._fname, s.lines, s._indent);
    ifnot (0 == retval)
      {
      send_msg_dr (sprintf ("%s, press q to quit without saving", errno_string (retval)),
        1, NULL, NULL);

      if ('q' == getch ())
        return;
      }
    }
 
  send_msg (" ", 0);
  exit_me (0);
}

VED_CLINE["q"] = &myquit;
VED_CLINE["q!"] = &myquit;

VED_PAGER[string ('\r')] = &drawfile;

define list_set (s, mys)
{
  s.quit = &myquit;
  () = add (s, mys, get_cur_wind ().frame_rows[1];row = get_cur_wind ().frame_rows[1][0], col = 0);
}
