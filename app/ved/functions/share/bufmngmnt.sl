define setbuf (key)
{
  variable w = get_cur_wind ();
  
  ifnot (any (key == w.bufnames))
    return;
 
  variable s = w.buffers[key];

  w.frame_names[w.cur_frame] = key;
 
  if (s._autochdir && 0 == VED_ISONLYPAGER)
    () = chdir (s._dir);
}

define addbuf (s)
{
  ifnot (path_is_absolute (s._fname))
    s._absfname = getcwd + s._fname;
  else
    s._absfname = s._fname;

  variable w = get_cur_wind ();

  if (any (s._absfname == w.bufnames))
    return;
  
  w.buffers[s._absfname] = s;
  w.bufnames = [w.bufnames,  s._absfname];
  w.buffers[s._absfname]._dir = realpath (path_dirname (s._absfname));
}

define bufdelete (s, bufname, force)
{
  if (any (bufname == UNDELETABLE))
    return;

  variable w = get_cur_wind ();
  ifnot (any (s._absfname == w.bufnames))
    return;
 
  if (s._flags & VED_MODIFIED && force)
    {
    variable retval = writetofile (s._absfname, s.lines, s._indent);
    ifnot (0 == retval)
      send_msg_dr (errno_string (retval), 1, NULL, NULL);
    }

  variable isatframe = wherefirst (w.frame_names == bufname);

  assoc_delete_key (w.buffers, bufname);
 
  variable index = wherefirst (bufname == w.frame_names);
  
  w.bufnames[index] = NULL;
  w.bufnames = w.bufnames[wherenot (_isnull (w.bufnames))];
 
  variable winds = assoc_get_keys (VED_WIND);

  ifnot (length (w.bufnames))
    if (1 == length (winds))
      s.quit (0);
    else
      {
      assoc_delete_key (VED_WIND, VED_CUR_WIND);
      winds = assoc_get_keys (VED_WIND);
      VED_CUR_WIND = winds[0];
      w = get_cur_wind ();
      s = get_cur_buf ();
      setbuf (s._absfname);
      draw_wind ();
      return;
      }
 
  ifnot (NULL == isatframe)
    del_frame (isatframe);

  index = index ? index - 1 : length (w.bufnames) - 1;
 
  setbuf (w.bufnames[index]);
 
  s = get_cur_buf ();
  s.draw ();
}

define initbuf (s, fname, rows, lines, t)
{
  s._maxlen = t._maxlen;
  s._indent = t._indent;
  s._shiftwidth = t._shiftwidth;
  s._autoindent = t._autoindent;
  s._autochdir = qualifier ("_autochdir", t._autochdir);

  s.lexicalhl = t.lexicalhl;
  s.autoindent = t.autoindent;
  s.draw = t.draw;
  s.vedloop = t.vedloop;
  s.vedloopcallback = t.vedloopcallback;

  s._fname = fname;

  s._linlen = s._maxlen - s._indent;

  s.st_ = stat_file (s._fname);
  if (NULL == s.st_)
    s.st_ = struct
      {
      st_atime,
      st_mtime,
      st_uid = getuid (),
      st_gid = getgid (),
      st_size = 0
      };

  s.rows = rows;

  s.lines = NULL == lines ? getlines (s._fname, s._indent, s.st_) : lines;
  s._flags = 0;
  s._is_wrapped_line = 0;
 
  s.ptr = Integer_Type[2];

  s._len = length (s.lines) - 1;
 
  initrowsbuffvars (s);

  s.ptr[0] = s.rows[0];
  s.ptr[1] = s._indent;
 
  s._findex = s._indent;
  s._index = s._indent;
 
  s.undo = String_Type[0];
  s._undolevel = 0;
  s.undoset = {};

  s._i = 0;
  s._ii = 0;

  addbuf (s);
}

