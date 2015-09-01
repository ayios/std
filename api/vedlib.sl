typedef struct
  {
  _i,
  _ii,
  _len,
  _chr,
  _type,
  _fname,
  _absfname,
  _fd,
  _flags,
  _maxlen,
  _indent,
  _linlen,
  _avlins,
  _findex,
  _index,
  _shiftwidth,
  _undolevel,
  _autoindent,
  _dir,
  _autochdir,
  _is_wrapped_line,
  undo,
  undoset,
  ptr,
  rows,
  cols,
  clrs,
  lins,
  lnrs,
  vlins,
  lines,
  st_,
  vedloop,
  vedloopcallback,
  ved,
  draw,
  lexicalhl,
  autoindent,
  pairs,
  } Ftype_Type;

typedef struct
  {
  chr,
  lnr,
  prev_l,
  next_l,
  modified,
  } Insert_Type;

typedef struct
  {
  _i,
  ptr
  } Pos_Type;

typedef struct
  {
  cur_frame,
  frame_rows,
  frame_names,
  frames,
  buffers,
  bufnames,
  rline,
  } Wind_Type;

typedef struct
  {
  global,
  fname,
  ar,
  pat,
  patstr,
  substlist,
  numchanges,
  newlines,
  askwhensubst,
  ask,
  lnronfile,
  } Search_Type;
  
private variable vis = struct
  {
  _i,
  ptr,
  clr = COLOR.visual,
  l_mode,
  l_down,
  l_up,
  l_keys = ['y', 'Y', 'd', '>', '<', keys->DOWN, keys->UP],
  c_mode,
  c_left,
  c_right,
  c_keys = ['y', 'd', keys->DOWN, keys->RIGHT, keys->UP, keys->LEFT],
  bw_mode,
  bw_down,
  bw_up,
  bw_left,
  bw_right,
  bw_keys = ['x', 'I', 'd', 'y', keys->DOWN, keys->UP, keys->RIGHT, keys->LEFT],
  bw_maxlen,
  needsdraw,
  startrow,
  startlnr,
  startcol,
  startindex,
  vlins,
  lnrs,
  linlen,
  lines,
  sel,
  at_exit,
  };

private variable insfuncs = struct
  {
  cr,
  esc,
  bol,
  eol,
  up,
  left,
  down,
  pag_down,
  pag_up,
  right,
  del_prev,
  del_next,
  ins_char,
  ins_tab,
  completeline,
  };

public variable
  POS = Pos_Type[10],
  FTYPES = Assoc_Type[Integer_Type],
  MARKS = Assoc_Type[Pos_Type],
  REG = Assoc_Type[String_Type];

public variable
  EL_MAP = [[913:929:1], [931:937:1], [945:969:1]],
  EN_MAP = [['a':'z'], ['A':'Z']],
  MAPS = [EL_MAP, EN_MAP],
  WCHARS = array_map (String_Type, &char, [['0':'9'], EN_MAP, EL_MAP, '_']);

public variable
  VED_ROWS = [1:LINES - 3],
  VED_INFOCLRFG = COLOR.infofg,
  VED_INFOCLRBG = COLOR.infobg,
  VED_PROMPTCLR = COLOR.prompt;

public variable
  VED_MODIFIED = 0x01,
  VED_ONDISKMODIFIED = 0x02,
  VED_RDONLY = 0x04;

public variable
  VED_WIND = Assoc_Type[Wind_Type],
  VED_CUR_WIND = NULL,
  VED_PREV_WIND,
  VED_PREV_BUFINDEX,
  VED_MAXFRAMES = 3;

public variable
  VED_ISONLYPAGER = 0,
  VED_RLINE = 1;

public variable UNDELETABLE = String_Type[0];
public variable SPECIAL = String_Type[0];
public variable XCLIP_BIN = which ("xclip");
public variable VED_DIR = TEMPDIR + "/ved_" + string (PID) + "_" + string (_time)[[5:]];
 
public variable
  s_histfile = HISTDIR + "/" + string (getuid ()) + "ved_search_history",
  s_histindex = NULL,
  s_history = {};
 
public variable % NOT IMPLEMENTED
  RECORD = 0,
  CRECORD,
  RECORDS = Assoc_Type[List_Type];

private define _invalid ()
{
  pop ();
}

public variable
  VED_PAGER = Assoc_Type[Ref_Type, &_invalid],
  VEDCOUNT = 0;
 
private define build_ftype_table ()
{
  variable i;
  variable ii;
  variable ft;
  variable nss = [LCLDIR, STDDIR, USRDIR];
 
  % priority local < std < usr
  _for i (0, length (nss) - 1)
    {
    ft = listdir (nss[i] + "/ftypes");
    if (NULL == ft)
      continue;

    _for ii (0, length (ft) - 1)
      if (_isdirectory (nss[i] + "/ftypes/" + ft[ii])) 
        FTYPES[ft[ii]] = 0;
    }
}

build_ftype_table ();

() = mkdir (VED_DIR, PERM["PRIVATE"]);

loadfrom ("search", "searchandreplace", "search", &on_eval_err);
loadfrom ("string", "decode", NULL, &on_eval_err);
loadfrom ("stdio", "appendstr", NULL, &on_eval_err);
loadfrom ("array", "getsize", NULL, &on_eval_err);
loadfrom ("pcre", "find_unique_words_in_lines", 1, &on_eval_err);
loadfrom ("pcre", "find_unique_lines_in_lines", 1, &on_eval_err);

define set_modified ();
define seltoX ();
define topline ();
define toplinedr ();

define get_ftype (fn)
{
  variable ftype = substr (path_extname (fn), 2, -1);
  ifnot (any (assoc_get_keys (FTYPES) == ftype))
    ftype = "txt";

  return ftype;
}

define init_ftype (ftype)
{
  ifnot (FTYPES[ftype])
    FTYPES[ftype] = 1;

  variable type = @Ftype_Type;

  loadfrom ("ftypes/" + ftype, ftype + "_functions", NULL, &on_eval_err);

  type._type = ftype;
  return type;
}

define __get_null_str (indent)
{
  return sprintf ("%s\000", repeat (" ", indent));
}
 
define getlines (fname, indent, st)
{
  if (-1 == access (fname, F_OK) || 0 == st.st_size)
    {
    st.st_size = 0;
    return [__get_null_str (indent)];
    }

  indent = repeat (" ", indent);
  return array_map (String_Type, &sprintf, "%s%s", indent, readfile (fname));
}

private define _on_lang_change_ (mode, ptr)
{
  topline (" -- " + mode + " --");
  smg->setrcdr (ptr[0], ptr[1]);
}

define write_prompt (str, col)
{
  smg->atrcaddnstrdr (str, VED_PROMPTCLR, PROMPTROW, 0,
    qualifier ("row", PROMPTROW), col, COLUMNS);
}

define v_linlen (s, r)
{
  r = (r == '.' ? s.ptr[0] : r) - s.rows[0];
  return strlen (s.lins[r]) - s._indent;
}

define v_lin (s, r)
{
  r = (r == '.' ? s.ptr[0] : r) - s.rows[0];
  return s.lins[r];
}

define v_lnr (s, r)
{
  r = (r == '.' ? s.ptr[0] : r) - s.rows[0];
  return s.lnrs[r];
}

define tail (s)
{
  variable
    lnr = v_lnr (s, '.') + 1,
    line = v_lin (s, '.');

  return sprintf (
    "[%s] (row %d) (col %d) (linenr %d/%d %.0f%%) (strlen %d) chr (%d), undo (%d/%d)",
    path_basename (s._fname), s.ptr[0], s.ptr[1] - s._indent + 1, lnr,
    s._len + 1, (100.0 / s._len) * (lnr - 1), v_linlen (s, '.'),
    qualifier ("chr", decode (substr (line, s._index + 1, 1))[0]),
    s._undolevel, length (s.undo));
}

define draw_tail (s)
{
  if (s._is_wrapped_line)
    smg->hlregion (1, s.ptr[0], COLUMNS - 2, 1, 2);
 
  smg->atrcaddnstrdr (tail (s;;__qualifiers ()), VED_INFOCLRFG, s.rows[-1], 0, s.ptr[0], s.ptr[1],
    COLUMNS);
}

define getlinestr (s, line, ind)
{
  return substr (line, ind + s._indent, s._linlen);
}

define fpart_of_word (s, line, col, start)
{
  ifnot (strlen (line))
    return "";

  variable origcol = col;

  ifnot (col - s._indent)
    @start = s._indent;
  else
    {
    while (col--, col >= s._indent && any (WCHARS == substr (line, col + 1, 1)));

    @start = col + 1;
    }
 
  return substr (line, @start + 1, origcol - @start + 1);
}

define find_word (s, line, col, start, end)
{
  ifnot (col - s._indent)
    @start = s._indent;
  else
    {
    while (col--, col >= s._indent && any (WCHARS == substr (line, col + 1, 1)));

    @start = col + 1;
    }
 
  variable len = strlen (line);

  while (col++, col < len && any (WCHARS == substr (line, col + 1, 1)));
 
  @end = col - 1;
 
  return substr (line, @start + 1, @end - @start + 1);
}

define find_Word (s, line, col, start, end)
{
  ifnot (col - s._indent)
    @start = s._indent;
  else
    {
    while (col--, col >= s._indent && 0 == isblank (substr (line, col + 1, 1)));

    @start = col + 1;
    }
 
  variable len = strlen (line);

  while (col++, col < len && 0 == isblank (substr (line, col + 1, 1)));
 
  @end = col - 1;
 
  return substr (line, @start + 1, @end - @start + 1);
}

define drawfile (s)
{
  variable st = lstat_file (s._absfname);
 
  if (s.st_.st_size)
    if (st.st_atime == s.st_.st_atime && st.st_size == s.st_.st_size)
      {
      s.draw ();
      return;
      }

  s.st_ = st;
 
  s.lines = getlines (s, s._absfname, s._indent, st);

  s._len = length (s.lines) - 1;
 
  variable _i = qualifier ("_i");
  variable pos = qualifier ("pos");
  variable len = length (s.rows) - 1;

  ifnot (NULL == pos)
    (s.ptr[0] = pos[0], s.ptr[1] = pos[1]);
  else
    (s.ptr[1] = 0, s.ptr[0] = s._len + 1 <= len ? s._len + 1 : s.rows[-2]);
 
  ifnot (NULL == _i)
    s._i = _i;
  else
    s._i = s._len + 1 <= len ? 0 : s._len + 1 - len;

  s.draw ();
}

private define write_line (fp, line, indent)
{
  line = substr (line, indent + 1, -1);
  return fwrite (line, fp);
}

define __writetofile (file, lines, indent, bts)
{
  variable
    i,
    retval,
    fp = fopen (file, "w");
 
  if (NULL == fp)
    return errno;

  _for i (0, length (lines) - 1)
    if (retval = write_line (fp, lines[i] + "\n", indent), retval == -1)
      return errno;
    else
      @bts += retval;

  if (-1 == fclose (fp))
    return errno;
 
  return 0;
}

define __writefile (s, overwrite, ptr, argv)
{
  variable file;
  variable bts = 0;
 
  if (NULL == argv || 0 == length (argv))
    {
    if (s._flags & VED_RDONLY)
      return;

    file = s._absfname;
    }
  else
    {
    file = argv[0];
    ifnot (access (file, F_OK))
      {
      ifnot (overwrite)
        {
        send_msg_dr ("file exists, w! to overwrite", 1, ptr[0], ptr[1]);
        return;
        }

      if (-1 == access (file, W_OK))
        {
        send_msg_dr ("file is not writable", 1, ptr[0], ptr[1]);
        return;
        }
      }
    }
 
  variable retval = __writetofile (file, s.lines, s._indent, &bts);
 
  if (retval)
    {
    send_msg_dr (errno_string (retval), 1, ptr[0], ptr[1]);
    return;
    }
 
  tostderr (s._absfname + ": " + string (bts) + " bytes written");

  if (file == s._absfname)
    s._flags &= ~VED_MODIFIED;
}

define waddlineat (s, line, clr, row, col, len)
{
  smg->atrcaddnstr (line, clr, row, col, len);
  s.lexicalhl ([line], [row]);
}

define waddline (s, line, clr, row)
{
  smg->atrcaddnstr (line, clr, row, s._indent, s._linlen);
  s.lexicalhl ([line], [row]);
}

%%% LIB

private define _set_clr_ (s, clr, set)
{
  s.clrs[-1] = clr;
  SMGIMG[s.rows[-1]][1] = clr;
  if (set)
    smg->hlregion (clr, s.rows[-1], 0, 1, COLUMNS);
}

define set_clr_fg (b, set)
{
  _set_clr_ (b, VED_INFOCLRFG, set);
}

define set_clr_bg (b, set)
{
  _set_clr_ (b, VED_INFOCLRBG, set);
}

define initrowsbuffvars (s)
{
  s.cols = Integer_Type[length (s.rows)];
  s.cols[*] = 0;

  s.clrs = Integer_Type[length (s.rows)];
  s.clrs[*] = 0;
  s.clrs[-1] = VED_INFOCLRFG;
 
  s._avlins = length (s.rows) - 2;
}

define get_cur_wind ()
{
  return VED_WIND[VED_CUR_WIND];
}

define get_cur_frame ()
{
  return get_cur_wind ().cur_frame;
}

define get_cur_rline ()
{
  return get_cur_wind ().rline;
}

define setbuf (key)
{
  variable w = get_cur_wind ();
  
  ifnot (any (key == w.bufnames))
    return;
 
  variable s = w.buffers[key];
  
  variable frame = qualifier ("frame", w.cur_frame);

  if (frame > length (w.frame_names) - 1)
    return;

  w.frame_names[frame] = key;
 
  if (s._autochdir && 0 == VED_ISONLYPAGER)
    () = chdir (s._dir);
}

