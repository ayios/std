public variable VEDDIR = STDDIR + "/app/ved/functions";

set_slang_load_path (sprintf ("%s%c%s",
  get_slang_load_path ( ),
  path_get_delimiter (),
  VEDDIR + "/share"));

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
  quit,
  vedloop,
  vedloopcallback,
  ved,
  draw,
  mainloop,
  lexicalhl,
  autoindent,
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
  } Mark_Type;

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

public variable
  FTYPES = Assoc_Type[Integer_Type],
  VED_MODIFIED = 0x01,
  VED_ONDISKMODIFIED = 0x02,
  VED_RDONLY = 0x04,
  VED_ROWS = [1:LINES - 3],
  VED_INFOCLRFG = COLOR.infofg,
  VED_INFOCLRBG = COLOR.infobg,
  VED_PROMPTCLR = COLOR.prompt,
  XCLIP_BIN = which ("xclip");

public variable
  VED_WIND = Assoc_Type[Wind_Type],
  VED_CUR_WIND = NULL,
  VED_PREV_WIND,
  VED_MAXFRAMES = 3;

public variable
  VED_ISONLYPAGER = 0,
  VED_RLINE = 1,
  VED_INITDONE = 0;

public variable UNDELETABLE = String_Type[0];

public variable EL_MAP = [[913:929:1], [931:937:1], [945:969:1]];
public variable EN_MAP = [['a':'z'], ['A':'Z']];
public variable MAPS = [EL_MAP, EN_MAP];
public variable WCHARS = array_map (String_Type, &char, [['0':'9'], EN_MAP, EL_MAP, '_']);

private define _invalid ()
{
  pop ();
}

public variable
  VED_PAGER = Assoc_Type[Ref_Type, &_invalid],
  VEDCOUNT = 0,
  RECORD = 0,
  CRECORD,
  MARKS = Assoc_Type[Mark_Type],
  RECORDS = Assoc_Type[List_Type],
  REG = Assoc_Type[String_Type];

MARKS[string ('`')] = @Mark_Type;

FTYPES["sl"] = 0;
FTYPES["txt"] = 0;
FTYPES["list"] = 0;
FTYPES["ashell"] = 0;

define set_modified ();
define writetofile ();
define seltoX ();

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
    {
    set_slang_load_path (sprintf ("%s/%s%c%s", VEDDIR, ftype,
      path_get_delimiter (), get_slang_load_path ()));
    FTYPES[ftype] = 1;
    }

  variable type = @Ftype_Type;

  loadfile (ftype + "_functions", NULL, &on_eval_err);

  type._type = ftype;
  return type;
}

define getlines (fname, indent, st)
{
  indent = repeat (" ", indent);
  if (-1 == access (fname, F_OK) || 0 == st.st_size)
    {
    st.st_size = 0;
    return [sprintf ("%s\000", indent)];
    }

  return array_map (String_Type, &sprintf, "%s%s", indent, readfile (fname));
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

define set_clr_fg (b, set)
{
  b.clrs[-1] = VED_INFOCLRFG;
  SMGIMG[b.rows[-1]][1] = VED_INFOCLRFG;
  if (set)
    smg->hlregion (VED_INFOCLRFG, b.rows[-1], 0, 1, COLUMNS);
}

define set_clr_bg (b, set)
{
  b.clrs[-1] = VED_INFOCLRBG;
  SMGIMG[b.rows[-1]][1] = VED_INFOCLRBG;
  if (set)
    smg->hlregion (VED_INFOCLRBG, b.rows[-1], 0, 1, COLUMNS);
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

define get_cur_buf ()
{
  variable w = _NARGS ? () : get_cur_wind ();
  ifnot (length (w.buffers))
    return NULL;
  
  variable n = w.frame_names[w.cur_frame];
  ifnot (any (n == w.bufnames))
    return NULL;

  return w.buffers[w.frame_names[w.cur_frame]];
}

define get_frame_buf (frame)
{
  variable w = get_cur_wind ();
  if (frame >= w.frames)
    return NULL;

  return w.buffers[w.frame_names[frame]];
}

define get_cur_frame ()
{
  return VED_WIND[VED_CUR_WIND].cur_frame;
}

define get_cur_rline ()
{
  return VED_WIND[VED_CUR_WIND].rline;
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

define change_frame ()
{
  variable w = VED_WIND[VED_CUR_WIND];
  variable b = w.frame_names[w.cur_frame];
  variable s = w.buffers[b];

  set_clr_bg (s, 1);

  w.cur_frame = w.cur_frame == w.frames - 1 ? 0 : w.cur_frame + 1;

  s = get_cur_buf ();

  set_clr_fg (s, 1);
  
  (@__get_reference ("setbuf")) (s._absfname);

  smg->setrcdr (s.ptr[0], s.ptr[1]);
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
  
 (@__get_reference ("setbuf")) (s._absfname);

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

new_wind ();
