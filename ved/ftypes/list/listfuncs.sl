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
    return 0;
    }

  fnames[s.fname] = self;
  c = fnames[s.fname];
 
  variable len = length (rows);
 
  c.rows = rows;
  c._indent = qualifier ("indent", 0);
  c._shiftwidth = 4;
  c.ptr = Integer_Type[2];
  c.cols = Integer_Type[len];
  c.cols[*] = 0;
  c.clrs = Integer_Type[len];
  c.clrs[*] = 0;
  c._avlins = len - 1;
  c._maxlen = COLUMNS;
  c._linlen = c._maxlen - c._indent;
  c._flags = 0;
  c.lines = readfile (s.fname);
  if (NULL == c.lines)
    c.lines = [sprintf ("%s\000", repeat (" ", c._indent))];
  c._len = length (c.lines) - 1;
  c._fname = s.fname;
  c._i = c._len >= s.lnr - 1 ? s.lnr - 1 : 0;
  c.ptr[0] = qualifier ("row", 1);
  c.ptr[1] = qualifier ("col", s.col - 1);
  c._findex = c._indent;
  c._index = c.ptr[1];
  c.undo = String_Type[0];
  c._undolevel = 0;
  c.undoset = {};

  c.st_ = stat_file (c._fname);
  if (NULL == c.st_)
    c.st_ = struct
      {
      st_atime,
      st_mtime,
      st_uid = getuid (),
      st_gid = getgid (),
      st_size = 0
      };

  return 0;
}

private define togglecur ()
{
  cf_.clrs[-1] = INFOCLRBG;
  smg->hlregion (INFOCLRBG, cf_.rows[-1], 0, 1, COLUMNS);
  IMG[cf_.rows[-1]][1] = INFOCLRBG;
  frame = frame ? 0 : 1;
  prev_fn = cf_._fname;
}

private define set_cf (fname)
{
  cf_ = fnames[fname];
  cf_.clrs[-1] = INFOCLRFG;
  IMG[cf_.rows[-1]][1] = INFOCLRFG;
  smg->hlregion (INFOCLRFG, cf_.rows[-1], 0, 1, COLUMNS);
  topline_dr (" -- PAGER --");
}

private define getitem ()
{
  variable
    line = v_lin ('.'),
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
    () = fprintf (stderr, "%s: No such filename", fname);
    return NULL;
    }

  return struct {lnr = lnr, col = col, fname = fname};
}

private define drawfile ()
{
  ifnot (frame)
    return;
 
  variable l = getitem ();

  if (NULL == l)
    return;

  togglecur ();
 
  variable retval = add (NULL, l, defrows[0]);

  set_cf (l.fname);
 
  if (exists == retval)
    {
    cf_._i = cf_._len >= l.lnr - 1 ? l.lnr - 1 : 0;
    cf_.ptr[0] = 1;
    cf_.ptr[1] = l.col - 1 + cf_._indent;
    cf_._findex = cf_._indent;
    cf_._index = cf_.ptr[1];
    }
 
  cf_.draw ();
}

private define chframe ()
{
  if (1 == length (fnames))
    return;

  variable fn = prev_fn;
  togglecur ();
  set_cf (fn);

  smg->setrcdr (cf_.ptr[0], cf_.ptr[1]);
}

private define myquit ()
{
  variable
    fn,
    chr,
    fns = assoc_get_keys (fnames);

  _for fn (0, length (fns) - 1)
    {
    cf_ = fnames[fns[fn]];
    if (cf_._flags & RDONLY || 0 == cf_._flags & MODIFIED ||
        (0 == qualifier_exists ("force") && "q!" == rl_.argv[0]))
      continue;

    send_msg_dr (sprintf ("%s: save changes? y[es]|n[o]", cf_._fname), 0, NULL, NULL);

    chr = getch ();
    while (0 == any (chr == ['y', 'n']))
      chr = getch ();
 
    if ('n' == chr)
      continue;
 
    variable retval = writetofile (cf_._fname, cf_.lines, cf_._indent);
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

clinef["q"] = &myquit;
clinef["q!"] = &myquit;

lpagerf[string ('\r')] = &drawfile;
lpagerf[string (keys->CTRL_w)] = &chframe;

lpagerc = array_map (Integer_Type, &integer, assoc_get_keys (lpagerf));

define ved (s, fname, rows)
{
  s.quit = &myquit;
  set_img ();

  variable mys = struct
    {
    fname = fname,
    lnr = 1,
    col = 0,
    };

  () = add (s, mys, defrows[1];row = defrows[1][0], col = 0);

  set_cf (mys.fname);
  prev_fn = mys.fname;

  clear (1, LINES);

  smg->hlregion (INFOCLRBG, cf_.rows[0] - 1, 0, 1, COLUMNS);
 
  s.draw ();

  variable func = get_func ();

  if (func)
    {
    count = get_count ();
    if (any (pagerc == func))
      (@pagerf[string (func)]);

    if (any (lpagerc == func))
      (@lpagerf[string (func)]);
    }

  if (DRAWONLY)
    return;

  topline_dr (" -- PAGER --");
 
  (@vedloop) (s);
}