define addbuf (s)
{
  ifnot (path_is_absolute (s._fname))
    s._absfname = getcwd () + s._fname;
  else
    s._absfname = s._fname;

  variable w = get_cur_wind ();

  if (any (s._absfname == w.bufnames))
    return;
  
  w.buffers[s._absfname] = s;
  w.bufnames = [w.bufnames,  s._absfname];
  w.buffers[s._absfname]._dir = realpath (path_dirname (s._absfname));
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

define draw_wind ()
{
  variable w = get_cur_wind ();
  variable i;
  variable s;
  variable cur;

  _for i (0, w.frames - 1)
    {
    s = w.buffers[w.frame_names[i]];
    if (i == w.cur_frame)
      {
      cur = s;
      cur._i = cur._ii;
      continue;
      }

    s._i = s._ii;
    set_clr_bg (s, NULL);
    s.draw (;dont_draw);
    }
 
  cur.draw ();
  smg->setrc (cur.ptr[0], cur.ptr[1]);
  if (cur._autochdir && 0 == VED_ISONLYPAGER)
    () = chdir (cur._dir);
}

% many functions (like the next) imply no errors.
% the logic is to unveil any code errors.
% like the test phase to a waterfall model.

define get_buf (name)
{
  variable w = get_cur_wind ();
 
  ifnot (any (name == w.bufnames))
    return NULL;

  return w.buffers[name];
}

define get_cur_buf ()
{
  variable w = get_cur_wind ();
  return w.buffers[w.frame_names[w.cur_frame]];
}

define get_cur_bufname ()
{
  return get_cur_buf ()._absfname;
}

define get_frame_buf (frame)
{
  variable w = get_cur_wind ();
  if (frame >= w.frames)
    return NULL;

  return w.buffers[w.frame_names[frame]];
}

define change_frame ()
{
  variable w = get_cur_wind ();
  variable s = w.buffers[w.frame_names[w.cur_frame]];
  variable dir = qualifier ("dir", "next");

  set_clr_bg (s, 1);

  if ("next" == dir)
    w.cur_frame = w.cur_frame == w.frames - 1 ? 0 : w.cur_frame + 1;
  else
    w.cur_frame = 0 == w.cur_frame ? w.frames - 1 : w.cur_frame - 1;

  s = get_cur_buf ();

  set_clr_fg (s, 1);
  
  setbuf (s._absfname);

  smg->setrcdr (s.ptr[0], s.ptr[1]);
}

define framesize (frames)
{
  variable f = Integer_Type[frames];
  variable ff = Array_Type[frames];
  variable len = length (VED_ROWS);
  
  f[*] = len / frames;
  f[0] += len mod frames;

  variable i;
  variable istart = 0;
  variable iend;

  _for i (0, length (f) - 1)
    {
    iend = istart + f[i] - 1;
    ff[i] = VED_ROWS[[istart:iend]];
    istart = iend + 1;
    }
  
  return ff;
}

define del_frame ()
{
  variable frame = _NARGS ? () : get_cur_frame ();
  variable w = get_cur_wind ();

  if (frame >= w.frames)
    return;

  if (1 == w.frames)
    return;

  w.frame_names[frame] = NULL;
  w.frame_names = w.frame_names[wherenot (_isnull (w.frame_names))];
  w.frames--;

  variable setframesize = qualifier ("framesize_func", &framesize);

  w.frame_rows = (@setframesize) (w.frames);
  
  variable cur_fr = get_cur_frame ();
  
  if (frame == w.frames || cur_fr > frame)
    w.cur_frame--;

  variable i;
  variable s;

  _for i (0, w.frames - 1)
    {
    s = w.buffers[w.frame_names[i]];
    s.rows = w.frame_rows[i];
    initrowsbuffvars (s);
    
    s._i = s._ii;

    if (i == w.cur_frame)
      set_clr_fg (s, NULL);
    else
      set_clr_bg (s, NULL);

    s.ptr[0] = s.rows[0];
    s.ptr[1] = s._indent;
 
    s._findex = s._indent;
    s._index = s._indent;
    }

  draw_wind ();
}

define new_frame (fn)
{
  variable w = get_cur_wind ();
  if (w.frames == VED_MAXFRAMES)
    return;
  
  variable i;
  variable s;
  variable b;
  
  w.frames++;

  variable setframesize = qualifier ("framesize_func", &framesize);

  w.frame_rows = (@setframesize) (w.frames);

  w.cur_frame = w.frames - 1;
  
  variable ft = get_ftype (fn);
  s = init_ftype (ft);
  variable func = __get_reference (sprintf ("%s_settype", ft));
  (@func) (s, fn, w.frame_rows[-1], NULL);

  w.frame_names = [w.frame_names, fn];
  
  setbuf (s._absfname);

  % fine tuning maybe is needed
  _for i (0, w.cur_frame - 1)
    {
    s = w.buffers[w.frame_names[i]];
    s.rows = w.frame_rows[i];
    initrowsbuffvars (s);
    s._i = s._ii;
    s.clrs[-1] = VED_INFOCLRBG;
    s.ptr[0] = s.rows[0];
    s.ptr[1] = s._indent;
 
    s._findex = s._indent;
    s._index = s._indent;
    }
    
  draw_wind ();
}

define del_wind (name)
{
  if (1 == length (VED_WIND))
    return;

  variable winds = assoc_get_keys (VED_WIND);
  
  ifnot (any (name == winds))
    return;
  
  winds = winds[array_sort (winds)];

  variable i = wherefirst (name == winds);

  assoc_delete_key (VED_WIND, name);

  if (name == VED_CUR_WIND)
    {
    VED_CUR_WIND = i ? winds[i-1] : winds[-1];
    draw_wind ();
    }
}

define on_wind_change (w)
{
}

define wind_change (to)
{
  variable winds = assoc_get_keys (VED_WIND);
  winds = winds[array_sort (winds)];

  variable w;
  variable i;
  
  if (Integer_Type == typeof (to))
    if (length (winds) - 1 < to)
      return;
    else
      w = winds[to];
  else
    ifnot (any ([",", "."] == to))
      return;
    else
      if (to == ",")
        w = winds[wherefirst (winds == VED_CUR_WIND) - 1];
      else
        {
        i = wherefirst (winds == VED_CUR_WIND);
        i = i == length (winds) - 1 ? 0 : i + 1;
        w = winds[i];
        }

  if (w == VED_CUR_WIND)
    return;

  VED_PREV_WIND = VED_CUR_WIND;
  VED_CUR_WIND = w;

  w = VED_WIND[w];
  
  on_wind_change (w);
  
  draw_wind ();
}

define on_wind_new (w)
{
}

define wind_init (name, frames)
{
  if (any (name == assoc_get_keys (VED_WIND)) && 0 == qualifier_exists ("force"))
    return;

  variable setframesize = qualifier ("framesize_func", &framesize);

  VED_WIND[name] = @Wind_Type;
  VED_WIND[name].frames = frames > VED_MAXFRAMES
    ? VED_MAXFRAMES
    : frames < 1
      ? 1
      : frames;
  VED_WIND[name].frame_names = String_Type[VED_WIND[name].frames];
  VED_WIND[name].frame_rows = (@setframesize) (VED_WIND[name].frames);
  VED_WIND[name].cur_frame = 0;
  VED_WIND[name].buffers = Assoc_Type[Ftype_Type];
  VED_WIND[name].bufnames = String_Type[0];

  if (qualifier_exists ("on_wind_new"))
    on_wind_new (VED_WIND[name]);
}

define new_wind ()
{
  variable name = _NARGS ? () : NULL;
  
  variable i;
  variable winds = assoc_get_keys (VED_WIND);

  if (any (name == winds))
    return;

  if (NULL == name)
    _for i ('a', 'z')
      {
      name = char (i); 
      ifnot (any (name == winds))
        break;

      if ('z' == i)
        return;
      }
  
  ifnot (qualifier_exists ("in_bg")) 
    {
    ifnot (NULL == VED_CUR_WIND)
      VED_PREV_WIND = VED_CUR_WIND;
    VED_CUR_WIND = name;
    }
  
  wind_init (name, 1;;__qualifiers ());

  if (qualifier_exists ("draw_wind"))
    draw_wind ();
}

define bufdelete (s, bufname, force)
{
  if (any (bufname == UNDELETABLE))
    return;

  variable w = get_cur_wind ();

  ifnot (any (bufname == w.bufnames))
    return;
 
  if (s._flags & VED_MODIFIED && force)
    {
    variable bts = 0;
    variable retval = __writetofile (bufname, s.lines, s._indent, &bts);
    ifnot (0 == retval)
      {
      send_msg_dr (errno_string (retval), 1, NULL, NULL);
      return;
      }
    }

  variable isatframe = wherefirst (w.frame_names == bufname);
  variable iscur = get_cur_bufname () == bufname;

  assoc_delete_key (w.buffers, bufname);
 
  variable index = wherefirst (bufname == w.bufnames);
  
  w.bufnames[index] = NULL;
  w.bufnames = w.bufnames[wherenot (_isnull (w.bufnames))];

  variable winds = assoc_get_keys (VED_WIND);

  ifnot (length (w.bufnames))
    if (1 == length (winds))
      exit_me (0);
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
    if (1 < w.frames)
      del_frame (isatframe);
  
  if (iscur)
    {
    index = index ? index - 1 : length (w.bufnames) - 1;
 
    setbuf (w.bufnames[index]);
 
    s = get_cur_buf ();
    s.draw ();
    }
}

define preloop (s)
{
  MARKS[string ('`')].ptr = s.ptr;
  MARKS[string ('`')]._i = s._ii;
}

%%% VED OBJECT FUNCTIONS

private define _draw_ (s)
{
  if (-1 == s._len)
    {
    s.lins = [" "];
    s.lnrs = [0];
    s._ii = 0;
 
    smg->aratrcaddnstrdr ([repeat (" ", COLUMNS), tail (s)], [0, VED_INFOCLRFG],
      [s.rows[0], s.rows[-1]], [0, 0], s.rows[0], 0, COLUMNS);

    return;
    }

  s.lnrs = Integer_Type[0];
  s.lins = String_Type[0];

  variable
    i = s.rows[0],
    ar = String_Type[0];

  s._ii = s._i;

  while (s._i <= s._len && i <= s.rows[-2])
    {
    s.lnrs = [s.lnrs, s._i];
    s.lins = [s.lins, s.lines[s._i]];
    s._i++;
    i++;
    }

  s.vlins = [s.rows[0]:s.rows[0] + length (s.lins) - 1];

  s._i = s._i - (i) + s.rows[0];

  if (-1 == s._i)
    s._i = 0;

  if (s.ptr[0] >= i)
    s.ptr[0] = i - 1;

  ar = array_map (String_Type, &substr, s.lins, 1, s._maxlen);

  if (length (ar) < length (s.rows) - 1)
    {
    variable t = String_Type[length (s.rows) - length (ar) - 1];
    t[*] = " ";
    ar = [ar, t];
    }
 
  ar = [ar, tail (s;;__qualifiers ())];

  _for i (0, length (ar) - 1)
    SMGIMG[s.rows[i]] = {[ar[i]], [s.clrs[i]], [s.rows[i]], [s.cols[i]]};

  smg->aratrcaddnstr (ar, s.clrs, s.rows, s.cols, COLUMNS);

  s.lexicalhl (ar[[:-2]], s.vlins);
 
  (@[&smg->setrcdr, &smg->setrc][qualifier_exists ("dont_draw")]) (s.ptr[0], s.ptr[1]);
}

private define _vedloopcallback_ (s)
{
  (@VED_PAGER[string (s._chr)]) (s);
}

private define _vedloop_ (s)
{
  variable rl;

  forever
    {
    s = get_cur_buf ();
    VEDCOUNT = -1;
    s._chr = getch ();
 
    if ('0' <= s._chr <= '9')
      {
      VEDCOUNT = "";
 
      while ('0' <= s._chr <= '9')
        {
        VEDCOUNT += char (s._chr);
        s._chr = getch ();
        }

      VEDCOUNT = integer (VEDCOUNT);
      }

    s.vedloopcallback ();
 
    if (':' == s._chr && 0 == VED_ISONLYPAGER && VED_RLINE)
      {
      topline (" -- command line --");
      rl = get_cur_rline ();
      rline->set (rl);
      rline->readline (rl;
        ved = s, draw = (@__get_reference ("SCRATCH")) == s._absfname ? 0 : 1);

      if ('!' == get_cur_rline ().argv[0][0] &&
         (@__get_reference ("SCRATCH")) == s._absfname)
        {
        (@__get_reference ("draw")) (s);
        continue;
        }

      topline (" -- pager --");
      s = get_cur_buf ();
      smg->setrcdr (s.ptr[0], s.ptr[1]);
      }

    if ('q' == s._chr && VED_ISONLYPAGER)
      break;
    }
}

%%% SYNTAX PUBLIC FUNCTIONS

define __hl_groups (lines, vlines, colors, regexps)
{
  variable
    i,
    ii,
    col,
    subs,
    match,
    color,
    regexp,
    context;
 
  _for i (0, length (lines) - 1)
    {
    _for ii (0, length (regexps) - 1)
      {
      color = colors[ii];
      regexp = regexps[ii];
      col = 0;

      while (subs = pcre_exec (regexp, lines[i], col), subs > 1)
        {
        match = pcre_nth_match (regexp, 1);
        col = match[0];
        context = match[1] - col;
        smg->hlregion (color, vlines[i], col, 1, context);
        col += context;
        }
      }
    }
}
 
%%% SYN CALLBACK FUNCTIONS

private define autoindent (s, indent, line)
{
  % lookup for a (not private) type_autoindent
  variable f = __get_reference (s._type + "_autoindent");
  % call it (if exists) and calc the value
  if (NULL == f)
  % else calculate the value as:
    @indent =  s._indent + (s._autoindent ? s._shiftwidth : 0);
  else
    @indent = (@f) (s, line);
}

private define lexicalhl ()
{
  loop (3)
    pop ();
}

define deftype ()
{
  variable type = struct
    {
    _indent = 0,
    _shiftwidth = 4,
    _maxlen = COLUMNS,
    _autochdir = 1,
    _autoindent = 0,
    autoindent = &autoindent,
    draw = &_draw_,
    lexicalhl = &lexicalhl,
    vedloop = &_vedloop_,
    vedloopcallback = &_vedloopcallback_,
    };

  return type;
}

%%% MARK FUNCTIONS

private define mark_init (m)
{
  ifnot (assoc_key_exists (MARKS, m))
    MARKS[m] = @Pos_Type;
}

array_map (&mark_init, array_map (String_Type, &string, ['`', '<', '>']));

private define mark_set (m, s)
{
  MARKS[m]._i = s._ii;
  MARKS[m].ptr = @s.ptr;
}

define markbacktick (s)
{
  mark_set (string ('`'), s);
}

private define mark (s)
{
  variable mark = getch (;disable_langchange);
 
  if ('a' <= mark <= 'z')
    {
    mark = string (mark);
    mark_init (mark); 
    mark_set (mark, s);
    }
}

private define mark_get ()
{
  variable marks = assoc_get_keys (MARKS);
  variable mark = getch (;disable_langchange);
 
  mark = string (mark);

  if (any (mark == marks))
    return @MARKS[mark];
  
  return NULL;
}

% PAGER
%% PG LIB
%%% GENERIC (USED BY OTHER MODES)
 
private define __pg_left (s)
{
  ifnot (s.ptr[1] - s._indent)
    ifnot (s._is_wrapped_line)
      return -1;

  s._index--;

  if (s._is_wrapped_line && 0 == s.ptr[1] - s._indent)
    {
    s._findex--;
 
    ifnot (s._findex)
      s._is_wrapped_line = 0;
 
    return 1;
    }

  s.ptr[1]--;
 
  return 0;
}

private define __pg_right (s, linlen)
{
  if (s._index - s._indent == linlen - 1 || 0 == linlen)
    return -1;

  if (s.ptr[1] < s._maxlen - 1)
    {
    s.ptr[1]++;
    s._index++;
    return 0;
    }
 
  s._index++;
  s._findex++;
 
  return 1;
}

%% USED BY PAGER COMMANDS

private define _indent_in_ (s, line, i_)
{
  ifnot (strlen (line) - s._indent)
    return NULL;
  
  ifnot (isblank (line[s._indent]))
    return NULL;
 
  while (isblank (line[@i_]) && @i_ < s._shiftwidth + s._indent)
    @i_++;

  return substr (line, @i_ + 1 - s._indent, -1);
}

private define _adjust_col_ (s, linlen, plinlen)
{
  if (linlen == 0 || 0 == s.ptr[1] - s._indent)
    {
    s.ptr[1] = s._indent;
    s._findex = s._indent;
    s._index = s._indent;
    }
  else if (linlen > s._linlen && s.ptr[1] + 1 == s._maxlen ||
    (s.ptr[1] - s._indent == plinlen - 1 && linlen > s._linlen))
      {
      s.ptr[1] = s._maxlen - 1;
      s._findex = s._indent;
      s._index = s._linlen - 1 + s._indent;
      }
  else if ((0 != plinlen && s.ptr[1] - s._indent == plinlen - 1 && (
      linlen < s.ptr[1] || linlen < s._linlen))
     || (s.ptr[1] - s._indent && s.ptr[1] - s._indent >= linlen))
      {
      s.ptr[1] = linlen - 1 + s._indent;
      s._index = linlen - 1 + s._indent;
      s._findex = s._indent;
      }
}

private define _word_change_case_ (s, what)
{
  variable
    ii,
    end,
    start,
    word,
    func_cond = what == "toupper" ? &islower : &isupper,
    func = what == "toupper" ? &toupper : &tolower,
    col = s._index,
    i = v_lnr (s, '.'),
    line = v_lin (s, '.');
 
  word = find_word (s, line, col, &start, &end);

  variable ar = decode (word);
  _for ii (0, length (ar) - 1)
    if ((@func_cond) (ar[ii]))
      word += char ((@func) (ar[ii]));
    else
      word += char (ar[ii]);

  line = sprintf ("%s%s%s", substr (line, 1, start), word, substr (line, end + 2, -1));
  s.lins[s.ptr[0] - s.rows[0]] = line;
  s.lines[i] = line;
  s.ptr[1] = start;
  s._index = start;

  set_modified (s);
 
  s.st_.st_size = getsizear (s.lines);

  waddline (s, line, 0, s.ptr[0]);

  draw_tail (s);
}

private define _gotoline_ (s)
{
  if (VEDCOUNT <= s._len + 1)
    {
    markbacktick (s);
    s._i = VEDCOUNT - (VEDCOUNT ? 1 : 0);
    s.draw (;dont_draw);

    s.ptr[0] = s.rows[0];
    s.ptr[1] = s._indent;
    s._findex = s._indent;
    s._index = s._indent;

    smg->setrcdr (s.ptr[0], s.ptr[1]);
    }
}

%% PG OBJECT FUNCTIONS

private define pg_down (s)
{
  variable
    lnr = v_lnr (s, '.'),
    linlen,
    plinlen;

  if (lnr == s._len)
    return;

  if (s._is_wrapped_line)
    {
    waddline (s, getlinestr (s, v_lin (s, '.'), 1), 0, s.ptr[0]);
    s._is_wrapped_line = 0;
    }

  plinlen = v_linlen (s, '.');

  if (s.ptr[0] < s.vlins[-1])
    {
    s.ptr[0]++;
 
    linlen = v_linlen (s, '.');
 
    _adjust_col_ (s, linlen, plinlen);

    draw_tail (s);

    return;
    }

  if (s.lnrs[-1] == s._len)
    return;

  s._i++;
 
  ifnot (s.ptr[0] == s.vlins[-1])
    s.ptr[0]++;

  s.draw (;dont_draw);
 
  linlen = v_linlen (s, '.');
 
  _adjust_col_ (s, linlen, plinlen);
 
  smg->setrcdr (s.ptr[0], s.ptr[1]);
}

private define pg_up (s)
{
  variable
    linlen,
    plinlen;

  if (s._is_wrapped_line)
    {
    waddline (s, getlinestr (s, v_lin (s, '.'), 1), 0, s.ptr[0]);
    s._is_wrapped_line = 0;
    }

  plinlen = v_linlen (s, '.');

  if (s.ptr[0] > s.vlins[0])
    {
    s.ptr[0]--;
 
    linlen = v_linlen (s, '.');
    _adjust_col_ (s, linlen, plinlen);
 
    draw_tail (s);
 
    return;
    }

  ifnot (s.lnrs[0])
    return;

  s._i--;

  s.draw (;dont_draw);
 
  linlen = v_linlen (s, '.');
 
  _adjust_col_ (s, linlen, plinlen);
 
  smg->setrcdr (s.ptr[0], s.ptr[1]);
}

private define pg_eof (s)
{
  if (VEDCOUNT > -1)
    {
    ifnot (VEDCOUNT + 1)
      VEDCOUNT = 0;

    _gotoline_ (s);
    return;
    }

  markbacktick (s);

  s._i = s._len - s._avlins;

  s.ptr[1] = s._indent;
  s._findex = s._indent;
  s._index = s._indent;

  if (length (s.lins) < s._avlins - 1)
    {
    s.ptr[0] = s.vlins[-1];
    smg->setrcdr (s.ptr[0], s.ptr[1]);
    return;
    }

  s.draw (;dont_draw);

  s.ptr[0] = s.vlins[-1];

  smg->setrcdr (s.ptr[0], s.ptr[1]);
}

private define pg_bof (s)
{
  if (VEDCOUNT > 0)
    {
    _gotoline_ (s);
    return;
    }

  markbacktick (s);

  s._i = 0;
 
  s.ptr[0] = s.rows[0];
  s.ptr[1] = s._indent;
  s._findex = s._indent;
  s._index = s._indent;
 
  s.draw ();
}

private define pg_left (s)
{
  variable retval = __pg_left (s);
 
  if (-1 == retval)
    return;

  if (retval)
    {
    variable line;
    if (s._is_wrapped_line)
      line = getlinestr (s, v_lin (s, '.'), s._findex + 1);
    else
      line = getlinestr (s, v_lin (s, '.'), 1);

    waddline (s, line, 0, s.ptr[0]);
    }

  draw_tail (s);
}

private define pg_right (s)
{
  variable
    line = v_lin (s, '.'),
    retval = __pg_right (s, v_linlen (s, '.'));

  if (-1 == retval)
    return;

  if (retval)
    {
    line = getlinestr (s, line, s._findex + 1 - s._indent);
    waddline (s, line, 0, s.ptr[0]);
    s._is_wrapped_line = 1;
    }

  draw_tail (s);
}

private define pg_page_down (s)
{
  if (s._i + s._avlins > s._len)
    return;
 
  markbacktick (s);

  s._is_wrapped_line = 0;
  s._i += (s._avlins);

  s.ptr[1] = s._indent;
  s._index = s._indent;
  s._findex = s._indent;

  s.draw ();
}

private define pg_page_up (s)
{
  ifnot (s.lnrs[0] - 1)
    return;
 
  markbacktick (s);

  if (s.lnrs[0] >= s._avlins)
    s._i = s.lnrs[0] - s._avlins;
  else
    s._i = 0;

  s._is_wrapped_line = 0;
  s.ptr[1] = s._indent;
  s._findex = s._indent;
  s._index = s._indent;

  s.draw ();
}

private define pg_eos (s)
{
  variable linlen = v_linlen (s, '.');

  markbacktick (s);

  if (linlen > s._linlen)
    {
    s.ptr[1] = s._maxlen - 1;
    s._index = s._findex + s._linlen - 1 + s._indent;
    }
  else if (0 == linlen)
    {
    s.ptr[1] = s._indent;
    s._index = s._indent;
    s._findex = s._indent;
    }
  else
    {
    s.ptr[1] = linlen + s._indent - 1;
    s._findex = s._indent;
    s._index = linlen - 1 + s._indent;
    }
 
  draw_tail (s);
}

private define pg_eol (s)
{
  variable linlen = v_linlen (s, s.ptr[0]);
 
  s._index = linlen - 1;

  if (linlen < s._linlen)
    s.ptr[1] = linlen + s._indent - 1;
  else
    {
    s.ptr[1] = s._maxlen - 1;
    s._index += s._indent;

    s._findex = linlen - s._linlen;

    variable line = getlinestr (s, v_lin (s, '.'), s._findex + 1);
 
    waddline (s, line, 0, s.ptr[0]);

    s._is_wrapped_line = 1;
    }
 
  draw_tail (s);
}

private define pg_bol (s)
{
  s.ptr[1] = s._indent;
  s._findex = s._indent;
  s._index = s._indent;

  if (s._is_wrapped_line)
    {
    variable line = getlinestr (s, v_lin (s, '.'), 1);
    waddline (s, line, 0, s.ptr[0]);
    s._is_wrapped_line = 0;
    }

  draw_tail (s);
}

private define pg_bolnblnk (s)
{
  s.ptr[1] = s._indent;

  variable linlen = v_linlen (s, '.');

  loop (linlen)
    {
    ifnot (isblank (s.lins[s.ptr[0] - s.rows[0]][s.ptr[1]]))
      break;

    s.ptr[1]++;
    }

  s._findex = s._indent;
  s._index = s.ptr[1] - s._indent;

  draw_tail (s);
}

private define pg_g (s)
{
  variable
    chr = getch ();

  if ('g' == chr)
    {
    pg_bof (s);
    return;
    }

  if ('U' == chr)
    {
    _word_change_case_ (s, "toupper");
    return;
    }

  if ('u' == chr)
    {
    _word_change_case_ (s, "tolower");
    return;
    }
}

private define pg_Yank (s)
{
  variable
    reg = qualifier ("reg", "\""),
    line = v_lin (s, '.');

  REG[reg] = line + "\n";
  seltoX (line + "\n");
}

private define pg_reread (s)
{
  s.lines = getlines (s._fname, s._indent, s.st_);

  s._len = length (s.lines) - 1;
 
  ifnot (s._len)
    {
    s._ii = 0;
    s.ptr[0] = s.rows[0];
    }
  else if (s._ii < s._len)
    {
    s._i = s._ii;
    while (s.ptr[0] - s.rows[0] + s._ii > s._len)
      s.ptr[0]--;
    }
  else
    {
    while (s._ii > s._len)
      s._ii--;

    s.ptr[0] = s.rows[0];
    }

  s.ptr[1] = 0;
 
  s._i = s._ii;

  s.draw ();
}

define _change_frame_ (s)
{
  change_frame ();
  s = get_cur_buf ();
}

define _new_frame_ (s)
{ 
  new_frame (TEMPDIR + "/" + string (_time) + ".noname");
  s = get_cur_buf ();
}

define _del_frame_ (s)
{
  del_frame ();
  s = get_cur_buf ();
}

define _del_wind_ (s)
{
  del_wind (VED_CUR_WIND);
  s = get_cur_buf ();
}

define on_wind_change (w)
{
  topline (" -- ved --");
  setbuf (w.frame_names[w.cur_frame]);
}

define on_wind_new (w)
{
  variable fn = TEMPDIR + "/" + string (_time) + ".noname";
  variable s = init_ftype ("txt");
  variable func = __get_reference ("txt_settype");
  (@func) (s, fn, w.frame_rows[0], NULL);
  
  setbuf (fn);
  (@__get_reference ("__initrline"));
  topline (" -- ved --");
  draw_wind ();
}

define _new_wind_ (s)
{
  new_wind (;on_wind_new);
  s = get_cur_buf ();
}

define _goto_wind_ (s, chr)
{
  if (any (['0':'9'] == chr))
    chr = int (chr - '0');
  else
    chr = char (chr);

  wind_change (chr);
  s = get_cur_buf ();
}

define handle_w (s)
{
  variable chr = getch ();
 
  if (any (['w', 's', keys->CTRL_w, 'd', 'k', 'n', ',', '.', ['0':'9']] == chr))
    {
    if (any (['w', keys->CTRL_w, keys->DOWN] == chr))
      {
      _change_frame_ (s);
      return;
      }
    
    if ('s' == chr)
      {
      _new_frame_ (s);
      return;
      }

    if ('d' == chr)
      {
      _del_frame_ (s);
      return;
      }

    if ('k' == chr)
      {
      _del_wind_ (s);
      return;
      }

    if ('n' == chr)
      {
      _new_wind_ (s);
      return;
      }

    if (any ([['0':'9'], ',', '.'] == chr))
      {
      _goto_wind_ (s, chr);
      return;
      }
    }
}

public define __pg_on_carriage_return (s)
{
}

private define pg_write_on_esc (s)
{
  __writefile (s, NULL, s.ptr, NULL);
  send_msg_dr ("", 14, NULL, NULL);
  sleep (0.001);
  smg->setrcdr (s.ptr[0], s.ptr[1]);
}
 
define pg_gotomark (s)
{
  variable m = mark_get ();
  if (NULL == m)
    return;

  if (m._i > s._len)
    return;

  markbacktick (s);

  s._i = m._i;
  s.ptr = m.ptr;

  s.draw ();
}

VED_PAGER[string ('m')]          = &mark;
VED_PAGER[string ('\r')]         = &__pg_on_carriage_return;
VED_PAGER[string (0x1001a)]      = &pg_write_on_esc;
VED_PAGER[string ('`')]          = &pg_gotomark;
VED_PAGER[string (keys->CTRL_l)] = &pg_reread;
VED_PAGER[string ('Y')]          = &pg_Yank;
VED_PAGER[string (keys->DOWN)]   = &pg_down;
VED_PAGER[string ('j')]          = &pg_down;
VED_PAGER[string ('k')]          = &pg_up;
VED_PAGER[string (keys->UP)]     = &pg_up;
VED_PAGER[string ('G')]          = &pg_eof;
VED_PAGER[string (keys->HOME)]   = &pg_bof;
VED_PAGER[string ('g')]          = &pg_g;
VED_PAGER[string (' ')]          = &pg_page_down;
VED_PAGER[string (keys->NPAGE)]  = &pg_page_down;
VED_PAGER[string (keys->CTRL_f)] = &pg_page_down;
VED_PAGER[string (keys->CTRL_b)] = &pg_page_up;
VED_PAGER[string (keys->PPAGE)]  = &pg_page_up;
VED_PAGER[string (keys->RIGHT)]  = &pg_right;
VED_PAGER[string ('l')]          = &pg_right;
VED_PAGER[string ('h')]          = &pg_left;
VED_PAGER[string (keys->LEFT)]   = &pg_left;
VED_PAGER[string ('-')]          = &pg_eos;
VED_PAGER[string (keys->END)]    = &pg_eol;
VED_PAGER[string ('$')]          = &pg_eol;
VED_PAGER[string ('^')]          = &pg_bolnblnk;
VED_PAGER[string ('0')]          = &pg_bol;
VED_PAGER[string (keys->CTRL_w)] = &handle_w;

%%% FIXME DIFF UNDO

define diff (lines, fname, retval)
{
  variable
    status,
    isbigin = strbytelen (lines) >= 256 * 256,
    p = proc->init (isbigin ? 0 : 1, 1, 1),
    com = [which ("diff"), "-u", fname, "-"];

  if (isbigin)
    {
    variable fn = VED_DIR + "/" + path_basename (fname) + "_" + string (PID);
    () = writestring (fn, lines);
    com[-1] = fn; 
    }
  else
    p.stdin.in = lines;

  status = p.execv (com, NULL);

  if (NULL == status)
    {
    @retval = NULL;
    return "couldn't invoke diff process";
    }

  ifnot (2 > status.exit_status)
    {
    @retval = -1;
    return p.stderr.out;
    }
 
  ifnot (status.exit_status)
    {
    @retval = 0;
    return String_Type[0];
    }
 
  @retval = 1;

  return p.stdout.out;
}

define patch (in, dir, retval)
{
  variable isbigin = 256 * 256 >= strbytelen (in);
  variable isbigout = qualifier ("isbig", 0);
  variable com = [which ("patch"), "-d", dir, "-r", VED_DIR + "/patchrej.diff"];
  variable out = "-";
      
  if (isbigin)
    {
    variable fin = VED_DIR + "/pathchin.diff";
    () = writestring (fin, in);
    com = [com, "-i", fin];
    }
 
  if (isbigout)
    out = VED_DIR + "/patchout.diff";
   
  com = [com, "-o", out];
   
  variable p = proc->init (isbigin ? 0 : 1, 1, 1);
  ifnot (isbigin)
    p.stdin.in = in;

  variable status = p.execv (com, NULL);

  if (NULL == status)
    {
    @retval = NULL;
    return "couldn't invoke patch process";
    }
 
  ifnot (2 > status.exit_status)
    {
    @retval = -1;
    return p.stderr.out;
    }
 
  if (1 == status.exit_status)
    {
    @retval = 1;
    return p.stderr.out;
    }

  @retval = 0;

  return isbigout ? strjoin (readfile (out), "\n") : p.stdout.out;
}

define set_modified (s)
{
  s._flags |= VED_MODIFIED;
 
  variable
    retval,
    d = diff (strjoin (s.lines, "\n") + "\n", s._absfname, &retval);

  if (NULL == retval)
    {
    send_msg_dr (d, 1, s.ptr[0], s.ptr[1]);
    return;
    }
 
  if (-1 == retval)
    {
    % change
    send_msg_dr (d, 1, s.ptr[0], s.ptr[1]);
    return;
    }

  ifnot (retval)
    {
    send_msg_dr ("found no changes", 0, s.ptr[0], s.ptr[1]);
    return;
    }

  s.undo = [s.undo, d];
  list_append (s.undoset, [qualifier ("_i", s._ii), s.ptr[0], s.ptr[1]]);

  s._undolevel++;
}

private define undo (s)
{
  ifnot (length (s.undo))
    return;

  variable
    retval,
    in,
    isbig = 256 * 256 <= s.st_.st_size,
    d;
 
  if (0 == s._undolevel)
    {
    s.lines = getlines (s._absfname, s._indent, s.st_);
    s._len = length (s.lines) - 1;
    s._i = s._ii;
    s.draw ();
    return;
    }

  in = s.undo[s._undolevel - 1];

  d = patch (in, s._dir, &retval;isbig = isbig);
 
  if (NULL == retval)
    {
    send_msg_dr (d, 1, s.ptr[0], s.ptr[1]);
    return;
    }
 
  if (-1 == retval || 1 == retval)
    {
    % change
    send_msg_dr (d, 1, s.ptr[0], s.ptr[1]);
    return;
    }

  s.lines = strchop (d, '\n', 0);
  s._len = length (s.lines) - 1;
 
  s._i = s.undoset[s._undolevel - 1][0];
  s.ptr[0] = s.undoset[s._undolevel - 1][1];
  s.ptr[1] = s.undoset[s._undolevel - 1][2];

  s._undolevel--;
 
  s._flags |= VED_MODIFIED;

  s.draw ();
}

private define redo (s)
{
  if (s._undolevel == length (s.undo))
    return;

  variable
    retval,
    in = s.undo[s._undolevel],
    isbig = 256 * 256 <= s.st_.st_size,
    d;

  d = patch (in, path_dirname (s._fname), &retval;isbig = isbig);
 
  if (NULL == retval)
    {
    send_msg_dr (d, 1, s.ptr[0], s.ptr[1]);
    return;
    }
 
  if (-1 == retval || 1 == retval)
    {
    % change
    send_msg_dr (d, 1, s.ptr[0], s.ptr[1]);
    return;
    }
 
  s.lines = strchop (d, '\n', 0);
  s._len = length (s.lines) - 1;

  s._i = s.undoset[s._undolevel][0];
  s.ptr[0] = s.undoset[s._undolevel][1];
  s.ptr[1] = s.undoset[s._undolevel][2];

  s._undolevel++;

  s._flags |= VED_MODIFIED;

  s.draw ();
}

VED_PAGER[string ('u')] = &undo;
VED_PAGER[string (keys->CTRL_r)] = &redo;

%%% SEARCH

private variable
  s_col,
  s_fcol,
  s_lnr,
  s_found;

private define _init_search_hist_ ()
{
  variable ar = readfile (s_histfile);
  if (NULL != ar && length (ar))
    {
    array_map (&list_append, s_history, ar);
    s_histindex = 0;
    }
}

_init_search_hist_ ();

private define s_exit_rout (s, pat, draw)
{
  if (s_found && pat != NULL)
    {
    list_insert (s_history, pat);
    if (NULL == s_histindex)
      s_histindex = 0;
    }

  if (draw)
    if (s_found)
      {
      markbacktick (s);
      s_fcol = s_fcol > s._maxlen ? s._indent : s_fcol;
      s._i = s_lnr;
      s.ptr[0] = s.rows[0];
      s.ptr[1] = s_fcol;
      s._index = s_fcol;
      s._findex = s._indent;
      s.draw ();
      }

  smg->setrcdr (s.ptr[0], s.ptr[1]);
  send_msg (" ", 0);
  smg->atrcaddnstr (" ", 0, PROMPTROW, 0, COLUMNS);

  draw_tail (s);
}

private define search_backward (s, str)
{
  variable
    i,
    ar,
    pat,
    pos,
    cols,
    match,
    line,
    wrapped = 0,
    clrs = Integer_Type[0],
    rows = Integer_Type[4];
 
  rows[*] = MSGROW;

  try
    {
    pat = pcre_compile (str, PCRE_UTF8);
    }
  catch ParseError:
    {
    send_msg_dr ("error compiling pcre pattern", 1, PROMPTROW, s_col);
    return;
    }
 
  i = s_lnr;

  while (i > -1 || (i > s_lnr && wrapped))
    {
    line = getlinestr (s, s.lines[i], 1);
    if (pcre_exec (pat, line))
      {
      match = pcre_nth_match (pat, 0);
      ar = [
        sprintf ("row %d|", i + 1),
        substrbytes (line, 1, match[0]),
        substrbytes (line, match[0] + 1, match[1] - match[0]),
        substrbytes (line, match[1] + 1, -1)];
      cols = strlen (ar[[:-2]]);
      cols = [0, array_map (Integer_Type, &int, cumsum (cols))];
      clrs = [0, 0, VED_PROMPTCLR, 0];

      pos = [qualifier ("row", PROMPTROW),  s_col];
      if (qualifier_exists ("context"))
        pos[1] = match[1];

      smg->aratrcaddnstrdr (ar, clrs, rows, cols, pos[0], pos[1], COLUMNS);

      s_lnr = i;
      s_fcol = match[0];
      s_found = 1;

      return;
      }
    else
      ifnot (i)
        if (wrapped)
          break;
        else
          {
          i = s._len;
          wrapped = 1;
          }
      else
        i--;
    }
 
  s_found = 0;
  send_msg_dr ("Nothing found", 0, PROMPTROW, s_col);
}

private define search_forward (s, str)
{
  variable
    i,
    ar,
    pat,
    pos,
    cols,
    match,
    line,
    wrapped = 0,
    clrs = Integer_Type[0],
    rows = Integer_Type[4];
 
  rows[*] = MSGROW;

  try
    {
    pat = pcre_compile (str, PCRE_UTF8);
    }
  catch ParseError:
    {
    send_msg_dr ("error compiling pcre pattern", 1, PROMPTROW, s_col);
    return;
    }
 
  i = s_lnr;
 
  while (i <= s._len || (i < s_lnr && wrapped))
    {
    line = getlinestr (s, s.lines[i], 1);
    if (pcre_exec (pat, line))
      {
      match = pcre_nth_match (pat, 0);
      ar = [
        sprintf ("row %d|", i + 1),
        substrbytes (line, 1, match[0]),
        substrbytes (line, match[0] + 1, match[1] - match[0]),
        substrbytes (line, match[1] + 1, -1)];
      cols = strlen (ar[[:-2]]);
      cols = [0, array_map (Integer_Type, &int, cumsum (cols))];
      clrs = [0, 0, VED_PROMPTCLR, 0];

      pos = [qualifier ("row", PROMPTROW), s_col];
      if (qualifier_exists ("context"))
        pos[1] = match[1];
 
      smg->aratrcaddnstrdr (ar, clrs, rows, cols, pos[0], pos[1], COLUMNS);

      s_lnr = i;
      s_fcol = match[0];
      s_found = 1;
 
      return;
      }
    else
      if (i == s._len)
        if (wrapped)
          break;
        else
          {
          i = 0;
          wrapped = 1;
          }
      else
        i++;
    }
 
  s_found = 0;
  
  send_msg_dr ("Nothing found", 0, PROMPTROW, s_col);
}

private define search (s)
{
  variable
    cur_lang = input->getlang (),
    origlnr,
    dothesearch,
    type,
    typesearch,
    chr,
    pchr,
    str,
    pat = "";
 
  if (length (s_history))
    s_histindex = 0;
 
  s_found = 0;
  s_lnr = v_lnr (s, '.');

  s_fcol = s.ptr[1];
  origlnr = s_lnr;

  type = keys->BSLASH == s._chr ? "forward" : "backward";
  pchr = type == "forward" ? "/" : "?";
  str = pchr;
  s_col = 1;
 
  typesearch = type == "forward" ? &search_forward : &search_backward;
  write_prompt (str, s_col);
 
  forever
    {
    dothesearch = 0;
    chr = getch (;on_lang = &_on_lang_change_, on_lang_args = {"search", [PROMPTROW, s_col]});

    if (033 == chr)
      {
      s_exit_rout (s, NULL, 0);
      break;
      }
 
    if ((' ' <= chr < 64505) &&
        0 == any (chr == [keys->rmap.backspace, keys->rmap.delete,
        [keys->UP:keys->RIGHT], [keys->F1:keys->F12]]))
      {
      if (s_col == strlen (pat) + 1)
        pat += char (chr);
      else
        pat = substr (pat, 1, s_col - 1) + char (chr) + substr (pat, s_col, -1);

      s_col++;
      dothesearch = 1;
      }
 
    if (any (chr == keys->rmap.backspace) && strlen (pat))
      if (s_col - 1)
        {
        if (s_col == strlen (pat) + 1)
          pat = substr (pat, 1, strlen (pat) - 1);
        else
          pat = substr (pat, 1, s_col - 2) + substr (pat, s_col, -1);
 
        s_lnr = origlnr;

        s_col--;
        dothesearch = 1;
        }

    if (any (chr == keys->rmap.delete) && strlen (pat))
      {
      ifnot (s_col - 1)
        (pat = substr (pat, 2, -1), dothesearch = 1);
      else if (s_col != strlen (pat) + 1)
        (pat = substr (pat, 1, s_col - 1) + substr (pat, s_col + 1, -1),
         dothesearch = 1);
      }
 
    if (any (chr == keys->rmap.left) && s_col != 1)
      s_col--;
 
    if (any (chr == keys->rmap.right) && s_col != strlen (pat) + 1)
      s_col++;
 
    if ('\r' == chr)
      {
      s_exit_rout (s, pat, s_found);
      break;
      }
 
    if (chr == keys->UP)
      ifnot (NULL == s_histindex)
        {
        pat = s_history[s_histindex];
        if (s_histindex == length (s_history) - 1)
          s_histindex = 0;
        else
          s_histindex++;

        s_col = strlen (pat) + 1;
        str = pchr + pat;
        write_prompt (str, s_col);
        (@typesearch) (s, pat);
        continue;
        }

    if (chr == keys->DOWN)
      ifnot (NULL == s_histindex)
        {
        pat = s_history[s_histindex];
        ifnot (s_histindex)
          s_histindex = length (s_history) - 1;
        else
          s_histindex--;

        s_col = strlen (pat) + 1;
        str = pchr + pat;
        write_prompt (str, s_col);
        (@typesearch) (s, pat);
        continue;
        }

    if (chr == keys->CTRL_n)
      {
      if (type == "forward")
        if (s_lnr == s._len)
          s_lnr = 0;
        else
          s_lnr++;
      else
        ifnot (s_lnr)
          s_lnr = s._len;
        else
          s_lnr--;

      (@typesearch) (s, pat);
      }

    str = pchr + pat;
    write_prompt (str, s_col);

    if (dothesearch)
      (@typesearch) (s, pat);
    }
  
  ifnot (input->getlang () == cur_lang)
    input->setlang (cur_lang);
}

private define search_word (s)
{
  variable
    str,
    pat,
    end,
    chr,
    lcol,
    type,
    start,
    origlnr,
    typesearch,
    line = v_lin (s, '.');
 
  s_found = 0;
  s_fcol = s.ptr[1];
  s_lnr = v_lnr (s, '.');

  type = '*' == s._chr ? "forward" : "backward";
 
  typesearch = type == "forward" ? &search_forward : &search_backward;

  if (type == "forward")
    if (s_lnr == s._len)
      s_lnr = 0;
    else
      s_lnr++;
  else
    if (s_lnr == 0)
      s_lnr = s._len;
    else
      s_lnr--;

  s_col = s._index;
  lcol = s_col;

  if (isblank (substr (line, lcol + 1, 1)))
    return;
 
  pat = find_word (s, line, lcol, &start, &end);

  if (s_col - s._indent)
    pat = "\\W+" + pat;
  else
    pat = "^" + pat;

  if (s._index < v_linlen (s, '.'))
    pat += "\\W";

  (@typesearch) (s, pat;row = MSGROW, context);

  forever
    {
    ifnot (s_found)
      {
      s_exit_rout (s, NULL, 0);
      return;
      }

    chr = getch (;disable_langchange);
 
    ifnot (any ([keys->CTRL_n, 033, '\r'] == chr))
      continue;

    if (033 == chr)
      {
      s_exit_rout (s, NULL, 0);
      return;
      }
 
    if ('\r' == chr)
      {
      s_exit_rout (s, pat, s_found);
      return;
      }
 
    if (chr == keys->CTRL_n)
      {
      if (type == "forward")
        if (s_lnr == s._len)
          s_lnr = 0;
        else
          s_lnr++;
      else
        ifnot (s_lnr)
          s_lnr = s._len;
        else
          s_lnr--;

      (@typesearch) (s, pat;row = MSGROW, context);
      }
    }
}

VED_PAGER[string ('#')] = &search_word;
VED_PAGER[string ('*')] = &search_word;
VED_PAGER[string (keys->BSLASH)] = &search;
VED_PAGER[string (keys->QMARK)] = &search;

%%% VISUAL MODE

private define v_unhl_line (vs, s, index)
{
  smg->hlregion (0, vs.vlins[index], 0, 1, s._maxlen);
}

private define v_hl_ch (vs, s)
{
  variable i;
  _for i (0, length (vs.vlins) - 1)
    {
    v_unhl_line (vs, s, i);
    smg->hlregion (vs.clr, vs.vlins[i], vs.col[i], 1, strlen (vs.sel[i]));
    }

  ifnot (qualifier_exists ("dont_draw"))
    smg->refresh ();
}

private define v_hl_line (vs, s)
{
  variable i;
  _for i (0, length (vs.vlins) - 1)
    if (vs.vlins[i] >= s.rows[0])
      if (vs.vlins[i] == s.rows[-1])
        break;
      else
        smg->hlregion (vs.clr, vs.vlins[i], 0, 1,
          s._maxlen > vs.linlen[i] ? vs.linlen[i] : s._maxlen);
  
  ifnot (qualifier_exists ("dont_draw"))
    smg->refresh ();
}

private define v_calclines_up (s, vs, un, inc)
{
  if (un)
    v_unhl_line (vs, s, -1);

  vs.lines = vs.lines[[:-2]];
  vs.lnrs = vs.lnrs[[:-2]];
  vs.vlins = vs.vlins[[:-2]];
  vs.linlen = vs.linlen[[:-2]];

  if (inc)
    vs.vlins++;
}

private define v_calclines_up_ (s, vs, incr)
{
  vs.lines = [v_lin (s, '.'), vs.lines];
  vs.lnrs = [vs.lnrs[0] - 1, vs.lnrs];

  if (incr)
    vs.vlins++;

  vs.vlins = [s.ptr[0], vs.vlins];
  vs.linlen = [strlen (vs.lines[0]), vs.linlen];
}

private define v_l_up (vs, s)
{
  ifnot (v_lnr (s, '.'))
    return;
  
  if (s.ptr[0] == s.vlins[0]) %for now FIXME
    {
    s._i--;
    s.draw ();
    
    if (vs.lnrs[-1] <= vs.startlnr)
      v_calclines_up_ (s, vs, 1);
    else
      v_calclines_up (s, vs, 0, 1);
    
    v_hl_line (vs, s);
    return;
    }

  s.ptr[0]--;

  if (vs.lnrs[-1] > vs.startrow)
    v_calclines_up (s, vs, 1, 0);
  else
    v_calclines_up_ (s, vs, 0);

  v_hl_line (vs, s);
}

vis.l_up = &v_l_up;

private define v_calclines_down (s, vs, un, dec)
{
  if (un)
    v_unhl_line (vs, s, 0);

  vs.lines = vs.lines[[1:]];
  vs.lnrs = vs.lnrs[[1:]];
  vs.vlins = vs.vlins[[1:]];
  vs.linlen = vs.linlen[[1:]];

  if (dec)
    vs.vlins--;
}

private define v_calclines_down_ (s, vs, dec)
{
  vs.lines = [vs.lines, v_lin (s, '.')];
  vs.lnrs = [vs.lnrs, vs.lnrs[-1] + 1];

  if (dec)
    vs.vlins--;

  vs.vlins = [vs.vlins, s.ptr[0]];
  vs.linlen = [vs.linlen, strlen (vs.lines[-1])];
}

private define v_l_down (vs, s)
{
  if (v_lnr (s, '.') == s._len)
      return;

  if (s.ptr[0] == s.vlins[-1])
    {
    s._i++;
    s.draw ();
    
    if (vs.lnrs[0] < vs.startlnr)
      v_calclines_down (s, vs, 0, 1);
    else
      v_calclines_down_ (s, vs, 1);

    v_hl_line (vs, s);
    return;
    }    

  s.ptr[0]++;

  if (vs.lnrs[0] < vs.startlnr)
    v_calclines_down (s, vs, 1, 0);
  else
    v_calclines_down_ (s, vs, 0);

  v_hl_line (vs, s);
}

vis.l_down = &v_l_down;

private define v_l_loop (vs, s)
{
  variable chr, i;
 
  while (chr = getch (), any (vs.l_keys == chr))
    {
    if (chr == keys->DOWN)
      {
      vs.l_down (s);
      continue;
      }

    if (chr == keys->UP)
      {
      vs.l_up (s);
      continue;
      }

    if ('y' == chr)
      {
      REG["\""] = strjoin (vs.lines, "\n") + "\n";
      seltoX (strjoin (vs.lines, "\n") + "\n");
      break;
      }
    
    if ('>' == chr)
      {
      _for i (0, length (vs.lnrs) - 1)
        s.lines[vs.lnrs[i]] = repeat (" ", s._shiftwidth) + s.lines[vs.lnrs[i]];
      
      set_modified (s);
      break;
      }
    
    if ('<' == chr)
      {
      _for i (0, length (vs.lnrs) - 1)
        {
        variable i_ = s._indent;
        variable l = _indent_in_ (s, s.lines[vs.lnrs[i]], &i_);
        if (NULL == l)
          continue;
        
        s.lines[vs.lnrs[i]] = l;
        }

      set_modified (s);
      break;
      }

    if ('d' == chr)
      {
      REG["\""] = strjoin (vs.lines, "\n") + "\n";
      seltoX (strjoin (vs.lines, "\n") + "\n");
      s.lines[vs.lnrs] = NULL;
      s.lines = s.lines[wherenot (_isnull (s.lines))];
      s._len = length (s.lines) - 1;

      s._i = vs.lnrs[0] ? vs.lnrs[0] - 1 : 0;
      s.ptr[0] = s.rows[0];
      s.ptr[1] = s._indent;
      s._index = s._indent;
      s._findex = s._indent;
 
      if (-1 == s._len)
        {
        s.lines = [__get_null_str (s._indent)];
        s._len = 0;
        }
       
      s.st_.st_size = getsizear (s.lines);
      set_modified (s);
      s.draw ();
      return;
      }
    }

  vs.needsdraw = 1;
}

private define v_linewise_mode (vs, s)
{
  vs.linlen = [strlen (vs.lines[0])];

  v_hl_line (vs, s);
  
  v_l_loop (vs, s);
}

vis.l_mode = &v_linewise_mode;

private define v_c_left (vs, s, cur)
{
  variable retval = __pg_left (s);

  if (-1 == retval)
    return;
 
  vs.index[cur]--;

  if (retval)
    {
    variable lline;
    if (s._is_wrapped_line)
      {
      lline = getlinestr (s, vs.lines[cur], s._findex + 1 - s._indent);
      vs.wrappedmot--;
      }
    else
      lline = vs.lines[cur];

    waddline (s, lline, 0, s.ptr[0]);
    }

  if (s.ptr[1] < vs.startcol[cur])
    vs.col[cur] = s.ptr[1];
  else
    vs.col[cur] = vs.startcol[cur];

% if (s.ptr[1])
%   if (s.ptr[1] < vs.startcol[cur])
%     if (s._is_wrapped_line)
%       vs.col[cur] = vs.startcol[cur] - vs.wrappedmot;
%     else
%       vs.col[cur] = s.ptr[1];
%   else
%     if (s._is_wrapped_line)
%       vs.col[cur] = vs.startcol[cur] - vs.wrappedmot;
%     else
%      vs.col[cur] = vs.startcol[cur];
% else
%   if (s._is_wrapped_line)
%     vs.col[cur] = (l++, l - strlen (vs.sel[cur]) + 1);
%   else
%     vs.col[cur] = s.ptr[1];

  %s.col[cur] = s.ptr[1] < vs.startcol[cur] ? s.ptr[1] : vs.startcol[cur];
 % vs.col[cur] = s.ptr[1] < vs.startcol[cur]
 %   ? s._is_wrapped_line
 %     ? 0 == s.ptr[1]
 %       ? vs.startcol[cur] - vs.wrappedmot
 %       : vs.startcol[cur]
 %     : s.ptr[1]
 %   : s._is_wrapped_line
 %     ? vs.startcol[cur] - vs.wrappedmot
 %     : vs.startcol[cur];
  vs.col[cur] = s.ptr[1] < vs.startcol[cur]
    ? s._is_wrapped_line
      ? vs.startcol[cur] - vs.wrappedmot
      : s.ptr[1]
    : s._is_wrapped_line
      ? vs.startcol[cur] - vs.wrappedmot
      : vs.startcol[cur];
  vs.col[cur] = s.ptr[1] < vs.startcol[cur]
    ? s._is_wrapped_line
      ? vs.startcol[cur] - strlen (vs.sel[cur]) + 1
      : s.ptr[1]
    : s._is_wrapped_line
      ? vs.startcol[cur] - vs.wrappedmot
      : vs.startcol[cur];

  if (vs.index[cur] >= vs.startindex[cur])
    vs.sel[cur] = substr (vs.sel[cur], 1, strlen (vs.sel[cur]) - 1);
  else
    vs.sel[cur] = substr (vs.lines[cur], vs.index[cur] + 1, 1) + vs.sel[cur];

  v_hl_ch (vs, s);
}

vis.c_left = &v_c_left;

private define v_c_right (vs, s, cur)
{
  variable retval = __pg_right (s, vs.linlen[-1]);

  if (-1 == retval)
    return;
 
  vs.index[cur]++;

  if (retval)
    {
    variable lline = getlinestr (s, vs.lines[cur], s._findex + 1 - s._indent);
    waddline (s, lline, 0, s.ptr[0]);
    s._is_wrapped_line = 1;
    vs.wrappedmot++;
    }

  vs.col[cur] = s.ptr[1] < vs.startcol[cur]
    ? s.ptr[1]
    : s._is_wrapped_line
      ? vs.startcol[cur] - vs.wrappedmot
      : vs.startcol[cur];
 
  if (vs.index[cur] <= vs.startindex[cur])
    vs.sel[cur] = substr (vs.sel[cur], 2, -1);
  else
    vs.sel[cur] += substr (vs.lines[cur], vs.index[cur] + 1, 1);

  v_hl_ch (vs, s);
}

vis.c_right = &v_c_right;

private define v_char_mode (vs, s)
{
  variable
    sel,
    chr,
    cur = 0;
 
  vs.startcol = [vs.col[0]];
  vs.startindex = vs.index;
  vs.index = [vs.index];

  vs.sel = [substr (vs.lines[cur], vs.index[cur] + 1, 1)];

  v_hl_ch (vs, s);

  while (chr = getch (), any (vs.c_keys == chr))
    {
    if (keys->RIGHT == chr)
      {
      vs.c_right (s, cur);
      continue;
      }

    if (keys->LEFT == chr)
      {
      vs.c_left (s, cur);
      continue;
      }

    if ('y' == chr)
      {
      sel = strjoin (vs.sel, "\n");
      REG["\""] = sel;
      seltoX (sel);
      break;
      }

    if ('d' == chr)
      {
      variable len = length (vs.sel);
      if (1 < len)
        return;
      
      sel = strjoin (vs.sel, "\n");
      REG["\""] = sel;
      seltoX (sel);

      variable line = s.lines[vs.startlnr];
      line = strreplace (line, sel, "");
      ifnot (strlen (line))
        line = __get_null_str (s._indent);

      s.lines[vs.startlnr] = line;
      s.lins[s.ptr[0] - s.rows[0]] = line;

      variable index = vs.startindex;

      if (index > strlen (line))
        ifnot (strlen (line))
          index = s._indent;
        else
          index -= strlen (sel);

      if (index > strlen (line))
        index = strlen (line);

      s._index = index;
      s.ptr[0] = vs.ptr[0];
      s.ptr[1] = index;

      s.st_.st_size = getsizear (s.lines);

      set_modified (s);

      waddline (s, getlinestr (s, s.lines[vs.startlnr], 1), 0, s.ptr[0]);

      draw_tail (s);
      return;
      }
    }

  s.ptr[0] = vs.ptr[0];
  s.ptr[1] = vs.startindex;
  vs.needsdraw = 1;
}

vis.c_mode = &v_char_mode;

private define v_bw_calclines (vs)
{
  variable i;
  _for i (0, length (vs.lines) - 1)
    vs.sel[i] = substr (vs.lines[i], vs.startcol + 1, vs.index[i] - vs.startcol + 1);
}

private define v_bw_calclines_up (s, vs, un, inc)
{
  v_calclines_up (s, vs, un, inc);

  vs.index =  vs.index[[:-2]];
  vs.sel = vs.sel[[:-2]];
  vs.col  = vs.col[[:-2]];
}

private define v_bw_calclines_up_ (s, vs, incr)
{
  v_calclines_up_ (s, vs, incr);
  vs.index = [vs.index[0], vs.index];
  vs.sel = [substr (vs.lines[0], vs.index[0] + 1, 1), vs.sel];
  vs.col  = [vs.col[0], vs.col];
  vs.bw_maxlen = int (min (vs.linlen[where (vs.linlen)]));
}

private define v_bw_up (vs, s)
{
  ifnot (v_lnr (s, '.'))
    return;
  
  if (s.ptr[0] == s.vlins[0])
    {
    s._i--;
    s.draw ();
    
    if (vs.lnrs[-1] <= vs.startlnr)
      v_bw_calclines_up_ (s, vs, 1);
    else
      v_bw_calclines_up (s, vs, 0, 1);

    v_bw_calclines (vs);   
    v_hl_ch (vs, s);
    return;
    }

  s.ptr[0]--;

  if (vs.lnrs[-1] > vs.startrow)
    v_bw_calclines_up (s, vs, 1, 0);
  else
    v_bw_calclines_up_ (s, vs, 0);

  v_bw_calclines (vs);   
  v_hl_ch (vs, s);
}

vis.bw_up = &v_bw_up;

private define v_bw_calclines_down (s, vs, un, dec)
{
  v_calclines_down (s, vs, un, dec);
  vs.index =  vs.index[[1:]];
  vs.sel = vs.sel[[1:]];
  vs.col  = vs.col[[1:]];
}

private define v_bw_calclines_down_ (s, vs, dec)
{
  v_calclines_down_ (s, vs, dec);
  vs.index = [vs.index, vs.index[-1]];
  vs.sel = [vs.sel, substr (vs.lines[-1], vs.index[-1] + 1, 1)];
  vs.col  = [vs.col, vs.col[-1]];
}

private define v_bw_down (vs, s)
{
  if (v_lnr (s, '.') == s._len)
      return;

  if (s.ptr[0] == s.vlins[-1])
    {
    s._i++;
    s.draw ();
    
    if (vs.lnrs[0] < vs.startlnr)
      v_bw_calclines_down (s, vs, 0, 1);
    else
      v_bw_calclines_down_ (s, vs, 1);

    v_bw_calclines (vs);   
    v_hl_ch (vs, s);
    return;
    }    

  s.ptr[0]++;

  if (vs.lnrs[0] < vs.startlnr)
    v_bw_calclines_down (s, vs, 1, 0);
  else
    v_bw_calclines_down_ (s, vs, 0);

  v_bw_calclines (vs);   
  v_hl_ch (vs, s);
}

vis.bw_down = &v_bw_down;

private define v_bw_left (vs, s)
{
  if (s.ptr[1] == vs.startcol)
    return;

  vs.index--;
  s.ptr[1]--;
  s._index--;
  
  v_bw_calclines (vs);  
  v_hl_ch (vs, s);
}

vis.bw_left = &v_bw_left;

private define v_bw_right (vs, s)
{
  variable linlen = v_linlen (s, '.');

  if (s._index - s._indent == linlen - 1 || 0 == linlen
      || s._index + 1 > vs.bw_maxlen)
    return;
  
  if (s.ptr[1] < s._maxlen - 1)
    s.ptr[1]++;
  else
    {
    % still there is no care for wrapped lines (possible blockwise is unsuable
    % and bit of sensless for wrapped lines): very low priority
    %s._findex++;
    %s._is_wrapped_line = 1;
    }

  s._index++;
  vs.index++;
 
  v_bw_calclines (vs);
  v_hl_ch (vs, s);
}

vis.bw_right = &v_bw_right;
 
private define v_bw_mode (vs, s)
{
  variable
    i,
    lnr,
    sel,
    chr,
    len,
    line;

  vs.linlen = [strlen (vs.lines[0])];

  vs.bw_maxlen = vs.linlen[0];
  vs.startcol = vs.col[0];
  vs.startindex = vs.index;
  vs.index = [vs.index];

  vs.sel = [substr (vs.lines[0], vs.index[0] + 1, 1)];

  v_hl_ch (vs, s);

  while (chr = getch (), any (vs.bw_keys == chr))
    {
    if (keys->UP == chr)
      {
      vs.bw_up (s);
      continue;
      }

    if (keys->DOWN == chr)
      {
      vs.bw_down (s);
      continue;
      }

    if (keys->RIGHT == chr)
      {
      vs.bw_right (s);
      continue;
      }

    if (keys->LEFT == chr)
      {
      vs.bw_left (s);
      continue;
      }

    if ('d' == chr)
      {
      sel = strjoin (vs.sel, "\n");
      REG["\""] = sel;
      seltoX (sel);
      _for i (0, length (vs.lnrs) - 1)
        {
        lnr = vs.lnrs[i];
        line = s.lines[lnr];
 
        if (0 == strlen (line) || (1 == strlen (line) && ' ' == line[0]))
          continue;
        
        if (vs.startcol)
          line = sprintf ("%s%s", substr (line, 1, vs.startcol), vs.index[i] == strlen (line)
            ? "" : substr (line, vs.startcol + 1 + strlen (vs.sel[i]), -1));
        else
          line = sprintf ("%s", vs.index[i] == strlen (line)
            ? "" : substr (line, strlen (vs.sel[1]) + 1, -1));

        s.lines[lnr] = line;
        }

      set_modified (s);
      break;
      }
    
    if ('y' == chr)
      {
      sel = strjoin (vs.sel, "\n");
      REG["\""] = sel;
      seltoX (sel);
      break;
      }
    
    if ('I' == chr)
      {
      variable t = rline->__gettxt ("", vs.vlins[0] - 1, vs.startcol)._lin;
      _for i (0, length (vs.lnrs) - 1)
        {
        lnr = vs.lnrs[i];
        line = s.lines[lnr];
        len = strlen (line);
 
        if (0 == len && vs.startcol)
          continue;
        
        if (vs.startcol)
          line = sprintf ("%s%s%s%s",
            substr (line, 1, vs.startcol),
            len < vs.startcol ? repeat (" ", vs.startcol - len) : "",
            t,
            substr (line, vs.startcol + 1, -1));
        else
          line = sprintf ("%s%s", t, strlen (line) == 1 && line[0] == ' '
            ? "" : substr (line, 1, -1));

        s.lines[lnr] = line;
        }

      set_modified (s);
      break;
      }
    }

  vs.needsdraw = 1;
}

vis.bw_mode = &v_bw_mode;

private define v_atexit (vs, s, draw)
{
  topline ("-- pager --");
 
  if (draw)
    {
    s._i = vs._i;
    s.ptr[1] = vs.ptr[1];
    s.ptr[0] = vs.ptr[0];
    s._index = vs.startindex;
 
    s.draw ();
    }
}

vis.at_exit = &v_atexit;

private define v_init (s)
{
  toplinedr ("-- visual --");
  variable lnr = v_lnr (s, '.');
  variable v = @vis;
  
  v._i = @s._ii;
  v.ptr = @s.ptr;
  v.needsdraw = 0;
  v.startlnr = lnr;
  v.vlins = [s.ptr[0]];
  v.lnrs = [lnr];
  v.linlen = [v_linlen (s, '.')];
  v.lines = [v_lin (s, '.')];
  v.startrow = lnr;
  v.startindex = s._index;
  
  return struct
    {
    wrappedmot = 0,
    findex = s._findex,
    index = s._index,
    col = [s.ptr[1]],
    @v,
    };
}

private define vis_mode (s)
{
  variable
    vs = v_init (s);

  if (s._chr == 'v')
    vs.c_mode (s);
  else if (s._chr == keys->CTRL_v)
    vs.bw_mode (s);
  else
    vs.l_mode (s);

  vs.at_exit (s, vs.needsdraw);
}

VED_PAGER[string ('v')] = &vis_mode;
VED_PAGER[string ('V')] = &vis_mode;
VED_PAGER[string (keys->CTRL_v)] = &vis_mode; 

%%% INSERT MODE
  
private define newline_str (s, indent, line)
{
  s.autoindent (indent, line);
  return repeat (" ", @indent);
}

private variable lang = input->getlang ();

define insert ();

private define ins_tab (is, s, line)
{
  @line = substr (@line, 1, s._index) + repeat (" ", s._shiftwidth) +
    substr (@line, s._index + 1, - 1);

  s._index += s._shiftwidth;

  is.modified = 1;

  if (strlen (@line) < s._maxlen && s.ptr[1] + s._shiftwidth < s._maxlen)
    {
    s.ptr[1] += s._shiftwidth;
    waddline (s, getlinestr (s, @line, 1), 0, s.ptr[0]);
    draw_tail (s;chr = decode (substr (@line, s._index + 1, 1))[0]);
    return;
    }

  s._is_wrapped_line = 1;

  variable i = 0;
  if (s.ptr[1] < s._maxlen)
    while (s.ptr[1]++, i++, (s.ptr[1] < s._maxlen && i < s._shiftwidth));
  else
    i = 0;
 
  s._findex += (s._shiftwidth - i);

  variable
    lline = getlinestr (s, @line, s._findex + 1 - s._indent);

  waddline (s, lline, 0, s.ptr[0]);
  draw_tail (s;chr = decode (substr (@line, s._index + 1, 1))[0]);
}

insfuncs.ins_tab = &ins_tab;

private define ins_char (is, s, line)
{
  @line = substr (@line, 1, s._index) + char (is.chr) + substr (@line, s._index + 1, - 1);

  s._index++;

  is.modified = 1;

  if (strlen (@line) < s._maxlen && s.ptr[1] < s._maxlen)
    {
    s.ptr[1]++;
    waddline (s, getlinestr (s, @line, 1), 0, s.ptr[0]);
    draw_tail (s;chr = decode (substr (@line, s._index + 1, 1))[0]);
    return;
    }
 
  s._is_wrapped_line = 1;
 
  if (s.ptr[1] == s._maxlen)
    s._findex++;

  variable
    lline = getlinestr (s, @line, s._findex + 1 - s._indent);

  if (s.ptr[1] < s._maxlen)
    s.ptr[1]++;

  waddline (s, lline, 0, s.ptr[0]);
  draw_tail (s;chr = decode (substr (@line, s._index + 1, 1))[0]);
}

insfuncs.ins_char = &ins_char;

private define ins_del_prev (is, s, line)
{
  variable
    lline,
    len;

  ifnot (s._index - s._indent)
    {
    ifnot (is.lnr)
      return;

   if (s.ptr[0] != s.rows[0])
     s.ptr[0]--;
   else
     s._ii--;

    is.lnr--;

    s._index = strlen (s.lines[is.lnr]);
    s.ptr[1] = s._index > s._maxlen ? s._maxlen : s._index;

    if (is.lnr == s._len)
      @line = s.lines[is.lnr];
    else
      @line = s.lines[is.lnr] + @line;
 
    s.lines[is.lnr] = @line;
    s.lines[is.lnr + 1] = NULL;
    s.lines = s.lines[wherenot (_isnull (s.lines))];
    s._len--;

    s._i = s._ii;

    s.draw (;dont_draw);

    len = strlen (@line);
    if (len > s._maxlen)
      {
      s._findex = len - s._maxlen;
      s.ptr[1] = s._maxlen - (len - s._index);
      s._is_wrapped_line = 1;
      }
    else
      s._findex = s._indent;

    lline = getlinestr (s, @line, s._findex + 1 - s._indent);

    waddline (s, lline, 0, s.ptr[0]);
    draw_tail (s;chr = decode (substr (@line, s._index + 1, 1))[0]);
    is.modified = 1;
    return;
    }

  @line = substr (@line, 1, s._index - 1) + substr (@line, s._index + 1, - 1);

  len = strlen (@line);
 
  s._index--;

  ifnot (s.ptr[1])
    {
    if (s._index > s._maxlen)
      {
      s.ptr[1] = s._maxlen;
      s._findex = len - s._linlen;
      lline = substr (@line, s._findex + 1, -1);
      waddline (s, lline, 0, s.ptr[0]);
      draw_tail (s;chr = decode (substr (@line, s._index, 1))[0]);
      return;
      }

    s._findex = s._indent;
    s.ptr[1] = len;
    waddline (s, @line, 0, s.ptr[0]);
    draw_tail (s;chr = decode (substr (@line, s._index, 1))[0]);
    s._is_wrapped_line = 0;
    return;
    }

  s.ptr[1]--;

  if (s._index == len)
    waddlineat (s, " ", 0, s.ptr[0], s.ptr[1], s._maxlen);
  else
    {
    lline = substr (@line, s._index + 1, -1);
    waddlineat (s, lline, 0, s.ptr[0], s.ptr[1], s._maxlen);
    }
 
  draw_tail (s;chr = decode (substr (@line, s._index + 1, 1))[0]);

  is.modified = 1;
}

insfuncs.del_prev = &ins_del_prev;

private define ins_del_next (is, s, line)
{
  ifnot (s._index - s._indent)
    if (1 == strlen (@line))
      if (" " == @line)
        {
        if (is.lnr < s._len)
          {
          @line += s.lines[is.lnr + 1];
          s.lines[is.lnr + 1 ] = NULL;
          s.lines = s.lines[wherenot (_isnull (s.lines))];
          s._len--;
          s._i = s._ii;
          s.draw (;dont_draw);
          is.modified = 1;
          waddline (s, getlinestr (s, @line, 1), 0, s.ptr[0]);
          draw_tail (s;chr = decode (substr (@line, s._index + 1, 1))[0]);
          }

        return;
        }
      else
        {
        @line = " ";
        waddline (s, @line, 0, s.ptr[0]);
        draw_tail (s;chr = decode (substr (@line, s._index + 1, 1))[0]);
        is.modified = 1;
        return;
        }

  if (s._index == strlen (@line))
    {
    if (is.lnr < s._len)
      {
      @line += getlinestr (s, s.lines[is.lnr + 1], 1);
      s.lines[is.lnr + 1 ] = NULL;
      s.lines = s.lines[wherenot (_isnull (s.lines))];
      s._len--;
      s._i = s._ii;
      s.draw (;dont_draw);
      is.modified = 1;
      if (s._is_wrapped_line)
        waddline (s, getlinestr (s, @line, s._findex + 1 - s._indent), 0, s.ptr[0]);
      else
        waddline (s, getlinestr (s, @line, 1), 0, s.ptr[0]);

      draw_tail (s;chr = decode (substr (@line, s._index + 1, 1))[0]);
      }

    return;
    }

  @line = substr (@line, 1, s._index) + substr (@line, s._index + 2, - 1);

  if (s._is_wrapped_line)
    waddline (s, getlinestr (s, @line, s._findex + 1 - s._indent), 0, s.ptr[0]);
  else
    waddline (s, getlinestr (s, @line, 1), 0, s.ptr[0]);
 
  draw_tail (s;chr = decode (substr (@line, s._index + 1, 1))[0]);
  is.modified = 1;
}

insfuncs.del_next = &ins_del_next;

private define ins_eol (is, s, line)
{
  variable
    lline,
    len = strlen (@line);
 
  s._index = len;

  if (len > s._linlen)
    {
    s._findex = len - s._linlen;
    lline = getlinestr (s, @line, s._findex + 1 - s._indent);
 
    waddline (s, lline, 0, s.ptr[0]);

    s.ptr[1] = s._maxlen;
    s._is_wrapped_line = 1;
    }
  else
    s.ptr[1] = len;

  draw_tail (s;chr = decode (substr (@line, s._index + 1, 1))[0]);
}

insfuncs.eol = &ins_eol;

private define ins_bol (is, s, line)
{
  s._findex = s._indent;
  s._index = s._indent;
  s.ptr[1] = s._indent;
  waddline (s, getlinestr (s, @line, 1), 0, s.ptr[0]);
  draw_tail (s;chr = decode (substr (@line, s._index + 1, 1))[0]);
  s._is_wrapped_line = 0;
}

insfuncs.bol = &ins_bol;

private define ins_completeline (is, s, line, comp_line)
{
  if (s._is_wrapped_line)
    return;

  if (s._index < strlen (comp_line) - s._indent)
    {
    @line = substr (@line, 1, s._index + s._indent) +
      substr (comp_line, s._index + 1 + s._indent, 1) +
      substr (@line, s._index + 1 + s._indent, -1);

    s._index++;

    if (s.ptr[1] + 1 < s._maxlen)
      s.ptr[1]++;

    waddline (s, getlinestr (s, @line, 1), 0, s.ptr[0]);
    draw_tail (s;chr = decode (substr (@line, s._index + 1, 1))[0]);
    is.modified = 1;
    }
}

insfuncs.completeline = &ins_completeline;

private define ins_right (is, s, line)
{
  variable len = strlen (@line);

  if (s._index + 1 > len || 0 == len)
    return;

  s._index++;
 
  ifnot (s.ptr[1] == s._maxlen)
    s.ptr[1]++;
 
  if (s._index + 1 > s._maxlen)
    {
    s._findex++;
    s._is_wrapped_line = 1;
    }
 
  variable lline;

  if (s.ptr[1] + 1 > s._maxlen)
    {
    lline = getlinestr (s, @line, s._findex - s._indent);
    waddline (s, lline, 0, s.ptr[0]);
    }

  draw_tail (s;chr = decode (substr (@line, s._index + 1, 1))[0]);
}

insfuncs.right = &ins_right;

private define ins_left (is, s, line)
{
  if (0 < s.ptr[1] - s._indent)
    {
    s._index--;
    s.ptr[1]--;
    draw_tail (s;chr = decode (substr (@line, s._index + 1, 1))[0]);
    }
  else
    if (s._is_wrapped_line)
      {
      s._index--;
      variable lline;
      lline = getlinestr (s, @line, s._index - s._indent);

      waddline (s, lline, 0, s.ptr[0]);
 
      draw_tail (s;chr = decode (substr (@line, s._index, 1))[0]);

      if (s._index - 1 == s._indent)
        s._is_wrapped_line = 0;
      }
}

insfuncs.left = &ins_left;

private define ins_page_up (is, s, line)
{
  s.lins[s.ptr[0] - s.rows[0]] = @line;
  s.lines[is.lnr] = @line;
  s._findex = s._indent;
  
  (@VED_PAGER[string (keys->PPAGE)]) (s;modified);
  is.lnr = v_lnr (s, '.');
  @line = v_lin (s, '.'); 
  
  ifnot (is.lnr)
    is.prev_l = "";
  else
    is.prev_l = s.lines[is.lnr - 1];
 
  is.next_l = s.lines[is.lnr + 1];
}

insfuncs.pag_up = &ins_page_up;
  
private define ins_page_down (is, s, line)
{
  s.lins[s.ptr[0] - s.rows[0]] = @line;
  s.lines[is.lnr] = @line;
  s._findex = s._indent;
  
  (@VED_PAGER[string (keys->NPAGE)]) (s;modified);
  is.lnr = v_lnr (s, '.');
  @line = v_lin (s, '.'); 
  
  if (is.lnr == s._len)
    is.next_l = "";
  else
    is.next_l = s.lines[is.lnr + 1];
 
  is.prev_l = s.lines[is.lnr - 1];
}

insfuncs.pag_down = &ins_page_down;

private define ins_down (is, s, line)
{
  if (is.lnr == s._len)
    return;

  s.lins[s.ptr[0] - s.rows[0]] = @line;
  s.lines[is.lnr] = @line;
 
  s._findex = s._indent;

  is.lnr++;

  is.prev_l = @line;
  if (is.lnr + 1 > s._len)
    is.next_l = "";
  else
    is.next_l = s.lines[is.lnr + 1];

  if (s._is_wrapped_line)
    {
    waddline (s, getlinestr (s, @line, 1), 0, s.ptr[0]);
    s._is_wrapped_line = 0;
    s.ptr[1] = s._maxlen;
    }

  s._index = s.ptr[1];

  @line = s.lines[is.lnr];

  variable len = strlen (@line);
 
  if (s._index > len)
    {
    s.ptr[1] = len ? len : s._indent;
    s._index = len ? len : s._indent;
    }
 
  if (s.ptr[0] < s.vlins[-1])
    {
    s.ptr[0]++;
    draw_tail (s;chr = strlen (@line)
      ? s._index > s._indent
        ? decode (substr (@line, s._index + 1, 1))[0]
        : decode (substr (@line, s._indent + 1, 1))[0]
      : ' ');

    return;
    }

  if (s.lnrs[-1] == s._len)
    return;

  ifnot (s.ptr[0] == s.vlins[-1])
    s.ptr[0]++;

  s._i++;

  variable chr = strlen (@line)
    ? s._index > s._indent
      ? decode (substr (@line, s._index + 1, 1))[0]
      : decode (substr (@line, s._indent + 1, 1))[0]
    : ' ';

  s.draw (;chr = chr);
}

insfuncs.down = &ins_down;

private define ins_up (is, s, line)
{
  variable i = v_lnr (s, '.');

  ifnot (is.lnr)
    return;

  s.lins[s.ptr[0] - s.rows[0]] = @line;
  s.lines[is.lnr] = @line;

  is.lnr--;

  is.next_l = @line;

  if (-1 == is.lnr - 1)
    is.prev_l = "";
  else
    is.prev_l = s.lines[is.lnr - 1];

  s._findex = s._indent;

  if (s._is_wrapped_line)
    {
    waddline (s, getlinestr (s, @line, s._indent + 1 - s._indent), 0, s.ptr[0]);
    s._is_wrapped_line = 0;
    s.ptr[1] = s._maxlen;
    }
 
  s._index = s.ptr[1];
 
  @line = s.lines[is.lnr];
 
  variable len = strlen (@line);

  if (s._index > len)
    {
    s.ptr[1] = len ? len : s._indent;
    s._index = len ? len : s._indent;
    }
 
  if (s.ptr[0] > s.vlins[0])
    {
    s.ptr[0]--;
    draw_tail (s;chr = strlen (@line)
      ? s._index > s._indent
        ? decode (substr (@line, s._index + 1, 1))[0]
        : decode (substr (@line, s._indent + 1, 1))[0]
      : ' ');
    return;
    }
 
  s._i = s._ii - 1;
 
  variable chr = strlen (@line)
    ? s._index > s._indent
      ? decode (substr (@line, s._index + 1, 1))[0]
      : decode (substr (@line, s._indent + 1, 1))[0]
    : ' ';

  s.draw (;chr = chr);
}

insfuncs.up = &ins_up;

private define ins_cr (is, s, line)
{
  variable
    prev_l,
    next_l,
    lline;

  if (strlen (@line) == s._index)
    {
    s.lines[is.lnr] = @line;
    s.lins[s.ptr[0] - s.rows[0]] = @line;

    lang = input->getlang ();

    s._chr = 'o';
 
    (@VED_PAGER[string ('o')]) (s;modified);

    return;
    }
  else
    {
    lline = 0 == s._index - s._indent ? " " : substr (@line, 1, s._index);
    variable indent = 0;
    @line =  newline_str (s, &indent, @line) + substr (@line, s._index + 1, -1);

    prev_l = lline;

    if (is.lnr + 1 >= s._len)
      next_l = "";
    else
      if (s.ptr[0] == s.rows[-2])
        next_l = s.lines[is.lnr + 1];
      else
        next_l = v_lin (s, s.ptr[0] + 1);

    s.ptr[1] = indent;
    s._i = s._ii;

    if (s.ptr[0] == s.rows[-2] && s.ptr[0] + 1 > s._avlins)
      s._i++;
    else
      s.ptr[0]++;

    ifnot (is.lnr)
      s.lines = [lline, @line, s.lines[[is.lnr + 1:]]];
    else
      s.lines = [s.lines[[:is.lnr - 1]], lline, @line, s.lines[[is.lnr + 1:]]];

    s._len++;
 
    s.draw (;dont_draw);
 
    waddline (s, @line, 0, s.ptr[0]);
    draw_tail (s;chr = decode (substr (@line, s._index + 1, 1))[0]);

    s._index = indent;
    s._findex = s._indent;

    lang = input->getlang ();

    insert (s, line, is.lnr + 1, prev_l, next_l;modified, dont_draw_tail);
    }
}

insfuncs.cr = &ins_cr;

private define ins_esc (is, s, line)
{
  if (0 < s.ptr[1] - s._indent)
    s.ptr[1]--;

  if (0 < s._index - s._indent)
    s._index--;
 
  if (is.modified)
    {
    s.lins[s.ptr[0] - s.rows[0]] = @line;
    s.lines[is.lnr] = @line;

    set_modified (s);
 
    s.st_.st_size = getsizear (s.lines);
    }
 
  topline (" -- pager --");
  draw_tail (s);
}

insfuncs.esc = &ins_esc;

define ctrl_completion_rout (s, line, type)
{
  variable
    ar,
    chr,
    start,
    item,
    rows = Integer_Type[0],
    indexchanged = 0,
    index = 1,
    origlen = strlen (@line),
    col = s._index - 1,
    iwchars = [MAPS, ['0':'9'], '_'];

  if (any (["ins_linecompletion", "blockcompletion"] == type))
    {
    item = @line;
    if ("blockcompletion" == type)
      {
      item = strtrim_beg (item);
      variable block_ar = qualifier ("block_ar");
      if (NULL == block_ar || 0 == length (block_ar)
        || (strlen (item) && 0 == length (wherenot (strncmp (
            block_ar, item, strlen (item))))))
        return;
      }
    }
  else if ("ins_wordcompletion" == type)
    {
    item = fpart_of_word (s, @line, col, &start);

    ifnot (strlen (item))
      return;
    }

  forever
    {
    ifnot (indexchanged)
      if ("ins_linecompletion" == type)
        ar = pcre->find_unique_lines_in_lines (s.lines, item, NULL;ign_lead_ws);
      else if ("ins_wordcompletion" == type)
        ar = pcre->find_unique_words_in_lines (s.lines, item, NULL);
      else if ("blockcompletion" == type)
        ifnot (strlen (item))
          ar = block_ar;
        else
          ar = block_ar[wherenot (strncmp (block_ar, item, strlen (item)))];

    ifnot (length (ar))
      {
      if (length (rows))
        smg->restore (rows, s.ptr, 1);
      
      waddline (s, getlinestr (s, @line, 1), 0, s.ptr[0]);
      smg->setrcdr (s.ptr[0], s.ptr[1]);
      return;
      }

    indexchanged = 0;

    if (index > length (ar))
      index = length (ar);

    rows = widg->pop_up (ar, s.ptr[0], s.ptr[1] + 1, index);

    smg->setrcdr (s.ptr[0], s.ptr[1]);

    chr = getch ();

    if (any (keys->rmap.backspace == chr))
      {
      if (1 == strlen (item))
        {
        smg->restore (rows, s.ptr, 1);
        return;
        }
      else
        item = substr (item, 1, strlen (item) - 1);
 
      smg->restore (rows, NULL, NULL);
      continue;
      }

    if (any ([' ', '\r'] == chr))
      {
      smg->restore (rows, NULL, NULL);
      
      if ("ins_linecompletion" == type)
        @line = ar[index - 1] + substr (@line, s._index + 1, -1);
      else if ("ins_wordcompletion" == type)
        @line = substr (@line, 1, start) + ar[index - 1] + substr (@line, s._index + 1, -1);
      else if ("blockcompletion" == type)
        {
        @line = ar[index - 1];
        return;
        }

      waddline (s, getlinestr (s, @line, 1), 0, s.ptr[0]);
 
      variable len = strlen (@line);

      %bug here (if len > maxlen) (wrapped line)
      if (len < origlen)
        s._index -= (origlen - len);
      else if (len > origlen)
        s._index += len - origlen;

      s.ptr[1] = s._index;

      draw_tail (s;chr = decode (substr (@line, s._index + 1, 1))[0]);
 
      return;
      }

    if (any ([keys->CTRL_n, keys->DOWN] == chr))
      {
      index++;
      if (index > length (ar))
        index = 1;

      indexchanged = 1;
      }

    if (any ([keys->CTRL_p, keys->UP] == chr))
      {
      index--;
      ifnot (index)
        index = length (ar);

      indexchanged = 1;
      }

    ifnot (any ([iwchars, keys->CTRL_n, keys->DOWN, keys->CTRL_p, keys->UP] == chr))
      {
      smg->restore (rows, s.ptr, 1);
      smg->refresh ();
      return;
      }
    else if (any ([iwchars] == chr))
      item += char (chr);
 
    ifnot (indexchanged)
      smg->restore (rows, NULL, NULL);
 
   % BUG HERE
    if (indexchanged)
      if (index > 1)
        if (index > LINES - 4)
          ar = ar[[1:]];
    % when ar has been changed and index = 1
    }
}

define ins_linecompletion (s, line)
{
  ifnot (strlen (@line))
    return;

  ctrl_completion_rout (s, line, _function_name ());
}

define blockcompletion (lnr, s, line)
{
 variable f = __get_reference (s._type + "_blocks");
  
  if (NULL == f)
    return;
  
  variable assoc = (@f) (s._shiftwidth, s.ptr[1]);
  variable keys = assoc_get_keys (assoc);
  variable item = @line;

  ctrl_completion_rout (s, line, _function_name ();block_ar = keys);
 
  variable i = wherefirst (@line == keys);  
  if (NULL == i)
    waddline (s, getlinestr (s, @line, 1), 0, s.ptr[0]);
  else
    {
    variable ar = strchop (assoc[@line], '\n', 0);
    % broken _for loop code,
    % trying to calc the indent
    % when there is an initial string to narrow the results, might need
    % a different approach
    %_for i (0, length (ar) - 1)
    %  (ar[i], ) = strreplace (ar[i], " ", "", strlen (item) - 1);

    @line = ar[0];
    if (1 == length (ar))
      waddline (s, getlinestr (s, @line, 1), 0, s.ptr[0]);
    
    s.lines[lnr] = @line;
    s.lines = [s.lines[[:lnr]], 1 == length (ar) ? String_Type[0] : ar[[1:]],
      lnr == s._len ? String_Type[0] :  s.lines[[lnr+1:]]];
    s._len = length (s.lines) - 1;
    s.st_.st_size = getsizear (s.lines);
  
    set_modified (s);
  
    s._i = s._ii;
    s.draw ();
    }
}
 
define pag_completion (s)
{
  variable chr = getch ();
  variable line;
  
  switch (chr)
  
    {
    case 'b':
      line = v_lin (s, '.');
      blockcompletion (v_lnr (s, '.'), s, &line);
    }
 
    {
    return;
    }
}
 
VED_PAGER[string (033)] = &pag_completion;
 
define ins_ctrl_x_completion (is, s, line)
{
  variable chr = getch ();
  
  switch (chr)
  
    {
    case keys->CTRL_l:
      ins_linecompletion (s, line);
    }
    
    {
    case 'b':
      blockcompletion (is.lnr, s, line);
    }
 
    {
    return;
    }
}

define ins_wordcompletion (s, line)
{
  ctrl_completion_rout (s, line, _function_name ());
}

private define ins_getline (is, s, line)
{
  is = struct {@insfuncs, @is};
 
  forever
    {
    is.chr = getch (;on_lang = &_on_lang_change_, on_lang_args = {"insert", s.ptr});

    if (033 == is.chr)
      {
      is.esc (s, line);
      return;
      }
    
    if (0x1001a == is.chr) % Double Escape
      {
      s.lins[s.ptr[0] - s.rows[0]] = @line;
      s.lines[is.lnr] = @line;
      s.st_.st_size = getsizear (s.lines);
      __writefile (s, NULL, s.ptr, NULL);
      s._flags &= ~VED_MODIFIED;
      send_msg_dr (s._absfname + " written", 0, s.ptr[0], s.ptr[1]);
      sleep (0.02);
      send_msg_dr ("", 0, s.ptr[0], s.ptr[1]);
      continue;
      }
  
    if ('\r' == is.chr)
      {
      is.cr (s, line);
      return;
      }
 
    if (keys->CTRL_n == is.chr)
      {
      ins_wordcompletion (s, line);
      continue;
      }

    if (keys->CTRL_x == is.chr)
      {
      ins_ctrl_x_completion (is, s, line);
      continue;
      }

    if (keys->UP == is.chr)
      {
      is.up (s, line);
      continue;
      }
 
    if (keys->DOWN == is.chr)
      {
      is.down (s, line);
      continue;
      }

    if (keys->NPAGE == is.chr)
      {
      is.pag_down (s, line);
      continue;
      }

    if (keys->PPAGE == is.chr)
      {
      is.pag_up (s, line);
      continue;
      }

    if (any (keys->rmap.left == is.chr))
      {
      is.left (s, line);
      continue;
      }
 
    if (any (keys->rmap.right == is.chr))
      {
      is.right (s, line);
      continue;
      }

    if (any (keys->CTRL_y == is.chr))
      {
      ifnot (strlen (is.prev_l))
        continue;

      is.completeline (s, line, is.prev_l);
      continue;
      }

    if (any (keys->CTRL_e == is.chr))
      {
      ifnot (strlen (is.next_l))
        continue;

      is.completeline (s, line, is.next_l);
      continue;
      }

    if (any (keys->rmap.home == is.chr))
      {
      is.bol (s, line);
      continue;
      }

    if (any (keys->rmap.end == is.chr))
      {
      is.eol (s, line);
      continue;
      }

    if (any (keys->rmap.backspace == is.chr))
      {
      is.del_prev (s, line);
      continue;
      }

    if (any (keys->rmap.delete == is.chr))
      {
      is.del_next (s, line);
      continue;
      }
 
    if ('\t' == is.chr)
      {
      is.ins_tab (s, line);
      continue;
      }

    if (' ' <= is.chr <= 126 || 902 <= is.chr <= 974)
      {
      is.ins_char (s, line);
      continue;
      }
    }
}

define insert (s, line, lnr, prev_l, next_l)
{
  input->setlang (lang);

  topline (" -- insert --");

  variable self = @Insert_Type;

  self.lnr = lnr;
  self.modified = qualifier_exists ("modified");
  self.prev_l = prev_l;
  self.next_l = next_l;

  ifnot (qualifier_exists ("dont_draw_tail"))
    draw_tail (s);

  ins_getline (self, s, line);

  lang = input->getlang ();

  input->setlang (input->get_en_lang ());
}
%%% END INSERT MODE

%%%% ED MODE

private define ed_indent_in (s)
{
  variable
    i_ = s._indent,
    i = v_lnr (s, '.'),
    line = v_lin (s, '.');
 
  line = _indent_in_ (s, line, &i_);
  
  if (NULL == line)
    return;

  s.lins[s.ptr[0] - s.rows[0]] = line;
  s.lines[i] = line;
  s.ptr[1] -= i_;
  s._index -= i_;

  if (0 > s.ptr[1] - s._indent)
    s.ptr[1] = s._indent;

  if (0 > s._index - s._indent)
    s._index = s._indent;

  set_modified (s);

  s.st_.st_size += s._shiftwidth;

  waddline (s, line, 0, s.ptr[0]);
 
  draw_tail (s);
}

private define ed_indent_out (s)
{
  variable
    i = v_lnr (s, '.'),
    line = v_lin (s, '.');

  line = sprintf ("%s%s", repeat (" ", s._shiftwidth), line);

  s.lins[s.ptr[0] - s.rows[0]] = line;
  s.lines[i] = line;
  s.ptr[1] += s._shiftwidth;
  s._index += s._shiftwidth;

  if (s.ptr[1] >= s._maxlen)
    s.ptr[1] = s._maxlen - 1;

  set_modified (s);

  s.st_.st_size += s._shiftwidth;

  waddline (s, line, 0, s.ptr[0]);

  draw_tail (s);
}

private define ed_join_line (s)
{
  variable
    i = v_lnr (s, '.'),
    line = v_lin (s, '.');

  if (0 == s._len || i == s._len)
    return;

  s.lines[i] = line + " " + s.lines[i + 1];
  s.lines[i + 1] = NULL;
  s.lines = s.lines[wherenot (_isnull (s.lines))];
  s._len--;
 
  s._i = s._ii;
 
  set_modified (s);

  s.draw ();
}

private define ed_del_line (s)
{
  variable
    i = v_lnr (s, '.'),
    line = v_lin (s, '.');

  if (0 == s._len && (0 == v_linlen (s, '.') || " " == line ||
      line == __get_null_str (s._indent)))
    return 1;

  ifnot (i)
    ifnot (s._len)
      {
      s.lines[0] = __get_null_str (s._indent);
      s.st_.st_size = 0;
      s.ptr[1] = s._indent;
      s._index = s._indent;
      s._findex = s._indent;
      set_modified (s);
      return 0;
      }

  REG["\""] = s.lines[i] + "\n";

  s.lines[i] = NULL;
  s.lines = s.lines[wherenot (_isnull (s.lines))];
  s._len--;
 
  s._i = s._ii;
 
  s.ptr[1] = s._indent;
  s._index = s._indent;
  s._findex = s._indent;

  if (s.ptr[0] == s.vlins[-1] && 1 < length (s.vlins))
    s.ptr[0]--;

  s.st_.st_size -= strbytelen (line);

  if (s._i > s._len)
    s._i = s._len;
 
  set_modified (s;_i = s._i);
  
  return 0;
}

private define ed_del_word (s, what)
{
  variable
    end,
    word,
    start,
    func = islower (what) ? &find_word : &find_Word,
    col = s._index,
    i = v_lnr (s, '.'),
    line = v_lin (s, '.');
 
  if (isblank (substr (line, col + 1, 1)))
    return;
 
  word = (@func) (s, line, col, &start, &end);
 
  REG["\""] = word;

  line = sprintf ("%s%s", substr (line, 1, start), substr (line, end + 2, -1));
 
  s.lins[s.ptr[0] - s.rows[0]] = line;
  s.lines[i] = line;
  s.ptr[1] = start;
  s._index = start;

  set_modified (s);
 
  s.st_.st_size = getsizear (s.lines);

  waddline (s, getlinestr (s, line, 1), 0, s.ptr[0]);

  draw_tail (s);
}

private define ed_chang_chr (s)
{
  variable
    chr = getch (),
    col = s._index,
    i = v_lnr (s, '.'),
    line = v_lin (s, '.');

  if (' ' <= chr <= 126 || 902 <= chr <= 974)
    {
    s.st_.st_size -= strbytelen (line);
    line = substr (line, 1, col) + char (chr) + substr (line, col + 2, - 1);
    s.lins[s.ptr[0] - s.rows[0]] = line;
    s.lines[i] = line;
    s.st_.st_size += strbytelen (line);
    set_modified (s);
    waddline (s, getlinestr (s, line, 1), 0, s.ptr[0]);
    draw_tail (s);
    }
}

private define ed_del_chr (s)
{
  variable
    col = s._index,
    i = v_lnr (s, '.'),
    line = v_lin (s, '.'),
    len = strlen (line);

  if ((0 == s.ptr[1] - s._indent && 'X' == s._chr) || 0 > len - s._indent)
    return;
 
  if (any (['x', keys->rmap.delete] == s._chr))
    {
    REG["\""] = substr (line, col + 1, 1);
    line = substr (line, 1, col) + substr (line, col + 2, - 1);
    if (s._index == strlen (line))
      {
      s.ptr[1]--;
      s._index--;
      }
    }
  else
    if (0 < s.ptr[1] - s._indent)
      {
      REG["\""] = substr (line, col, 1);
      line = substr (line, 1, col - 1) + substr (line, col + 1, - 1);
      s.ptr[1]--;
      s._index--;
      }
 
  ifnot (strlen (line))
    line = __get_null_str (s._indent);
 
  if (s.ptr[1] - s._indent < 0)
    s.ptr[1] = s._indent;

  if (s._index - s._indent < 0)
    s._index = s._indent;

  s.lins[s.ptr[0] - s.rows[0]] = line;
  s.lines[i] = line;

  s.st_.st_size = getsizear (s.lines);
 
  set_modified (s);
 
  waddline (s, getlinestr (s, line, 1), 0, s.ptr[0]);
 
  draw_tail (s);
}

private define ed_change_word (s, what)
{
  variable
    end,
    word,
    start,
    lline,
    prev_l,
    next_l,
    func = islower (what) ? &find_word : &find_Word,
    col = s._index,
    lnr = v_lnr (s, '.'),
    line = v_lin (s, '.');
 
  if (isblank (substr (line, col + 1, 1)))
    return;
 
  word = (@func) (s, line, col, &start, &end);
 
  REG["\""] = word;

  line = sprintf ("%s%s", substr (line, 1, start), substr (line, end + 2, -1));
 
  ifnot (lnr)
    prev_l = "";
  else
    prev_l = v_lin (s, s.ptr[0] - 1);

  if (lnr == s._len)
    next_l = "";
  else
    next_l = s.lines[lnr + 1];
 
  if (s._index - s._indent > s._maxlen)
    lline = getlinestr (s, line, s._findex + 1);
  else
    lline = getlinestr (s, line, 1);
 
  if (strlen (lline))
    {
    waddline (s, lline, 0, s.ptr[0]);
    smg->refresh ();
    }
 
  s.ptr[1] = start;
  s._index = start;

  insert (s, &line, lnr, prev_l, next_l;modified);
}

private define ed_change (s)
{
  variable chr = getch ();
 
  if (any (['w', 'W'] == chr))
    {
    if ('w' == chr)
      {
      ed_change_word (s, 'w');
      return;
      }

    if ('W' == chr)
      {
      ed_change_word (s, 'W');
      return;
      }
    }
}

private define ed_del (s)
{
  variable chr = getch ();
 
  if (any (['d', 'w', 'W'] == chr))
    {
    if ('d' == chr)
      {
      if (1 == ed_del_line (s))
        return;

      s.draw ();
      return;
      }
 
    if ('w' == chr)
      {
      ed_del_word (s, 'w');
      return;
      }

    if ('W' == chr)
      {
      ed_del_word (s, 'W');
      return;
      }
 
    }
}

private define ed_del_to_end (s)
{
  variable
    col = s._index,
    i = v_lnr (s, '.'),
    line = v_lin (s, '.'),
    len = strlen (line);
 
  if (s._index == len)
    return;
 
  ifnot (s.ptr[1] - s._indent)
    {
    if (strlen (line))
      REG["\""] = line;

    line = __get_null_str (s._indent);
 
    s.ptr[1] = s._indent;
    s._index = s._indent;

    s.lines[i] = line;
    s.lins[s.ptr[0] - s.rows[0]] = line;
 
    set_modified (s);

    s.st_.st_size = getsizear (s.lines);

    waddline (s, getlinestr (s, line, 1), 0, s.ptr[0]);

    draw_tail (s);

    return;
    }
 
  variable reg = substr (line, col, -1);
  if (strlen (line))
    REG["\""] = reg;

  line = substr (line, 1, col);

  s.lins[s.ptr[0] - s.rows[0]] = line;
  s.lines[i] = line;
 
  s.st_.st_size = getsizear (s.lines);

  s.ptr[1]--;
  s._index--;

  set_modified (s);

  waddline (s, getlinestr (s, line, 1), 0, s.ptr[0]);

  draw_tail (s);
}

private define ed_editline (s)
{
  variable
    prev_l,
    next_l,
    lline,
    lnr = v_lnr (s, '.'),
    line = v_lin (s, '.'),
    len = strlen (line);

  ifnot (lnr)
    prev_l = "";
  else
    prev_l = v_lin (s, s.ptr[0] - 1);

  if (lnr == s._len)
    next_l = "";
  else
    next_l = s.lines[lnr + 1];
 
  if ('C' == s._chr)
    line = substr (line, 1, s._index);
  else if ('a' == s._chr && len)
    {
    s._index++;
    s.ptr[1]++;
    }
  else if ('A' == s._chr)
    {
    s._index = len;
    s.ptr[1] = len;
    }
 
  if (s._index - s._indent > s._maxlen)
    lline = getlinestr (s, line, s._findex + 1);
  else
    lline = getlinestr (s, line, 1);
 
  if (strlen (lline))
    {
    waddline (s, lline, 0, s.ptr[0]);
    smg->refresh ();
    }

  if ('C' == s._chr)
    insert (s, &line, lnr, prev_l, next_l;modified);
  else
    insert (s, &line, lnr, prev_l, next_l);
}

private define ed_newline (s)
{
  variable
    dir = s._chr == 'O' ? "prev" : "next",
    prev_l,
    next_l,
    indent,
    col = s._index,
    lnr = v_lnr (s, '.'),
    line = v_lin (s, '.'),
    len = strlen (line);

  if ("prev" == dir)
    ifnot (lnr)
      prev_l = "";
    else
      prev_l = v_lin (s, s.ptr[0] - 1);
  else
    prev_l = line;
 
  if ("prev" == dir)
    next_l = line;
  else
    if (lnr == s._len)
      next_l = "";
    else
      next_l = s.lines[lnr+1];
 
  s._len++;

  if (0 == lnr && "prev" == dir)
    s.lines = [newline_str (s, &indent, line), s.lines];
  else
    s.lines = [s.lines[[:"next" == dir ? lnr : lnr - 1]],
      newline_str (s, &indent, line),
      s.lines[["next" == dir ? lnr + 1 : lnr:]]];
 
  s.st_.st_size = getsizear (s.lines);
 
  s._i = lnr == 0 ? 0 : s._ii;
 
  if ("next" == dir)
    if (s.ptr[0] == s.rows[-2] && s.ptr[0] + 1 > s._avlins)
      s._i++;
    else
      s.ptr[0]++;
  
  s.ptr[1] = indent;
  s._index = indent;
  s._findex = s._indent;
 
  s.draw (;dont_draw);
 
  line = newline_str (s, &indent, line);
  insert (s, &line, "next" == dir ? lnr + 1 : lnr, prev_l, next_l;;__qualifiers ());
}

private define ed_Put (s)
{
  ifnot (assoc_key_exists (REG, "\""))
    return;

  variable
    lines = strchop (REG["\""], '\n', 0),
    lnr = v_lnr (s, '.');

  if ('\n' == REG["\""][-1])
    {
    lines = lines[[:-2]];
    ifnot (lnr)
      s.lines = [lines, s.lines];
    else
      s.lines = [s.lines[[:lnr - 1]], lines, s.lines[[lnr:]]];

    s._len += length (lines);
    }
  else
    s.lines[lnr] = substr (s.lines[lnr], 1, s._index) + strjoin (lines) +
      substr (s.lines[lnr], s._index + 1, -1);

  s._i = lnr == 0 ? 0 : s._ii;
 
  s.st_.st_size = getsizear (s.lines);
 
  set_modified (s);
 
  s.draw ();
}

private define ed_put (s)
{
  ifnot (assoc_key_exists (REG, "\""))
    return;

  variable
    lines = strchop (REG["\""], '\n', 0),
    lnr = v_lnr (s, '.');

  if ('\n' == REG["\""][-1])
    {
    lines = lines[[:-2]];
    s.lines = [s.lines[[:lnr]], lines, s.lines[[lnr + 1:]]];
    s._len += length (lines);
    }
  else
    s.lines[lnr] = substr (s.lines[lnr], 1, s._index + 1) + strjoin (lines) +
      substr (s.lines[lnr], s._index + 2, -1);

  s._i = lnr == 0 ? 0 : s._ii;
 
  s.st_.st_size = getsizear (s.lines);
 
  set_modified (s);
 
  s.draw ();
}

private define ed_toggle_case (s)
{
  variable
    func,
    col = s._index,
    i = v_lnr (s, '.'),
    line = v_lin (s, '.'),
    chr = substr (line, col + 1, 1);

  chr = decode (chr)[0];

  func = islower (chr) ? &toupper : &tolower;

  chr = char ((@func) (chr));
 
  s.st_.st_size -= strbytelen (line);
  line = substr (line, 1, col) + chr + substr (line, col + 2, - 1);
  s.lins[s.ptr[0] - s.rows[0]] = line;
  s.lines[i] = line;
  s.st_.st_size += strbytelen (line);
  set_modified (s);
 
  waddline (s, getlinestr (s, line, 1), 0, s.ptr[0]);

  if (s._index - s._indent == v_linlen (s, s.ptr[0]) - 1)
    draw_tail (s);
  else
    (@VED_PAGER[string ('l')]) (s);
}

%private define record ()
%{
%  if (RECORD)
%    {
%    RECORD = 0;
%    return;
%    }
%
%  variable chr = getch ();
%
%  ifnot ('a' < chr > 'z')
%    return;
%
%  RECORD = 1;
%  CRECORD = char (chr);
%  RECORDS[CRECORD] = {};
%}

private define _askonsubst_ (s, fn, lnr, fpart, context, lpart, replace)
{
  variable cmp_lnrs = Integer_Type[0];
  variable ar = 
    ["@" + fn + " linenr: " + string (lnr+1),
     "replace?",
     repeat ("_", COLUMNS),
     sprintf ("%s%s%s", fpart, context, lpart),
     repeat ("_", COLUMNS),
     "with?",
     repeat ("_", COLUMNS),
     sprintf ("%s%s%s", fpart, replace, lpart),
     repeat ("_", COLUMNS),
     "y[es replace]",
     "n[o  dont replace]",
     "q[uit all the replacements]",
     "a[ll replace all, dont ask again for this file]"];
   variable char_ar =  ['y', 'n', 'q', 'a'];
   return widg->askprintstr (ar, char_ar, &cmp_lnrs);
}
                                                                                         
define __substitute ()
{
  variable global = 0, ask = 1, pat = NULL, sub = NULL, ind;
  variable args = __pop_list (_NARGS);
  variable buf = get_cur_buf ();
 
  args = list_to_array (args, String_Type);
  
  ind = is_arg ("--global", args);
  ifnot (NULL == ind)
    global = 1;
  
  ind = is_arg ("--dont-ask-when-subst", args);
  ifnot (NULL == ind)
    ask = 0;
  
  ind = is_arg ("--pat=", args);
  ifnot (NULL == ind)
    pat = substr (args[ind], strlen ("--pat=") + 1, -1);
  
  ind = is_arg ("--sub=", args);
  ifnot (NULL == ind)
    sub = substr (args[ind], strlen ("--pat=") + 1, -1);

  if (NULL == pat || NULL == sub)
    {
    send_msg_dr ("--pat= and --sub= are required", 1, buf.ptr[0], buf.ptr[1]);
    return;
    }
 
  variable s = search->init (pat, sub;global = global, askwhensubst = ask);
  s.fname = path_basename (buf._absfname);
  s.ask = &_askonsubst_;
  variable retval = search->search_and_replace (s, buf.lines);
  ifnot (retval)
    {
    buf.lines = ();
    buf.draw ();
    }
}

VED_PAGER[string ('~')] = &ed_toggle_case;
VED_PAGER[string ('P')] = &ed_Put;
VED_PAGER[string ('p')] = &ed_put;
VED_PAGER[string ('o')] = &ed_newline;
VED_PAGER[string ('O')] = &ed_newline;
VED_PAGER[string ('c')] = &ed_change;
VED_PAGER[string ('d')] = &ed_del;
VED_PAGER[string ('D')] = &ed_del_to_end;
VED_PAGER[string ('C')] = &ed_editline;
VED_PAGER[string ('i')] = &ed_editline;
VED_PAGER[string ('a')] = &ed_editline;
VED_PAGER[string ('A')] = &ed_editline;
VED_PAGER[string ('r')] = &ed_chang_chr;
VED_PAGER[string ('J')] = &ed_join_line;
VED_PAGER[string ('>')] = &ed_indent_out;
VED_PAGER[string ('<')] = &ed_indent_in;
VED_PAGER[string ('x')] = &ed_del_chr;
VED_PAGER[string ('X')] = &ed_del_chr;
VED_PAGER[string (keys->rmap.delete[0])]    = &ed_del_chr;
VED_PAGER[string (keys->rmap.backspace[0])] = &ed_del_chr;
VED_PAGER[string (keys->rmap.backspace[1])] = &ed_del_chr;
VED_PAGER[string (keys->rmap.backspace[2])] = &ed_del_chr;
 
ifnot (NULL == DISPLAY)
  ifnot (NULL == XAUTHORITY)
    ifnot (NULL == XCLIP_BIN)
      loadfrom ("X", "seltoX", NULL, &on_eval_err);

new_wind ();
