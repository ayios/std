private define _invalid (s)
{
  return;
}
 
variable list_VED_PAGER = Assoc_Type[Ref_Type, &_invalid];

loadfile ("initfunctions", NULL, &on_eval_err);

private define _vedloopcallback_ (s)
{
  (@VED_PAGER[string (s._chr)]) (s);

  (@list_VED_PAGER[string (s._chr)]) (s);
}

private variable
  fnames = Assoc_Type[Ftype_Type],
  frame = 1,
  exists = 0x01,
  prev_fn = NULL,
  defrows = {[1:LINES - 9], [LINES - 8:LINES - 3]};

private define add (self, s, rows)
{
  if (assoc_key_exists (fnames, s.fname))
    return exists;

  variable ftype = get_ftype (s.fname);

  variable c;

  ifnot ("list" == ftype)
    {
    fnames[s.fname] = init_ftype (ftype);
    c = fnames[s.fname];
    loadfile (sprintf ("%s_settype", ftype), NULL, &on_eval_err);
    variable func = __get_reference (sprintf ("%s_settype", ftype));
    (@func) (c, s.fname, rows, NULL);
    c._i = c._len >= s.lnr - 1 ? s.lnr - 1 : 0;
    c.ptr[0] = 1;
    c.ptr[1] = s.col - 1 + c._indent;
    c._index = c.ptr[1];
    c.vedloopcallback = &_vedloopcallback_;
    return 0;
    }

  fnames[s.fname] = self;
  c = fnames[s.fname];
 
  variable lines = readfile (s.fname);
  if (NULL == lines)
    lines = [sprintf ("%s\000")];

  variable def = deftype ();
  def._autochdir = 0;
  initbuf (c, s.fname, rows, lines, def);
 
  c._len = length (lines) - 1;
  c._i = c._len >= s.lnr - 1 ? s.lnr - 1 : 0;
  c.ptr[0] = qualifier ("row", 1);
  c.ptr[1] = qualifier ("col", s.col - 1);
  c._index = c.ptr[1];
  c.vedloopcallback = &_vedloopcallback_;

  return 0;
}

private define togglecur ()
{
  VED_CB.clrs[-1] = VED_INFOCLRBG;
  smg->hlregion (VED_INFOCLRBG, VED_CB.rows[-1], 0, 1, COLUMNS);
  SMGIMG[VED_CB.rows[-1]][1] = VED_INFOCLRBG;
  frame = frame ? 0 : 1;
  prev_fn = VED_CB._fname;
}

private define set_cf (fname)
{
  VED_CB = fnames[fname];
  VED_CB.clrs[-1] = VED_INFOCLRFG;
  SMGIMG[VED_CB.rows[-1]][1] = VED_INFOCLRFG;
  smg->hlregion (VED_INFOCLRFG, VED_CB.rows[-1], 0, 1, COLUMNS);
  toplinedr (" -- pager --");
  return VED_CB;
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
    fname = path_concat (getcwd (), tok[0]);
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
  ifnot (frame)
    return;

  variable l = getitem (s);

  if (NULL == l)
    return;
 
  if (".list" == path_extname (l.fname))
    return;

  togglecur ();

  variable retval = add (NULL, l, defrows[0];force);

  s = set_cf (l.fname);
 
  if (exists == retval)
    {
    s._i = s._len >= l.lnr - 1 ? l.lnr - 1 : 0;
    s.ptr[0] = 1;
    s.ptr[1] = l.col - 1 + s._indent;
    s._findex = s._indent;
    s._index = s.ptr[1];
    }
 
  s.draw ();
  s.vedloop ();
}

private define chframe (s)
{
  if (1 == length (fnames))
    return;

  variable fn = prev_fn;
  togglecur ();
  s = set_cf (fn);

  smg->setrcdr (s.ptr[0], s.ptr[1]);
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

list_VED_PAGER[string ('\r')] = &drawfile;
list_VED_PAGER[string (keys->CTRL_w)] = &chframe;

define list_set (s, mys)
{
  s.quit = &myquit;
  () = add (s, mys, defrows[1];row = defrows[1][0], col = 0);

  () = set_cf (mys.fname);
  prev_fn = mys.fname;
}
