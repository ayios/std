define setbuf (key)
{
  ifnot (any (key == VED_BUFNAMES))
    return;
 
  VED_CB = VED_BUFFERS[key];
 
  variable s = VED_CB;

  if (s._autochdir && 0 == VED_ISONLYPAGER)
    () = chdir (s._dir);
}

define addbuf (s)
{
  ifnot (path_is_absolute (s._fname))
    s._absfname = getcwd + s._fname;
  else
    s._absfname = s._fname;

  if (any (s._absfname == VED_BUFNAMES))
    return;

  VED_BUFFERS[s._absfname] = s;
  VED_BUFNAMES = [VED_BUFNAMES,  s._absfname];
  VED_BUFFERS[s._absfname]._dir = realpath (path_dirname (s._absfname));
}

define bufdelete (s, bufname, force)
{
  ifnot (any (s._absfname == VED_BUFNAMES))
    return;
 
  if (s._flags & VED_MODIFIED && force)
    {
    variable retval = writetofile (s._absfname, s.lines, s._indent);
    ifnot (0 == retval)
      send_msg_dr (errno_string (retval), 1, NULL, NULL);
    }

  assoc_delete_key (VED_BUFFERS, bufname);
 
  variable index = wherefirst (bufname == VED_BUFNAMES);
 
  VED_BUFNAMES[index] = NULL;
  VED_BUFNAMES = VED_BUFNAMES[wherenot (_isnull (VED_BUFNAMES))];
 
  ifnot (length (VED_BUFNAMES))
    s.quit (0);
 
  index = index ? index - 1 : length (VED_BUFNAMES) - 1;
 
  setbuf (VED_BUFNAMES[index]);
 
  s = VED_CB;
 
  s.draw ();
  s.vedloop ();
}

define initrowsbuffvars (s, rows)
{
  s.cols = Integer_Type[length (s.rows)];
  s.cols[*] = 0;

  s.clrs = Integer_Type[length (s.rows)];
  s.clrs[*] = 0;
  s.clrs[-1] = VED_INFOCLRFG;
 
  s._avlins = length (s.rows) - 2;
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
 
  initrowsbuffvars (s, rows);

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
