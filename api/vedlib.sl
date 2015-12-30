typedef struct
  {
  _i,
  _ii,
  _len,
  _chr,
  _type,
  _fname,
  _abspath,
  _fd,
  _flags,
  _maxlen,
  _indent,
  _linlen,
  _avlins,
  _findex,
  _index,
  _shiftwidth,
  _expandtab,
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
  _index,
  _findex,
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

private variable vis = struct
  {
  _i,
  cur,
  ptr,
  mode,
  clr = COLOR.visual,
  l_mode,
  l_down,
  l_up,
  l_page_up,
  l_page_down,
  l_keys = ['w', 's', 'y', 'Y', 'd', '>', '<', keys->DOWN, keys->UP, keys->PPAGE, keys->NPAGE],
  c_mode,
  c_left,
  c_right,
  c_keys = ['y', 'd', keys->DOWN, keys->RIGHT, keys->UP, keys->LEFT],
  bw_mode,
  bw_down,
  bw_up,
  bw_left,
  bw_right,
  bw_keys = ['x', 'I', 'i', 'd', 'y', 'r', 'c', keys->DOWN, keys->UP, keys->RIGHT, keys->LEFT],
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

public variable
  POS = Pos_Type[10],
  FTYPES = Assoc_Type[Integer_Type],
  MARKS = Assoc_Type[Pos_Type],
  REG = Assoc_Type[String_Type];

public variable
  EL_MAP = [902, [904:906], 908, [910:929], [931:937], [945:974]],
  EN_MAP = [['a':'z'], ['A':'Z']],
  MAPS = [EL_MAP, EN_MAP],
  WCHARS = array_map (String_Type, &char, [['0':'9'], EN_MAP, EL_MAP, '_']),
  DEFINED_UPPER_CASE = ['+', ',', '}', ')', ':'],
  DEFINED_LOWER_CASE = ['-', '.', '{', '(', ';'];

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
public variable XCLIP_BIN = Sys.which ("xclip");
public variable VED_DIR = Dir.vget ("TEMPDIR") + "/ved_" + string (Env.vget ("PID")) + "_" +
  string (_time)[[5:]];

public variable
  s_histfile = Dir.vget ("HISTDIR") + "/" + string (getuid ()) + "ved_search_history",
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
  VEDCOUNT;

private define build_ftype_table ()
{
  variable i;
  variable ii;
  variable ft;
  variable nss = [Dir.vget ("LCLDIR"), Dir.vget ("STDDIR"), Dir.vget ("USRDIR")];

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

if (-1 == mkdir (VED_DIR, File.vget ("PERM")["PRIVATE"]))
  __err_handler__ (1;msg = VED_DIR + ": cannot make directory, " + errno_string (errno));

__.sadd ("String", "decode", "decode", NULL;trace = 0);
__.sadd ("String", "append", "append__", NULL);
__.sadd ("String", "write", "write__", NULL);

__.sadd ("Array", "shift", "shift", NULL;trace = 0);
__.sadd ("Array", "istype", "istype__", NULL);
__.sadd ("Array", "getsize", "getsize", NULL;trace = 0);

__.sadd ("Re", "unique_lines", "unique_lines___", NULL);
__.sadd ("Re", "unique_words", "unique_words___", NULL);

__.new ("Ved";methods = "storePos,restorePos",
  funcs = ["storePos__", "restorePos__"],
  refs = [NULL, NULL]);

__.new ("Subst";methods = "new,exec,new_lines,assign,askonsubst",
   funcs = ["__new__", "exec__", "new_lines__", "assign_", "askonsubst_______"],
   refs = [NULL, NULL, NULL, NULL, NULL]);

__.new ("File";methods = "are_same,isreg",
  funcs = ["are_same__", "isreg_"],
  refs = [NULL, NULL]);

__.new ("Diff";methods = "new,patch,files",
  funcs = ["__new__", "patch_", "__files__"],
  refs = [NULL, NULL, NULL]);

__.new ("Vundo";methods = "undo,set,redo",
  funcs = ["__undo_", "__redo_", "__set___"],
  refs = [NULL, NULL, NULL],
  vars = ["rec", "level", "redo"], values = {Struct_Type[5], 0, NULL},
  varself = "rec,level,redo");

Vundo.__rec = Struct_Type[3];
Vundo.__rec[0] = struct {pos = @Pos_Type, data, inds, deleted, blwise};
Vundo.__rec[1] = struct {pos = @Pos_Type, data, inds, deleted, blwise};
Vundo.__rec[2] = struct {pos = @Pos_Type, data, inds, deleted, blwise};

define getXsel (){return "";}
define seltoX (sel){}
define set_modified ();
define topline ();
define toplinedr ();
define __eval ();
define insert ();

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

  load.from ("ftypes/" + ftype, ftype + "_functions", NULL;err_handler = &__err_handler__);

  type._type = ftype;
  return type;
}

define __get_null_str (indent)
{
  return sprintf ("%s\000", repeat (" ", indent));
}

define __vgetlines (fname, indent, st)
{
  if (-1 == access (fname, F_OK))
    {
    st.st_size = 0;
    return [__get_null_str (indent)];
    }

  if (-1 == access (fname, R_OK))
    {
    send_msg (fname + ": is not readable", 1);
    st.st_size = 0;
    return [__get_null_str (indent)];
    }

  if (-1 == access (fname, W_OK))
    {
    send_msg (fname + ": is Read Only", 1);
    st._flags |= VED_RDONLY;
    }

  variable lines = IO.readfile (fname);

  if (NULL == lines || 0 == length (lines))
    {
    lines = [__get_null_str (indent)];
    st.st_size = 0;
    }

  indent = repeat (" ", indent);

  return array_map (String_Type, &sprintf, "%s%s", indent, lines);
}

private define _on_lang_change_ (mode, ptr)
{
  topline (" -- " + mode + " --");
  smg->setrcdr (ptr[0], ptr[1]);
}

define __vwrite_prompt (str, col)
{
  smg->atrcaddnstrdr (str, VED_PROMPTCLR, PROMPTROW, 0,
    qualifier ("row", PROMPTROW), col, COLUMNS);
}

define __vlinlen (s, r)
{
  r = (r == '.' ? s.ptr[0] : r) - s.rows[0];
  return strlen (s.lins[r]) - s._indent;
}

define __vline (s, r)
{
  r = (r == '.' ? s.ptr[0] : r) - s.rows[0];
  return s.lins[r];
}

define __vlnr (s, r)
{
  r = (r == '.' ? s.ptr[0] : r) - s.rows[0];
  return s.lnrs[r];
}

define __vtail (s)
{
  variable
    lnr = __vlnr (s, '.') + 1,
    line = __vline (s, '.');

  return sprintf (
    "[%s] (row:%d col:%d lnr:%d/%d %.0f%% strlen:%d chr:%d) undo %d/%d",
    path_basename (s._fname), s.ptr[0], s.ptr[1] - s._indent + 1, lnr,
    s._len + 1, (100.0 / s._len) * (lnr - 1), __vlinlen (s, '.'),
    qualifier ("chr", String.decode (substr (line, s._index + 1, 1))[0]),
    s._undolevel, length (s.undo));
}

define __vdraw_tail (s)
{
  if (s._is_wrapped_line)
    smg->hlregion (1, s.ptr[0], COLUMNS - 2, 1, 2);

  smg->atrcaddnstrdr (__vtail (s;;__qualifiers ()), VED_INFOCLRFG, s.rows[-1], 0, s.ptr[0], s.ptr[1],
    COLUMNS);
}

define __vgetlinestr (s, line, ind)
{
  return substr (line, ind + s._indent, s._linlen);
}

define __vfpart_of_word (s, line, col, start)
{
  ifnot (strlen (line))
    return "";

  variable origcol = col;

  ifnot (col - s._indent)
    @start = s._indent;
  else
    {
    while (col--, col >= s._indent &&
      any (WCHARS == substr (line, col + 1, 1)));

    @start = col + 1;
    }

  return substr (line, @start + 1, origcol - @start + 1);
}

define __vfind_word (s, line, col, start, end)
{
  if (0 == strlen (line) || ' ' == line[col] ||
      0 == any (WCHARS == char (line[col])))
    return "";

  ifnot (col - s._indent)
    @start = s._indent;
  else
    {
    while (col--, col >= s._indent &&
      any (WCHARS == substr (line, col + 1, 1)));

    @start = col + 1;
    }

  variable len = strlen (line);

  while (col++, col < len && any (WCHARS == substr (line, col + 1, 1)));

  @end = col - 1;

  return substr (line, @start + 1, @end - @start + 1);
}

define __vfind_Word (s, line, col, start, end)
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

define __vparse_arg_range (s, arg, lnrs)
{
  arg = substr (arg, strlen ("--range=") + 1, -1);
  ifnot (strlen (arg))
    return NULL;

  arg = strchop (arg, ',', 0);
  ifnot (2 == length (arg))
    return NULL;

  variable i, ia;
  variable range = ["", ""];
  _for i (0, 1)
    _for ia (0, strlen (arg[i]) - 1)
      ifnot ('0' <= arg[i][ia] <= '9')
        return NULL;
      else
        range[i] += char (arg[i][ia]);

  range = array_map (Integer_Type, &atoi, range); % add an atoi array_map'ed
  if (range[0] > range[1] || 0 > range[0] || range[1] > s._len)
    return NULL;

  return lnrs[[range[0]:range[1]]];
}

define __get_dec (chr, dir)
{
  return any ([['0':'9'], '.'] == chr);
}

define __get_hex (chr, dir)
{
  variable c;
  if ("lhs" == dir)
    c = ['0'];
  else
    c = [['0':'9'], ['a':'f'], ['A':'F'], 'x'];

% why is not working?
% return any ("lhs" == dir ? ['0'] : [['0':'9'], ['a':'f'], ['A':'F']] == chr);
  return any (c == chr);
}

%define string_get_inline_nr_as_str (str)
%{
%}

define __vfind_nr (indent, line, col, start, end, ishex, isoct, isbin)
{
  ifnot (any ([['0':'9'], '-', '.', 'x'] == line[col]))
    return "";

  variable mbishex = 0;
  variable getfunc = [&__get_dec, &__get_hex];

  @ishex = 'x' == line[col];
  getfunc = getfunc[@ishex];

  ifnot (col - indent)
    @start = indent;
  else
    {
    ifnot (line[col] == '-')
      while (col--, col >= indent && (@getfunc) (line[col], "lhs"));

    @start = col + 1;

    if (col)
      if (line[col] == '-')
        @start--;
      else if (line[col] == 'x') % maybe is hex
        mbishex = 1; % when at least one digit found, and 'x' is not the char 
    }                % where the matching stopped. the string under the cursor
                     % can form a valid hex number
  variable len = strlen (line);

  while (col++, col < len && (@getfunc) (line[col], "rhs"));

  @end = col - 1;

  variable nr = substr (line, @start + 1, @end - @start + 1);

  if (nr == "-" || nr == "." || nr[0] == '.' || 0 == strlen (nr))
    return "";

  if (1 == strlen (nr))
    if ('0' == nr[0])
      if (col < len)
        ifnot (@ishex)
          if ('x' == line[col])
            mbishex = 1;

  % hex incr/decr is done when cursor is on an 'x'
  if (mbishex)  % for now and for both conditions and for safety, refuse
    return "";  % to modify the string, if an 'x' is found on the string

  len = strlen (nr);
  col = 0;

  ifnot (len mod 4)
    while (col++, col < len && (@isbin = any (['0','1'] == nr[col]), @isbin));

  col = 0;

  if (1 < len && 0 == @isbin)
    if ('0' == nr[0])
      while (col++, col < len && (@isoct = any (['0':'7'] == nr[col]), @isoct));

  if (nr[-1] == '.')
    if (len > 1)
      {
      nr = substr (nr, 1, len - 1);
      @end--;
      }
    else
      return "";

  if (@ishex || @isoct || @isbin)
    try
      return string (integer (sprintf ("%s%s", @isbin ? "0b" : "", nr)));
    catch SyntaxError:
      return "";

  return nr;
}

private define write_line (fp, line, indent)
{
  line = substr (line, indent + 1, -1);
  return fwrite (line, fp);
}

define __vwritetofile (file, lines, indent, bts)
{
  variable
    i,
    retval,
    fp = fopen (file, NULL == qualifier ("append") ? "w" : "a+");

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

define __vwritefile (s, overwrite, ptr, file, append)
{
  variable bts = 0;

  if (NULL == file)
    {
    if (s._flags & VED_RDONLY)
      return;

    file = s._abspath;
    }
  else
    {
    ifnot (access (file, F_OK))
      {
      ifnot (overwrite)
        if (NULL == append)
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

  variable retval = __vwritetofile (file, qualifier ("lines", s.lines), s._indent, &bts;
  append = append);

  if (retval)
    {
    send_msg_dr (errno_string (retval), 1, ptr[0], ptr[1]);
    return;
    }

  IO.tostderr (s._abspath + ": " + string (bts) + " bytes written\n");

  if (file == s._abspath)
    s._flags &= ~VED_MODIFIED;
}

private define waddlineat (s, line, clr, row, col, len)
{
  smg->atrcaddnstr (line, clr, row, col, len);
  s.lexicalhl ([line], [row]);
}

private define waddline (s, line, clr, row)
{
  smg->atrcaddnstr (line, clr, row, s._indent, s._linlen);
  s.lexicalhl ([line], [row]);
}

private define _set_clr_ (s, clr, set)
{
  s.clrs[-1] = clr;
  smg->IMG[s.rows[-1]][1] = clr;
  if (set)
    smg->hlregion (clr, s.rows[-1], 0, 1, COLUMNS);
}

define __vset_clr_fg (s, set)
{
  _set_clr_ (s, VED_INFOCLRFG, set);
}

define __vset_clr_bg (s, set)
{
  _set_clr_ (s, VED_INFOCLRBG, set);
}

private define _initrowsbuffvars_ (s)
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

define __vsetbuf (key)
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

private define _addbuf_ (s)
{
  ifnot (path_is_absolute (s._fname))
    s._abspath = getcwd () + s._fname;
  else
    s._abspath = s._fname;

  variable w = get_cur_wind ();

  if (any (s._abspath == w.bufnames))
    return;

  w.buffers[s._abspath] = s;
  w.bufnames = [w.bufnames,  s._abspath];
  w.buffers[s._abspath]._dir = realpath (path_dirname (s._abspath));
}

define __vinitbuf (s, fname, rows, lines, t)
{
  s._maxlen = t._maxlen;
  s._indent = t._indent;
  s._shiftwidth = t._shiftwidth;
  s._expandtab = t._expandtab;
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

  s.lines = NULL == lines ? __vgetlines (s._fname, s._indent, s.st_) : lines;
  s._flags = 0;
  s._is_wrapped_line = 0;

  s.ptr = Integer_Type[2];

  s._len = length (s.lines) - 1;

  _initrowsbuffvars_ (s);

  s.ptr[0] = s.rows[0];
  s.ptr[1] = s._indent;

  s._findex = s._indent;
  s._index = s._indent;

  s.undo = String_Type[0];
  s._undolevel = 0;
  s.undoset = {};

  s._i = 0;
  s._ii = 0;

  _addbuf_ (s);
}

define __vdraw_wind ()
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
    __vset_clr_bg (s, NULL);
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
  return get_cur_buf ()._abspath;
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

  __vset_clr_bg (s, 1);

  if ("next" == dir)
    w.cur_frame = w.cur_frame == w.frames - 1 ? 0 : w.cur_frame + 1;
  else
    w.cur_frame = 0 == w.cur_frame ? w.frames - 1 : w.cur_frame - 1;

  s = get_cur_buf ();

  __vset_clr_fg (s, 1);

  __vsetbuf (s._abspath);

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
    _initrowsbuffvars_ (s);

    s._i = s._ii;

    if (i == w.cur_frame)
      __vset_clr_fg (s, NULL);
    else
      __vset_clr_bg (s, NULL);

    s.ptr[0] = s.rows[0];
    s.ptr[1] = s._indent;

    s._findex = s._indent;
    s._index = s._indent;
    }

  __vdraw_wind ();
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

  __vsetbuf (s._abspath);

  % fine tuning maybe is needed
  _for i (0, w.cur_frame - 1)
    {
    s = w.buffers[w.frame_names[i]];
    s.rows = w.frame_rows[i];
    _initrowsbuffvars_ (s);
    s._i = s._ii;
    s.clrs[-1] = VED_INFOCLRBG;
    s.ptr[0] = s.rows[0];
    s.ptr[1] = s._indent;

    s._findex = s._indent;
    s._index = s._indent;
    }

  __vdraw_wind ();
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
    __vdraw_wind ();
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

  __vdraw_wind ();
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
    __vdraw_wind ();
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
    variable retval = __vwritetofile (bufname, s.lines, s._indent, &bts);
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
      __vsetbuf (s._abspath);
      __vdraw_wind ();
      return;
      }

  ifnot (NULL == isatframe)
    if (1 < w.frames)
      del_frame (isatframe);

  if (iscur)
    {
    index = index ? index - 1 : length (w.bufnames) - 1;

    __vsetbuf (w.bufnames[index]);

    s = get_cur_buf ();
    s.draw ();
    }
}

private define _rdregs_ ()
{
  return ['*',  '/', '%', '='];
}

private define _regs_ ()
{
  return [['A':'Z'], ['a':'z'], '*', '"', '/', '%'];
}

private define _get_reg_ (reg)
{
  ifnot (any ([_regs_, '='] == reg[0]))
    return NULL;

  if ("*" == reg)
    return getXsel ();

  if ("%" == reg)
    return get_cur_buf ()._abspath;

  if ("=" == reg)
    {
    variable res = __eval (NULL;return_str);
    ifnot (NULL == res)
      return res;
    else
      return NULL;
    }

  variable k = assoc_get_keys (REG);

  ifnot (any (k == reg))
    return NULL;

  return REG[reg];
}

private define _set_reg_ (reg, sel)
{
  variable k = assoc_get_keys (REG);

  if (any (_regs_ () == reg[0]) || 0 == any (k == reg))
    REG[reg] = sel;
  else
    REG[reg] = REG[reg] + sel;
}

%%% MARK

private define mark_init (m)
{
  ifnot (assoc_key_exists (MARKS, m))
    MARKS[m] = @Pos_Type;
}

array_map (&mark_init, array_map (String_Type, &string, ['`', '<', '>']));

private define mark_set (s, m)
{
  Ved.storePos (s, MARKS[m]);
}

define markbacktick (s)
{
  mark_set (s, string ('`'));
}

private define mark (s)
{
  variable m = getch (;disable_langchange);

  if ('a' <= m <= 'z')
    {
    m = string (m);
    mark_init (m);
    mark_set (s, m);
    }
}

private define mark_get ()
{
  variable marks = assoc_get_keys (MARKS);
  variable mark = getch (;disable_langchange);

  mark = string (mark);

  ifnot (any (mark == marks))
    return NULL;

  variable m = @MARKS[mark];

  if (NULL == m._i)
    return NULL;

  return m;
}

%%% VED OBJECT

define preloop (s)
{
  markbacktick (s);
}

private define _draw_ (s)
{
  if (-1 == s._len) % this shouldn't occur
    {
    send_msg ("_draw_ (), caught -1 == s._len condition" + s._fname, 1);
    s.lins = [__get_null_str (s._indent)];
    s.lnrs = [0];
    s._ii = 0;

    smg->aratrcaddnstrdr ([repeat (" ", COLUMNS), __vtail (s)], [0, VED_INFOCLRFG],
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

  variable indices = [0:length (ar) - 1];
  variable clrs = @s.clrs;
  variable arlen = length (ar);
  variable rowslen = length (s.rows);

  if (arlen < rowslen - 1)
    {
    ifnot (s._type == "ashell")
      clrs[[arlen:length (clrs) -2]] = 5;
    variable t = String_Type[rowslen - arlen - 1];
    t[*] = s._type == "ashell" ? " " : "~";
    ar = [ar, t];
    }

  ar = [ar, __vtail (s;;__qualifiers ())];

  smg->set_img (s.rows, ar, clrs, s.cols);

  smg->aratrcaddnstr (ar, clrs, s.rows, s.cols, COLUMNS);

  s.lexicalhl (ar[indices], s.vlins);

  (@[&smg->setrcdr, &smg->setrc][qualifier_exists ("dont_draw")]) (s.ptr[0], s.ptr[1]);
}

private define _vedloopcallback_ (s)
{
  (@VED_PAGER[string (s._chr)]) (s);
}

private define _loop_ (s)
{
  variable ismsg = 0;
  variable rl;

  forever
    {
    s = get_cur_buf ();
    VEDCOUNT = -1;
    s._chr = getch (;disable_langchange);

    if ('1' <= s._chr <= '9')
      {
      VEDCOUNT = "";

      while ('0' <= s._chr <= '9')
        {
        VEDCOUNT += char (s._chr);
        s._chr = getch (;disable_langchange);
        }

      try
        VEDCOUNT = integer (VEDCOUNT);
      catch SyntaxError:
        {
        ismsg = 1;
        send_msg_dr ("count: too many digits >= " +
          string (256 * 256 * 256 * 128), 1, s.ptr[0], s.ptr[1]);
        continue;
        }
      }

    s.vedloopcallback ();

    if (ismsg)
      {
      send_msg_dr (" ", 0, s.ptr[0], s.ptr[1]);
      ismsg = 0;
      }

    if (':' == s._chr && (VED_RLINE || 0 == VED_ISONLYPAGER))
      {
      topline (" -- command line --");
      rl = get_cur_rline ();
      rline->set (rl);
      rline->readline (rl;
        ved = s, draw = (@__get_reference ("SCRATCH")) == s._abspath ? 0 : 1);

      if ('!' == get_cur_rline ().argv[0][0] &&
         (@__get_reference ("SCRATCH")) == s._abspath)
        {
        (@__get_reference ("draw")) (s);
        continue;
        }

      topline (" -- pager --");
      s = get_cur_buf ();
      smg->setrcdr (s.ptr[0], s.ptr[1]);
      }

    if ('q' == s._chr && VED_ISONLYPAGER)
      return 1;
    }

  return 0;
}

private define _vedloop_ (s)
{
  forever
    try
      if (_loop_ (s))
        break;
    catch AnyError:
      (@__get_reference ("__vmessages"));
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
    line,
    iscomment = 0,
    context;

  _for i (0, length (lines) - 1)
    {
    line = lines[i];
    if (0 == strlen (line) || "\000" == line)
      continue;

    iscomment = '%' == strtrim_beg (line)[0];

    _for ii (0, length (regexps) - 1)
      {
      color = colors[ii];
      regexp = regexps[ii];
      col = 0;

      if (ii && iscomment)
        break;

      while (subs = pcre_exec (regexp, line, col), subs > 1)
        {
        match = pcre_nth_match (regexp, 1);
        col = match[0];
        context = match[1] - col;
        smg->hlregion (color, vlines[i], col, 1, context);
        col += context;
        }

      ifnot (ii)
        if (col)
          line = substr (line, 1, match[0] + 1); % + 1 is to avoid the error pattern
                                                 % to match it as eol
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

private define lexicalhl (s, lines, vlines)
{
}

define deftype ()
{
  variable type = struct
    {
    _indent = 0,
    _shiftwidth = 4,
    _expandtab = NULL,
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

% PAGER

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

private define __define_case (chr)
{
  ifnot (any (@chr == [DEFINED_LOWER_CASE, DEFINED_UPPER_CASE]))
    return 0;

  variable low = 1;
  variable ind = wherefirst_eq (DEFINED_LOWER_CASE, @chr);
  if (NULL == ind)
    {
    ind = wherefirst_eq (DEFINED_UPPER_CASE, @chr);
    low = 0;
    }

  @chr = low ? DEFINED_UPPER_CASE[ind] : DEFINED_LOWER_CASE[ind];

  1;
}

private define _word_change_case_ (s, what)
{
  variable
    ii,
    chr,
    end,
    start,
    word = "",
    func_cond = what == "toupper" ? &islower : &isupper,
    func = what == "toupper" ? &toupper : &tolower,
    col = s._index,
    i = __vlnr (s, '.'),
    line = __vline (s, '.'),
    orig = __vfind_word (s, line, col, &start, &end);

  ifnot (strlen (orig))
    return;

  variable ar = String.decode (orig);
IO.tostderr (ar);
  _for ii (0, length (ar) - 1)
    ifnot (__define_case (&ar[ii]))
      if ((@func_cond) (ar[ii]))
        word += char ((@func) (ar[ii]));
      else
        word += char (ar[ii]);
    else
      word += char (ar[ii]);

  ifnot (orig == word)
    Vundo.set (s, line, i);

  line = sprintf ("%s%s%s", substr (line, 1, start), word, substr (line, end + 2, -1));
  s.lins[s.ptr[0] - s.rows[0]] = line;
  s.lines[i] = line;
  s.ptr[1] = start;
  s._index = start;

  set_modified (s);

  s.st_.st_size = Array.getsize (s.lines);

  waddline (s, line, 0, s.ptr[0]);

  __vdraw_tail (s);
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

private define pg_down (s)
{
  variable
    lnr = __vlnr (s, '.'),
    linlen,
    plinlen;

  if (lnr == s._len)
    return;

  if (s._is_wrapped_line)
    {
    waddline (s, __vgetlinestr (s, __vline (s, '.'), 1), 0, s.ptr[0]);
    s._is_wrapped_line = 0;
    }

  plinlen = __vlinlen (s, '.');

  if (s.ptr[0] < s.vlins[-1])
    {
    s.ptr[0]++;

    linlen = __vlinlen (s, '.');

    _adjust_col_ (s, linlen, plinlen);

    __vdraw_tail (s);

    return;
    }

  if (s.lnrs[-1] == s._len)
    return;

  s._i++;

  ifnot (s.ptr[0] == s.vlins[-1])
    s.ptr[0]++;

  s.draw (;dont_draw);

  linlen = __vlinlen (s, '.');

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
    waddline (s, __vgetlinestr (s, __vline (s, '.'), 1), 0, s.ptr[0]);
    s._is_wrapped_line = 0;
    }

  plinlen = __vlinlen (s, '.');

  if (s.ptr[0] > s.vlins[0])
    {
    s.ptr[0]--;

    linlen = __vlinlen (s, '.');
    _adjust_col_ (s, linlen, plinlen);

    __vdraw_tail (s);

    return;
    }

  ifnot (s.lnrs[0])
    return;

  s._i--;

  s.draw (;dont_draw);

  linlen = __vlinlen (s, '.');

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
      line = __vgetlinestr (s, __vline (s, '.'), s._findex + 1);
    else
      line = __vgetlinestr (s, __vline (s, '.'), 1);

    waddline (s, line, 0, s.ptr[0]);
    }

  __vdraw_tail (s);
}

private define pg_right (s)
{
  variable
    line = __vline (s, '.'),
    retval = __pg_right (s, __vlinlen (s, '.'));

  if (-1 == retval)
    return;

  if (retval)
    {
    line = __vgetlinestr (s, line, s._findex + 1 - s._indent);
    waddline (s, line, 0, s.ptr[0]);
    s._is_wrapped_line = 1;
    }

  __vdraw_tail (s);
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
  ifnot (s.lnrs[0])
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
  variable linlen = __vlinlen (s, '.');

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

  __vdraw_tail (s);
}

private define pg_eol (s)
{
  variable linlen = __vlinlen (s, s.ptr[0]);

  s._index = linlen - 1;

  if (linlen < s._linlen)
    s.ptr[1] = linlen + s._indent - 1;
  else
    {
    s.ptr[1] = s._maxlen - 1;
    s._index += s._indent;

    s._findex = linlen - s._linlen;

    variable line = __vgetlinestr (s, __vline (s, '.'), s._findex + 1);

    waddline (s, line, 0, s.ptr[0]);

    s._is_wrapped_line = 1;
    }

  __vdraw_tail (s);
}

private define pg_bol (s)
{
  s.ptr[1] = s._indent;
  s._findex = s._indent;
  s._index = s._indent;

  if (s._is_wrapped_line)
    {
    variable line = __vgetlinestr (s, __vline (s, '.'), 1);
    waddline (s, line, 0, s.ptr[0]);
    s._is_wrapped_line = 0;
    }

  __vdraw_tail (s);
}

private define pg_bolnblnk (s)
{
  s.ptr[1] = s._indent;

  variable linlen = __vlinlen (s, '.');

  loop (linlen)
    {
    ifnot (isblank (s.lins[s.ptr[0] - s.rows[0]][s.ptr[1]]))
      break;

    s.ptr[1]++;
    }

  s._findex = s._indent;
  s._index = s.ptr[1] - s._indent;

  __vdraw_tail (s);
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

  if ('v' == chr)
    {
    (@__get_reference ("v_lastvi")) (s);
    return;
    }
}

private define pg_Yank (s)
{
  variable
    reg = qualifier ("reg", "\""),
    line = __vline (s, '.');

  _set_reg_ (reg, line + "\n");
  seltoX (line + "\n");
  send_msg_dr ("yanked", 1, s.ptr[0], s.ptr[1]);
}

define __vreread (s)
{
  s.lines = __vgetlines (s._fname, s._indent, s.st_);

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
  new_frame (Dir.vget ("TEMPDIR") + "/" + string (_time) + ".noname");
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
  __vsetbuf (w.frame_names[w.cur_frame]);
}

define on_wind_new (w)
{
  variable fn = Dir.vget ("TEMPDIR") + "/" + string (_time) + ".noname";
  variable s = init_ftype ("txt");
  variable func = __get_reference ("txt_settype");
  (@func) (s, fn, w.frame_rows[0], NULL);

  __vsetbuf (fn);
  (@__get_reference ("__initrline"));
  topline (" -- ved --");
  __vdraw_wind ();
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
  __vwritefile (s, NULL, s.ptr, NULL, NULL);
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
  s._index = m._index;
  s._findex = m._findex;

  s.draw ();

  variable len = __vlinlen (s, '.');
  if (s.ptr[1] > len)
    { % do: catch the if _is_wrapped_line condition
    if (len > s._maxlen)
      s.ptr[1] = s._maxlen; % probably wrong (unless _index changes too
    else
      s.ptr[1] = s._indent + len;

    s._index = s.ptr[1];
    s._findex = s._indent;
    smg->setrcdr (s.ptr[0], s.ptr[1]);
    }
}

private define _set_nr_ (s, incrordecr)
{
  variable
    count = qualifier ("count", 1),
    end,
    start,
    nr,
    col = s._index,
    i = __vlnr (s, '.'),
    line = __vline (s, '.');

  variable ishex = 0;
  variable isoct = 0;
  variable isbin = 0;

  nr = __vfind_nr (s._indent, line, col, &start, &end, &ishex, &isoct, &isbin);
  ifnot (strlen (nr))
    return;

  variable isdbl = _slang_guess_type (nr) == Double_Type;
  variable convf = [&atoi, &atof];
  convf = convf[isdbl];

  if ("+" == incrordecr)
    nr = (@convf) (nr) + count;
  else
    nr = (@convf) (nr) - count;

  variable format = sprintf ("%s%%%s",
    ishex ? "0x0" : isoct ? "0" : "",
    ishex ? "x" : isoct ? "o" : isbin ? "B" : isdbl ? ".3f" : "d");

  nr = sprintf (format, nr);

  if (isbin)
    while (strlen (nr) mod 4)
      nr = "0" + nr;

  line = sprintf ("%s%s%s", substr (line, 1, start), nr, substr (line, end + 2, -1));

  s.lins[s.ptr[0] - s.rows[0]] = line;
  s.lines[i] = line;
  s.ptr[1] = start;
  s._index = start;

  set_modified (s);

  s.st_.st_size = Array.getsize (s.lines);

  waddline (s, line, 0, s.ptr[0]);

  __vdraw_tail (s);
}

private define _incr_nr_ (s)
{
  _set_nr_ (s, "+";count = VEDCOUNT == -1 ? 1 : VEDCOUNT);
}

private define _decr_nr_ (s)
{
  _set_nr_ (s, "-";count = VEDCOUNT == -1 ? 1 : VEDCOUNT);
}

define set_modified (s)
{
  s._flags |= VED_MODIFIED;
}

private define undo (s)
{
  Vundo.undo (s);
}

private define redo (s)
{
  Vundo.redo (s);
}

%%% SEARCH

private variable
  s_col,
  s_fcol,
  s_lnr,
  s_found,
  s_ltype;

private define _init_search_hist_ ()
{
  variable ar = IO.readfile (s_histfile);
  if (NULL != ar && length (ar))
    {
    array_map (&list_append, s_history, ar);
    s_histindex = 0;
    }
}

_init_search_hist_ ();

private define s_exit_rout (s, pat, draw, cur_lang)
{
  ifnot (NULL == cur_lang)
    ifnot (input->getlang () == cur_lang)
      input->setlang (cur_lang);

  if (s_found && pat != NULL)
    {
    list_insert (s_history, pat);
    if (NULL == s_histindex)
      s_histindex = 0;

    _set_reg_ ("/", pat);
    }

  if (draw)
    if (s_found)
      {
      markbacktick (s);
      s_fcol = s_fcol > s._maxlen ? s._indent : s_fcol;

      if (s_lnr < s._avlins)
        {
        s._i = 0;
        s.ptr[0] = s.rows[0] + s_lnr;
        }
      else
        {
        s._i = s_lnr - 2;
        s.ptr[0] = s.rows[0] + 2;
        }

      s.ptr[1] = s_fcol;
      s._index = s_fcol;
      s._findex = s._indent;
      s.draw ();
      }

  smg->setrcdr (s.ptr[0], s.ptr[1]);
  send_msg (" ", 0);
  smg->atrcaddnstr (" ", 0, PROMPTROW, 0, COLUMNS);

  __vdraw_tail (s);
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
    line = __vgetlinestr (s, s.lines[i], 1);
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
    line = __vgetlinestr (s, s.lines[i], 1);
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
    chr,
    origlnr,
    dothesearch = qualifier_exists ("dothesearch"),
    cur_lang = input->getlang (),
    type = qualifier ("type", keys->BSLASH == s._chr ? "forward" : "backward"),
    typesearch = type == "forward" ? &search_forward : &search_backward,
    pchr = type == "forward" ? "/" : "?",
    pat = qualifier ("pat",  ""),
    str = pchr + pat;

  s_found = 0;
  s_lnr = qualifier ("lnr", __vlnr (s, '.'));
  s_ltype = type;
  s_fcol = s.ptr[1];
  s_col = strlen (str);

  if (dothesearch)
    {
    (@typesearch) (s, pat);
    s_exit_rout (s, pat, s_found, cur_lang);
    return;
    }

  origlnr = s_lnr;

  if (length (s_history))
    s_histindex = 0;

  __vwrite_prompt (str, s_col);

  forever
    {
    dothesearch = 0;
    chr = getch (;on_lang = &_on_lang_change_, on_lang_args = {"search", [PROMPTROW, s_col]});

    if (033 == chr)
      {
      s_exit_rout (s, NULL, 0, cur_lang);
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
      s_exit_rout (s, pat, s_found, cur_lang);
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
        __vwrite_prompt (str, s_col);
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
        __vwrite_prompt (str, s_col);
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

    if (chr == keys->CTRL_p)
      {
      typesearch = type == "forward" ? &search_backward : &search_forward;
      if (type == "backward")
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
      typesearch = type == "forward" ? &search_forward : &search_backward;
      }

    str = pchr + pat;
    __vwrite_prompt (str, s_col);

    if (dothesearch)
      (@typesearch) (s, pat);
    }
}

private define s_getlnr (s)
{
  variable lnr = __vlnr (s, '.');

  if (s_ltype == "forward")
    if (lnr == s._len)
      lnr = 0;
    else
      lnr++;
  else
    ifnot (lnr)
      lnr = s._len;
    else
      lnr--;

  return lnr;
}

private define s_backslash_reg_ (s)
{
  variable reg = _get_reg_ ("/");
  if (NULL == reg)
    return;

  if (s._chr == 'N')
    {
    variable ltype = s_ltype;
    s_ltype = (ltype == "forward") ? "backward" : "forward";
    }

  search (s;pat = reg, type = s_ltype, lnr = s_getlnr (s), dothesearch);

  if (s._chr == 'N')
    s_ltype = ltype;
}

private define s_search_word_ (s)
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
    line = __vline (s, '.');

  s_found = 0;
  s_fcol = s.ptr[1];
  s_lnr = __vlnr (s, '.');

  type = '*' == s._chr ? "forward" : "backward";
  s_ltype = type;

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

  pat = __vfind_word (s, line, lcol, &start, &end);

  if (s_col - s._indent)
    pat = "\\W+" + pat;
  else
    pat = "^" + pat;

  if (s._index < __vlinlen (s, '.'))
    pat += "\\W";

  (@typesearch) (s, pat;row = MSGROW, context);

  forever
    {
    ifnot (s_found)
      {
      s_exit_rout (s, NULL, 0, NULL);
      return;
      }

    chr = getch (;disable_langchange);

    ifnot (any ([keys->CTRL_n, 033, '\r'] == chr))
      continue;

    if (033 == chr)
      {
      s_exit_rout (s, NULL, 0, NULL);
      return;
      }

    if ('\r' == chr)
      {
      s_exit_rout (s, pat, s_found, NULL);
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

%%% VISUAL

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
  vs.cur--;
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
  vs.cur--;
  vs.lines = [s.lines[vs.lnrs[0] - 1], vs.lines];
  vs.lnrs = [vs.lnrs[0] - 1, vs.lnrs];

  if (incr)
    vs.vlins++;

  vs.vlins = [qualifier ("row", s.ptr[0]), vs.vlins];
  vs.linlen = [strlen (vs.lines[0]), vs.linlen];
}

private define v_l_up (vs, s)
{
  ifnot (__vlnr (s, '.'))
    return;

  if (s.ptr[0] == s.vlins[0])
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

private define v_l_page_up (vs, s)
{
  if (s._i < s._avlins || s._avlins > s._len)
    return;

  variable count = qualifier ("count", 1);
  variable i = 1;
  variable ii;

  while (i <= count && s._i)
    {
    variable isnotiatfpg = 1;
    ii = s._avlins;

    if (s._i - s._avlins >= 0)
      s._i -= s._avlins;
    else
      {
      ii = s._i + (s.ptr[0] - s.vlins[0]);
      s._i = 0;
      isnotiatfpg = 0;
      }

    loop (ii)
      {
      if (s.ptr[0] == s.vlins[0])
        {
        if (vs.lnrs[-1] <= vs.startlnr)
          v_calclines_up_ (s, vs, 1);
        else
          v_calclines_up (s, vs, 0, 1);
        continue;
        }

      if (vs.lnrs[-1] > vs.startrow)
        v_calclines_up (s, vs, 1, 1);
      else
        v_calclines_up_ (s, vs, 1;row = isnotiatfpg ? s.ptr[0] : vs.vlins[0]);
      }

    i++;
    }

  s.draw ();
  v_hl_line (vs, s);
}

vis.l_page_up = &v_l_page_up;

private define v_calclines_down (s, vs, un, dec)
{
  vs.cur++;
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
  vs.cur++;
  vs.lines = [vs.lines, s.lines[vs.lnrs[-1] + 1]];
  vs.lnrs = [vs.lnrs, vs.lnrs[-1] + 1];

  if (dec)
    vs.vlins--;

  vs.vlins = [vs.vlins, s.ptr[0]];
  vs.linlen = [vs.linlen, strlen (vs.lines[-1])];
}

private define v_l_page_down (vs, s)
{
  if (vs.lnrs[-1] == s._len)
    return;

  variable count = qualifier ("count", 1);
  variable i = 1;
  variable ii;
  variable notend = 1;

  while (i <= count && notend)
    {
    if (s._i + s._avlins < s._len)
      {
      ii = s._avlins - (s.ptr[0] - s.vlins[0]);
      ii = s._avlins;
      s._i += s._avlins;
      }
    else
      break;

    loop (ii)
      {
      if (s.ptr[0] == s.vlins[-1])
        {
        if (vs.lnrs[0] < vs.startlnr)
          v_calclines_down (s, vs, 0, 1);
        else
          v_calclines_down_ (s, vs, 1);

         continue;
         }

      if (vs.lnrs[0] < vs.startlnr)
        v_calclines_down (s, vs, 1, 0);
      else
        v_calclines_down_ (s, vs, 1);
      }

    i++;
    }

  s.draw ();
  v_hl_line (vs, s);
}

vis.l_page_down = &v_l_page_down;

private define v_l_down (vs, s)
{
  if (__vlnr (s, '.') == s._len)
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
  variable chr, i, size = s.st_.st_size, reg = "\"", reginit = 0;

  while (chr = getch (), any ([vs.l_keys, ['0':'9'], '"'] == chr))
    {
    VEDCOUNT = 1;

    if ('0' <= chr <= '9')
      {
      VEDCOUNT = "";

      while ('0' <= chr <= '9')
        {
        VEDCOUNT += char (chr);
        chr = getch ();
        }

      VEDCOUNT = integer (VEDCOUNT);
      }

    if ('"' == chr)
      if (reginit)
        return;
      else
        {
        reg = getch ();
        ifnot (any (_regs_ () == reg))
          return;

        if (any (_rdregs_ == reg))
          return;

        reg = char (reg);
        reginit = 1;
        }

    if (chr == keys->DOWN)
      {
      loop (VEDCOUNT)
        vs.l_down (s);
      continue;
      }

    if (chr == keys->UP)
      {
      loop (VEDCOUNT)
        vs.l_up (s);
      continue;
      }

    if (chr == keys->PPAGE)
      {
      vs.l_page_up (s;count = VEDCOUNT);
      continue;
      }

    if (chr == keys->NPAGE)
      {
      vs.l_page_down (s;count = VEDCOUNT);
      continue;
      }


    if ('y' == chr)
      {
      _set_reg_ (reg, strjoin (vs.lines, "\n") + "\n");
      seltoX (strjoin (vs.lines, "\n") + "\n");
      send_msg ("yanked", 1);
      break;
      }

    if ('>' == chr)
      {
      loop (VEDCOUNT)
        _for i (0, length (vs.lnrs) - 1)
          s.lines[vs.lnrs[i]] = repeat (" ", s._shiftwidth) + s.lines[vs.lnrs[i]];

      s.st_.st_size = Array.getsize (s.lines);
      ifnot (size == s.st_.st_size)
        set_modified (s);
      else
        return;

      break;
      }

    if ('<' == chr)
      {
      loop (VEDCOUNT)
        _for i (0, length (vs.lnrs) - 1)
          {
          variable i_ = s._indent;
          variable l = _indent_in_ (s, s.lines[vs.lnrs[i]], &i_);
          if (NULL == l)
            continue;

          s.lines[vs.lnrs[i]] = l;
          }

      s.st_.st_size = Array.getsize (s.lines);
      ifnot (size == s.st_.st_size)
        set_modified (s);
      else
        return;

      break;
      }

    if ('d' == chr)
      {
      _set_reg_ (reg, strjoin (vs.lines, "\n") + "\n");
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

      s.st_.st_size = Array.getsize (s.lines);
      set_modified (s);
      Vundo.set (s, vs.lines, vs.lnrs;deleted);
      s.draw ();
      send_msg ("deleted", 1);
      return;
      }

    if ('s' == chr)
      {
      variable rl = get_cur_rline ();
      variable argv = ["substitute", "--global",
        sprintf ("--range=%d,%d", vs.lnrs[0], vs.lnrs[-1]), "--pat="];

      rline->set (rl;line = strjoin (argv, " "), argv = argv,
        col = int (sum (strlen (argv))) + length (argv),
        ind = length (argv) - 1);

      rline->readline (rl);
      return;
      }

    if ('w' == chr)
      {
      rl = get_cur_rline ();
      argv = ["w", sprintf ("--range=%d,%d", vs.lnrs[0], vs.lnrs[-1])];

      rline->set (rl;line = strjoin (argv, " "), argv = argv,
        col = int (sum (strlen (argv))) + length (argv),
        ind = length (argv) - 1);

      rline->readline (rl);
      break;
      }
    }

  vs.needsdraw = 1;
}

private define v_linewise_mode (vs, s)
{
  if (1 == length (vs.lines))
    vs.linlen = [strlen (vs.lines[0])];
  else
    vs.linlen = strlen (vs.lines);

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
      lline = __vgetlinestr (s, vs.lines[cur], s._findex + 1 - s._indent);
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
    variable lline = __vgetlinestr (s, vs.lines[cur], s._findex + 1 - s._indent);
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
    reginit = 0,
    reg = "\"",
    cur = 0;

  vs.startcol = [vs.col[0]];
  vs.index = [vs.index];

  vs.sel = [substr (vs.lines[cur], vs.index[cur] + 1, 1)];

  v_hl_ch (vs, s);

  while (chr = getch (), any ([vs.c_keys, '"'] == chr))
    {
    if ('"' == chr)
      if (reginit)
        return;
      else
        {
        reg = getch ();
        ifnot (any (_regs_ () == reg))
          return;

        if (any (_rdregs_ == reg))
          return;

        reg = char (reg);
        reginit = 1;
        }

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
      _set_reg_ (reg, sel);
      seltoX (sel);
      send_msg ("yanked", 1);
      break;
      }

    if ('d' == chr)
      {
      variable len = length (vs.sel);
      if (1 < len)
        return;

      sel = strjoin (vs.sel, "\n");
      _set_reg_ (reg, sel);
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

      s.st_.st_size = Array.getsize (s.lines);

      set_modified (s);

      waddline (s, __vgetlinestr (s, s.lines[vs.startlnr], 1), 0, s.ptr[0]);
      Vundo.set (s, [s.lines[vs.startlnr]], [vs.startlnr]);
      __vdraw_tail (s);
      send_msg ("deleted", 1);
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
  ifnot (__vlnr (s, '.'))
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
  if (__vlnr (s, '.') == s._len)
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
  variable linlen = __vlinlen (s, '.');

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

    if (any (['d', 'x'] == chr))
      {
      sel = strjoin (vs.sel, "\n");
      _set_reg_ ("\"", sel);
      seltoX (sel);
      Vundo.set (s, vs.lines, vs.lnrs;blwise);

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

    if (any (['r', 'c'] == chr))
      {
      sel = strjoin (vs.sel, "\n");
      _set_reg_ ("\"", sel);
      seltoX (sel);
      Vundo.set (s, vs.lines, vs.lnrs;blwise);
      variable txt = rline->__gettxt ("", vs.vlins[0] - 1, vs.startcol)._lin;

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
            txt,
            substr (line, vs.startcol + 1 + strlen (vs.sel[i]), -1));
        else
         line = sprintf ("%s%s", txt, vs.index[i] == strlen (line)
           ? "" : substr (line, strlen (vs.sel[1]) + 1, -1));

        s.lines[lnr] = line;
        }

      set_modified (s);
      break;
      }

    if ('y' == chr)
      {
      sel = strjoin (vs.sel, "\n");
      _set_reg_ ("\"", sel);
      seltoX (sel);
      break;
      }

    if (any (['I', 'i'] == chr))
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

      Vundo.set (s, vs.lines, vs.lnrs;blwise);
      set_modified (s);
      break;
      }
    }

  vs.needsdraw = 1;
}

vis.bw_mode = &v_bw_mode;

private variable LastVi = NULL;

define v_lastvi (s)
{
  variable vs = LastVi;

  if (NULL == vs)
    return;

  ifnot (vs.mode == "lw")
    return;

  if (vs.lnrs[-1] > length (s.lines) - 1)
    return;

  vs.needsdraw = 0;

  s.ptr[0] = vs.ptr[0];
  s.ptr[1] = vs.ptr[1];

  s._i = vs._i;
  s.draw ();
  vs.lines = s.lines[vs.lnrs];

  vs.l_mode (s);

  vs.at_exit (s, vs.needsdraw);
}

private define v_atexit (vs, s, draw)
{
  variable keep;
  if (draw)
    {
    topline ("-- pager --");

    keep = @s.ptr;
    s.ptr[1] = vs.ptr[1];
    s.ptr[0] = vs.ptr[0];
    vs.ptr = keep;
    s._index = vs.startindex;

    keep = @s._i;
    s._i = vs._i;
    vs._i = keep;
    s.draw ();

    variable len = __vlinlen (s, '.');
    variable col = s.ptr[1], row = s.ptr[0];

    if (len < s._index)
      s._index = len - 1;

    if (s.ptr[1] > len)
      s.ptr[1] = len - 1;

    if (row > s._len)
      s.ptr[0] = s._len;

    if (row != s.ptr[0] || col != s.ptr[1])
      __vdraw_tail (s);
    }
  else
    {
    toplinedr ("-- pager --");
    vs.ptr = @s.ptr;
    vs._i = @s._i;
    }

  LastVi = vs;
}

vis.at_exit = &v_atexit;

private define v_init (s)
{
  toplinedr ("-- visual --");
  variable lnr = __vlnr (s, '.');
  variable v = @vis;

  v._i = @s._ii;
  v.ptr = @s.ptr;
  v.needsdraw = 0;
  v.startlnr = lnr;
  v.vlins = [s.ptr[0]];
  v.lnrs = [lnr];
  v.linlen = [__vlinlen (s, '.')];
  v.lines = [__vline (s, '.')];
  v.startrow = lnr;
  v.startindex = s._index;
  v.cur = s._index;
  v.startcol = [s.ptr[0]];

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
    mode = ["bw", "lw", "cw"],
    vs = v_init (s);

  vs.mode = mode[wherefirst ([keys->CTRL_v, 'V', 'v'] == s._chr)];

  if (s._chr == 'v')
    vs.c_mode (s);
  else if (s._chr == keys->CTRL_v)
    vs.bw_mode (s);
  else
    vs.l_mode (s);

  vs.at_exit (s, vs.needsdraw);
}

% ED

private define newline_str (s, indent, line)
{
  s.autoindent (indent, line);
  return repeat (" ", @indent);
}

private define ed_indent_in (s)
{
  variable
    i_ = s._indent,
    i = __vlnr (s, '.'),
    line = __vline (s, '.');

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

  __vdraw_tail (s);
}

private define ed_indent_out (s)
{
  variable
    i = __vlnr (s, '.'),
    line = __vline (s, '.');

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

  __vdraw_tail (s);
}

private define ed_join_line (s)
{
  variable
    i = __vlnr (s, '.'),
    line = __vline (s, '.');

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
    reg = qualifier ("reg", "\""),
    i = __vlnr (s, '.'),
    line = __vline (s, '.');

  if (0 == s._len && (0 == __vlinlen (s, '.') || " " == line ||
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

  _set_reg_ (reg, s.lines[i] + "\n");

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

  Vundo.set (s, strtok (strtrim_end (_get_reg_ (reg)), "\n"), [i];_i = s._i, deleted);

  set_modified (s;_i = s._i);

  return 0;
}

private define ed_del_word (s, what)
{
  variable
    reg = qualifier ("reg", "\""),
    end,
    word,
    start,
    func = islower (what) ? &__vfind_word : &__vfind_Word,
    col = s._index,
    i = __vlnr (s, '.'),
    line = __vline (s, '.');

  if (isblank (substr (line, col + 1, 1)))
    return;

  word = (@func) (s, line, col, &start, &end);

  _set_reg_ (reg, word);

  Vundo.set (s, line, i);

  line = sprintf ("%s%s", substr (line, 1, start), substr (line, end + 2, -1));

  s.lins[s.ptr[0] - s.rows[0]] = line;
  s.lines[i] = line;
  s.ptr[1] = start;
  s._index = start;

  set_modified (s);

  s.st_.st_size = Array.getsize (s.lines);

  waddline (s, __vgetlinestr (s, line, 1), 0, s.ptr[0]);

  __vdraw_tail (s);
}

private define ed_chang_chr (s)
{
  variable
    chr = getch (),
    col = s._index,
    i = __vlnr (s, '.'),
    line = __vline (s, '.');

  if (' ' <= chr <= 126 || 902 <= chr <= 974)
    {
    s.st_.st_size -= strbytelen (line);
    line = substr (line, 1, col) + char (chr) + substr (line, col + 2, - 1);
    s.lins[s.ptr[0] - s.rows[0]] = line;
    s.lines[i] = line;
    s.st_.st_size += strbytelen (line);
    set_modified (s);
    waddline (s, __vgetlinestr (s, line, 1), 0, s.ptr[0]);
    __vdraw_tail (s);
    }
}

private define ed_del_trailws (s)
{
  variable
    col = s._index,
    i = __vlnr (s, '.');

  variable
    line = __vline (s, '.'),
    line_ = strtrim_end (line),
    len_  = strlen (line_),
    len   = strlen (line);

   ifnot (len_)
     (len = 0, line = __get_null_str (s._indent));
   else
     if (len == len_)
       return;
     else
       (len = col < len_ ? col : len_, line = line_);

  s.lines[i] = line;
  s.lins[s.ptr[0] - s.rows[0]] = line;

  s._index = s._indent + len;
  s.ptr[1] = s._index;

  s.st_.st_size = Array.getsize (s.lines);

  set_modified (s);

  waddline (s, __vgetlinestr (s, line, 1), 0, s.ptr[0]);

  __vdraw_tail (s);
}

private define ed_del_chr (s)
{
  variable
    reg = qualifier ("reg", "\""),
    chr = qualifier ("chr", s._chr),
    col = s._index,
    i = __vlnr (s, '.'),
    line = __vline (s, '.'),
    len = strlen (line);

  if ((0 == s.ptr[1] - s._indent && 'X' == chr) || 0 > len - s._indent)
    return;

  if (any (['x', keys->rmap.delete] == chr))
    {
    _set_reg_ (reg, substr (line, col + 1, 1));
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
      _set_reg_ (reg, substr (line, col, 1));
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

  s.st_.st_size = Array.getsize (s.lines);

  set_modified (s);

  waddline (s, __vgetlinestr (s, line, 1), 0, s.ptr[0]);

  __vdraw_tail (s);
}

private define ed_change_word (s, what)
{
  variable
    reg = qualifier ("reg", "\""),
    end,
    word,
    start,
    lline,
    prev_l,
    next_l,
    func = islower (what) ? &__vfind_word : &__vfind_Word,
    col = s._index,
    lnr = __vlnr (s, '.'),
    line = __vline (s, '.');

  if (isblank (substr (line, col + 1, 1)))
    return;

  word = (@func) (s, line, col, &start, &end);

  _set_reg_ (reg, word);

  line = sprintf ("%s%s", substr (line, 1, start), substr (line, end + 2, -1));

  ifnot (lnr)
    prev_l = "";
  else
    prev_l = __vline (s, s.ptr[0] - 1);

  if (lnr == s._len)
    next_l = "";
  else
    next_l = s.lines[lnr + 1];

  if (s._index - s._indent > s._maxlen)
    lline = __vgetlinestr (s, line, s._findex + 1);
  else
    lline = __vgetlinestr (s, line, 1);

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
      ed_change_word (s, 'w';;__qualifiers ());
      return;
      }

    if ('W' == chr)
      {
      ed_change_word (s, 'W';;__qualifiers ());
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
      if (1 == ed_del_line (s;;__qualifiers ()))
        return;

      s.draw ();
      return;
      }

    if ('w' == chr)
      {
      ed_del_word (s, 'w';;__qualifiers ());
      return;
      }

    if ('W' == chr)
      {
      ed_del_word (s, 'W';;__qualifiers ());
      return;
      }

    }
}

private define ed_del_to_end (s)
{
  variable
    reg = qualifier ("reg", "\""),
    col = s._index,
    i = __vlnr (s, '.'),
    line = __vline (s, '.'),
    len = strlen (line);

  if (s._index == len)
    return;

  ifnot (s.ptr[1] - s._indent)
    {
    if (strlen (line))
     _set_reg_ (reg, line);

    line = __get_null_str (s._indent);

    s.ptr[1] = s._indent;
    s._index = s._indent;

    s.lines[i] = line;
    s.lins[s.ptr[0] - s.rows[0]] = line;

    Vundo.set (s, [_get_reg_ (reg)], [i]);
    set_modified (s);

    s.st_.st_size = Array.getsize (s.lines);

    waddline (s, __vgetlinestr (s, line, 1), 0, s.ptr[0]);

    __vdraw_tail (s);

    return;
    }

  if (strlen (line))
    _set_reg_ (reg, substr (line, col, -1));

  line = substr (line, 1, col);

  s.lins[s.ptr[0] - s.rows[0]] = line;
  s.lines[i] = line;

  s.st_.st_size = Array.getsize (s.lines);

  s.ptr[1]--;
  s._index--;

  Vundo.set (s, [_get_reg_ (reg)], [i]);

  set_modified (s);

  waddline (s, __vgetlinestr (s, line, 1), 0, s.ptr[0]);

  __vdraw_tail (s);
}

private define ed_editline (s)
{
  variable
    prev_l,
    next_l,
    lline,
    lnr = __vlnr (s, '.'),
    line = __vline (s, '.'),
    len = strlen (line);

  ifnot (lnr)
    prev_l = "";
  else
    prev_l = __vline (s, s.ptr[0] - 1);

  if (lnr == s._len)
    next_l = "";
  else
    next_l = s.lines[lnr + 1];

  if ('C' == s._chr)
    {
    Vundo.set (s, [line], [lnr]);
    line = substr (line, 1, s._index);
    }
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
    lline = __vgetlinestr (s, line, s._findex + 1);
  else
    lline = __vgetlinestr (s, line, 1);

  if (strlen (lline))
    {
    waddline (s, lline, 0, s.ptr[0]);
    smg->refresh ();
    }

  if ('C' == s._chr) % add to register? not really usefull
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
    lnr = __vlnr (s, '.'),
    line = __vline (s, '.'),
    len = strlen (line);

  if ("prev" == dir)
    ifnot (lnr)
      prev_l = "";
    else
      prev_l = __vline (s, s.ptr[0] - 1);
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

  s.st_.st_size = Array.getsize (s.lines);

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
  variable reg = _get_reg_ (qualifier ("reg", "\""));

  if (NULL == reg)
    return;

  variable
    lines = strchop (reg, '\n', 0),
    lnr = __vlnr (s, '.');

  if (length (lines) > 1)
    {
    variable ind = '\n' == reg[-1] ? -2 : -1;
    lines = lines[[:ind]];
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

  s.st_.st_size = Array.getsize (s.lines);

  set_modified (s);

  s.draw ();
}

private define ed_put (s)
{
  variable reg = _get_reg_ (qualifier ("reg", "\""));
  variable lnr = __vlnr (s, '.');

  if (NULL == reg)
    if (qualifier_exists ("return_line"))
      return s.lines[lnr];
    else
      return;

  variable lines = strchop (reg, '\n', 0);

  if (length (lines) > 1)
    {
    variable ind = '\n' == reg[-1] ? -2 : -1;
    lines = lines[[:ind]];
    s.lines = [s.lines[[:lnr]], lines, s.lines[[lnr + 1:]]];
    s._len += length (lines);
    }
  else
    s.lines[lnr] = substr (s.lines[lnr], 1, s._index + 1) + strjoin (lines) +
      substr (s.lines[lnr], s._index + 2, -1);

  s._i = lnr == 0 ? 0 : s._ii;

  s.st_.st_size = Array.getsize (s.lines);

  set_modified (s);

  s.draw ();

  if (qualifier_exists ("return_line"))
    return s.lines[lnr];
}

private define ed_toggle_case (s)
{
  variable
    col = s._index,
    i = __vlnr (s, '.'),
    line = __vline (s, '.'),
    chr = substr (line, col + 1, 1);

  chr = String.decode (chr)[0];


  ifnot (__define_case (&chr))
    {
    variable func = islower (chr) ? &toupper : &tolower;
    chr = char ((@func) (chr));
    }
  else
    chr = char (chr);

  s.st_.st_size -= strbytelen (line);
  line = substr (line, 1, col) + chr + substr (line, col + 2, - 1);
  s.lins[s.ptr[0] - s.rows[0]] = line;
  s.lines[i] = line;
  s.st_.st_size += strbytelen (line);
  set_modified (s);

  waddline (s, __vgetlinestr (s, line, 1), 0, s.ptr[0]);

  if (s._index - s._indent == __vlinlen (s, s.ptr[0]) - 1)
    __vdraw_tail (s);
  else
    (@VED_PAGER[string ('l')]) (s);
}

%%% INSERT MODE

private variable lang = input->getlang ();

private define ins_tab (is, s, line)
{
  % not sure what to do in feature, but as a fair compromise
  % and for now SLsmg_Tab_Width is set to 1 and nothing breaks
  % if _expandtab is set, then _shiftwidth (spaces) are inserted,

  variable tab = NULL == s._expandtab ? "\t" : repeat (" ", s._shiftwidth);
  variable len = strlen (tab);

  @line = substr (@line, 1, s._index) + tab + substr (@line, s._index + 1, - 1);

  s._index += len;

  is.modified = 1;

  if (strlen (@line) < s._maxlen && s.ptr[1] + len  < s._maxlen)
    {
    s.ptr[1] += len;
    waddline (s, __vgetlinestr (s, @line, 1), 0, s.ptr[0]);
    __vdraw_tail (s;chr = String.decode (substr (@line, s._index + 1, 1))[0]);
    return;
    }

  s._is_wrapped_line = 1;

  variable i = 0;
  if (s.ptr[1] < s._maxlen)
    while (s.ptr[1]++, i++, (s.ptr[1] < s._maxlen && i < len));
  else
    i = 0;

  s._findex += (len - i);

  variable
    lline = __vgetlinestr (s, @line, s._findex + 1 - s._indent);

  waddline (s, lline, 0, s.ptr[0]);
  __vdraw_tail (s;chr = String.decode (substr (@line, s._index + 1, 1))[0]);
}

private define ins_reg (s, line)
{
  variable reg = getch ();

  ifnot (any ([_regs_ (), '='] == reg))
    return;

  @line = ed_put (s;reg = char (reg), return_line);
}

private define ins_char (is, s, line)
{
  @line = substr (@line, 1, s._index) + char (is.chr) + substr (@line, s._index + 1, - 1);

  s._index++;

  is.modified = 1;

  if (strlen (@line) < s._maxlen && s.ptr[1] < s._maxlen)
    {
    s.ptr[1]++;
    waddline (s, __vgetlinestr (s, @line, 1), 0, s.ptr[0]);
    __vdraw_tail (s;chr = String.decode (substr (@line, s._index + 1, 1))[0]);
    return;
    }

  s._is_wrapped_line = 1;

  if (s.ptr[1] == s._maxlen)
    s._findex++;

  variable
    lline = __vgetlinestr (s, @line, s._findex + 1 - s._indent);

  if (s.ptr[1] < s._maxlen)
    s.ptr[1]++;

  waddline (s, lline, 0, s.ptr[0]);
  __vdraw_tail (s;chr = String.decode (substr (@line, s._index + 1, 1))[0]);
}

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

    lline = __vgetlinestr (s, @line, s._findex + 1 - s._indent);

    waddline (s, lline, 0, s.ptr[0]);
    __vdraw_tail (s;chr = String.decode (substr (@line, s._index + 1, 1))[0]);
    is.modified = 1;
    return;
    }

  @line = substr (@line, 1, s._index - 1) + substr (@line, s._index + 1, - 1);

  len = strlen (@line);

  ifnot (len)
    @line = __get_null_str (s._indent);

  s._index--;

  ifnot (s.ptr[1])
    {
    if (s._index > s._maxlen)
      {
      s.ptr[1] = s._maxlen;
      s._findex = len - s._linlen;
      lline = substr (@line, s._findex + 1, -1);
      waddline (s, lline, 0, s.ptr[0]);
      __vdraw_tail (s;chr = String.decode (substr (@line, s._index, 1))[0]);
      return;
      }

    s._findex = s._indent;
    s.ptr[1] = len;
    waddline (s, @line, 0, s.ptr[0]);
    __vdraw_tail (s;chr = String.decode (substr (@line, s._index, 1))[0]);
    s._is_wrapped_line = 0;
    return;
    }

  s.ptr[1]--;

  if (s._index == len && len)
    waddlineat (s, " ", 0, s.ptr[0], s.ptr[1], s._maxlen);
  else
    {
    lline = substr (@line, s._index + 1, -1);
    waddlineat (s, lline, 0, s.ptr[0], s.ptr[1], s._maxlen);
    }

  __vdraw_tail (s;chr = String.decode (substr (@line, s._index + 1, 1))[0]);

  is.modified = 1;
}

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
          waddline (s, __vgetlinestr (s, @line, 1), 0, s.ptr[0]);
          __vdraw_tail (s;chr = String.decode (substr (@line, s._index + 1, 1))[0]);
          }

        return;
        }
      else
        {
        @line = " ";
        waddline (s, @line, 0, s.ptr[0]);
        __vdraw_tail (s;chr = String.decode (substr (@line, s._index + 1, 1))[0]);
        is.modified = 1;
        return;
        }

  if (s._index == strlen (@line))
    {
    if (is.lnr < s._len)
      {
      @line += __vgetlinestr (s, s.lines[is.lnr + 1], 1);
      s.lines[is.lnr + 1 ] = NULL;
      s.lines = s.lines[wherenot (_isnull (s.lines))];
      s._len--;
      s._i = s._ii;
      s.draw (;dont_draw);
      is.modified = 1;
      if (s._is_wrapped_line)
        waddline (s, __vgetlinestr (s, @line, s._findex + 1 - s._indent), 0, s.ptr[0]);
      else
        waddline (s, __vgetlinestr (s, @line, 1), 0, s.ptr[0]);

      __vdraw_tail (s;chr = String.decode (substr (@line, s._index + 1, 1))[0]);
      }

    return;
    }

  @line = substr (@line, 1, s._index) + substr (@line, s._index + 2, - 1);

  if (s._is_wrapped_line)
    waddline (s, __vgetlinestr (s, @line, s._findex + 1 - s._indent), 0, s.ptr[0]);
  else
    waddline (s, __vgetlinestr (s, @line, 1), 0, s.ptr[0]);

  __vdraw_tail (s;chr = String.decode (substr (@line, s._index + 1, 1))[0]);
  is.modified = 1;
}

private define ins_eol (is, s, line)
{
  variable
    lline,
    len = strlen (@line);

  s._index = len;

  if (len > s._linlen)
    {
    s._findex = len - s._linlen;
    lline = __vgetlinestr (s, @line, s._findex + 1 - s._indent);

    waddline (s, lline, 0, s.ptr[0]);

    s.ptr[1] = s._maxlen;
    s._is_wrapped_line = 1;
    }
  else
    s.ptr[1] = len;

  __vdraw_tail (s;chr = String.decode (substr (@line, s._index + 1, 1))[0]);
}

private define ins_bol (is, s, line)
{
  s._findex = s._indent;
  s._index = s._indent;
  s.ptr[1] = s._indent;
  waddline (s, __vgetlinestr (s, @line, 1), 0, s.ptr[0]);
  __vdraw_tail (s;chr = String.decode (substr (@line, s._index + 1, 1))[0]);
  s._is_wrapped_line = 0;
}

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

    waddline (s, __vgetlinestr (s, @line, 1), 0, s.ptr[0]);
    __vdraw_tail (s;chr = String.decode (substr (@line, s._index + 1, 1))[0]);
    is.modified = 1;
    }
}

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
    lline = __vgetlinestr (s, @line, s._findex - s._indent);
    waddline (s, lline, 0, s.ptr[0]);
    }

  __vdraw_tail (s;chr = String.decode (substr (@line, s._index + 1, 1))[0]);
}

private define ins_left (is, s, line)
{
  if (0 < s.ptr[1] - s._indent)
    {
    s._index--;
    s.ptr[1]--;
    __vdraw_tail (s;chr = String.decode (substr (@line, s._index + 1, 1))[0]);
    }
  else
    if (s._is_wrapped_line)
      {
      s._index--;
      variable lline;
      lline = __vgetlinestr (s, @line, s._index - s._indent);

      waddline (s, lline, 0, s.ptr[0]);

      __vdraw_tail (s;chr = String.decode (substr (@line, s._index, 1))[0]);

      if (s._index - 1 == s._indent)
        s._is_wrapped_line = 0;
      }
}

private define ins_page_up (is, s, line)
{
  s.lins[s.ptr[0] - s.rows[0]] = @line;
  s.lines[is.lnr] = @line;
  s._findex = s._indent;

  (@VED_PAGER[string (keys->PPAGE)]) (s;modified);
  is.lnr = __vlnr (s, '.');
  @line = __vline (s, '.');

  ifnot (is.lnr)
    is.prev_l = "";
  else
    is.prev_l = s.lines[is.lnr - 1];

  is.next_l = s.lines[is.lnr + 1];
}

private define ins_page_down (is, s, line)
{
  s.lins[s.ptr[0] - s.rows[0]] = @line;
  s.lines[is.lnr] = @line;
  s._findex = s._indent;

  (@VED_PAGER[string (keys->NPAGE)]) (s;modified);
  is.lnr = __vlnr (s, '.');
  @line = __vline (s, '.');

  if (is.lnr == s._len)
    is.next_l = "";
  else
    is.next_l = s.lines[is.lnr + 1];

  is.prev_l = s.lines[is.lnr - 1];
}

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
    waddline (s, __vgetlinestr (s, @line, 1), 0, s.ptr[0]);
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
    __vdraw_tail (s;chr = strlen (@line)
      ? s._index > s._indent
        ? String.decode (substr (@line, s._index + 1, 1))[0]
        : String.decode (substr (@line, s._indent + 1, 1))[0]
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
      ? String.decode (substr (@line, s._index + 1, 1))[0]
      : String.decode (substr (@line, s._indent + 1, 1))[0]
    : ' ';

  s.draw (;chr = chr);
}

private define ins_up (is, s, line)
{
  variable i = __vlnr (s, '.');

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
    waddline (s, __vgetlinestr (s, @line, s._indent + 1 - s._indent), 0, s.ptr[0]);
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
    __vdraw_tail (s;chr = strlen (@line)
      ? s._index > s._indent
        ? String.decode (substr (@line, s._index + 1, 1))[0]
        : String.decode (substr (@line, s._indent + 1, 1))[0]
      : ' ');
    return;
    }

  s._i = s._ii - 1;

  variable chr = strlen (@line)
    ? s._index > s._indent
      ? String.decode (substr (@line, s._index + 1, 1))[0]
      : String.decode (substr (@line, s._indent + 1, 1))[0]
    : ' ';

  s.draw (;chr = chr);
}

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
        next_l = __vline (s, s.ptr[0] + 1);

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
    __vdraw_tail (s;chr = String.decode (substr (@line, s._index + 1, 1))[0]);

    s._index = indent;
    s._findex = s._indent;

    lang = input->getlang ();

    insert (s, line, is.lnr + 1, prev_l, next_l;modified, dont_draw_tail);
    }
}

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

    s.st_.st_size = Array.getsize (s.lines);
    }

  topline (" -- pager --");

  __vdraw_tail (s);
}

define ctrl_completion_rout (s, line, type)
{
  variable
    ar,
    chr,
    len,
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
    if ("ins_linecompletion" == type)
      {
      item = substr (@line, 1, s._index);
      variable ldws = strlen (item) - strlen (strtrim_beg (item));
      item = strtrim_beg (item);
      }

    if ("blockcompletion" == type)
      {
      item = strtrim_beg (@line);
      variable block_ar = qualifier ("block_ar");
      if (NULL == block_ar || 0 == length (block_ar)
        || (strlen (item) && 0 == length (wherenot (strncmp (
            block_ar, item, strlen (item))))))
        return;
      }
    }
  else if ("ins_wordcompletion" == type)
    {
    item = __vfpart_of_word (s, @line, col, &start);

    ifnot (strlen (item))
      return;
    }

  forever
    {
    ifnot (indexchanged)
      if ("ins_linecompletion" == type)
        ar = Re.unique_lines (s.lines, item, NULL;ign_lead_ws);
      else if ("ins_wordcompletion" == type)
        ar = Re.unique_words (s.lines, item, NULL);
      else if ("blockcompletion" == type)
        ifnot (strlen (item))
          ar = block_ar;
        else
          ar = block_ar[wherenot (strncmp (block_ar, item, strlen (item)))];

    ifnot (length (ar))
      {
      if (length (rows))
        smg->restore (rows, s.ptr, 1);

      waddline (s, __vgetlinestr (s, @line, 1), 0, s.ptr[0]);
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

      item = substr (item, 1, strlen (item) - 1);
      smg->restore (rows, NULL, NULL);
      waddline (s, __vgetlinestr (s, @line, 1), 0, s.ptr[0]);
      continue;
      }

    if (any ([' ', '\r'] == chr))
      {
      smg->restore (rows, NULL, NULL);

      if ("ins_linecompletion" == type)
        {
        len = strlen (item);
        item = ar[index - 1];
        variable llen = strlen (item);
        variable lldws = llen - strlen (strtrim_beg (item));

        if (llen - len < col)
          item = substr (item, col - len + 1, -1);

        if (llen - len > col)
          item = repeat (" ", ldws) + substr (item, lldws + 1, -1);

        @line = item + substr (@line, s._index + 1, -1);
        }
      else if ("ins_wordcompletion" == type)
        @line = substr (@line, 1, start) + ar[index - 1] + substr (@line, s._index + 1, -1);
      else if ("blockcompletion" == type)
        {
        @line = ar[index - 1];
        return;
        }

      waddline (s, __vgetlinestr (s, @line, 1), 0, s.ptr[0]);

      len = strlen (@line);

      %bug here (if len > maxlen) (wrapped line)
      if (len < origlen)
        s._index -= (origlen - len);
      else if (len > origlen)
        s._index += len - origlen;

      s.ptr[1] = s._index;

      __vdraw_tail (s;chr = String.decode (substr (@line, s._index + 1, 1))[0]);

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
      waddline (s, __vgetlinestr (s, @line, 1), 0, s.ptr[0]);
      smg->setrcdr (s.ptr[0], s.ptr[1]);
      return;
      }
    else if (any ([iwchars] == chr))
      item += char (chr);

    ifnot (indexchanged)
      {
      smg->restore (rows, NULL, NULL);
      waddline (s, __vgetlinestr (s, @line, 1), 0, s.ptr[0]);
      }

    % BUG HERE
    if (indexchanged)
      if (index > 1)
        if (index > LINES - 4)
          {
          index--;
          ar = ar[[1:]];
          }
    % when ar has been changed and index = 1
    }
}

define ins_linecompletion (s, line)
{
  ifnot (strlen (@line))
    return;

  ctrl_completion_rout (s, line, _function_name ());
}

private define __vfind_ldfnane (str, i)
{
  @i = strlen (str);
  ifnot (@i)
    return "";

  variable inv = [[0:32], [33:45], [58:64], [91:96]];
  variable fn = ""; variable c;

  do
    {
    c = substr (str, @i, 1);
    if (any (inv == c[0]) || (c[0] > 122 && 0 == any (c[0] == EL_MAP)))
      break;

    fn = c + fn;
    @i--;
    }
  while (@i);
  fn;
}

define ins_fnamecompletion (lnr, s, line)
{
  variable rl = get_cur_rline ();

  rline->set (rl;col = s.ptr[1], row = s.ptr[0]);

  variable i;
  variable orig = substr (@line, 1, s._index);
  variable fn = __vfind_ldfnane (orig, &i);
  variable r = rline->fnamecmpToprow (rl, &fn;header = NULL);
  if (033 == r || 0 == strlen (fn) || fn == orig)
    return;

  @line = (i ? substr (@line, 1, i) : "") + fn +
    (s._index + 1 == strlen (@line) ? "" : substr (@line, s._index + 2, -1));
  s.lines[lnr] = @line;
  s.st_.st_size = Array.getsize (s.lines);

  set_modified (s);

  waddline (s, __vgetlinestr (s, @line, 1), 0, s.ptr[0]);
  __vdraw_tail (s;chr = String.decode (substr (@line, s._index + 1, 1))[0]);
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
    waddline (s, __vgetlinestr (s, @line, 1), 0, s.ptr[0]);
  else
    {
    variable ar = strchop (assoc[@line], '\n', 0);
    % broken _for loop code,
    % trying to calc the indent
    % when there is an initial string to narrow the results,
    % might need a different approach
    %_for i (0, length (ar) - 1)
    %  (ar[i], ) = strreplace (ar[i], " ", "", strlen (item) - 1);

    @line = ar[0];
    if (1 == length (ar))
      waddline (s, __vgetlinestr (s, @line, 1), 0, s.ptr[0]);

    s.lines[lnr] = @line;
    s.lines = [s.lines[[:lnr]], 1 == length (ar) ? String_Type[0] : ar[[1:]],
      lnr == s._len ? String_Type[0] :  s.lines[[lnr+1:]]];
    s._len = length (s.lines) - 1;
    s.st_.st_size = Array.getsize (s.lines);

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
      line = __vline (s, '.');
      blockcompletion (__vlnr (s, '.'), s, &line);
    }

    {
    return;
    }
}

define ins_ctrl_x_completion (is, s, line)
{
  variable chr = getch ();

  switch (chr)

    {
    case keys->CTRL_l || case 'l':
      ins_linecompletion (s, line);
    }

    {
    case keys->CTRL_b || case 'b':
      blockcompletion (is.lnr, s, line);
    }

    {
    case keys->CTRL_f || case 'f':
      ins_fnamecompletion (is.lnr, s, line);
    }

    {
    return;
    }
}

define ins_wordcompletion (s, line)
{
  ctrl_completion_rout (s, line, _function_name ());
}

private define paste_xsel (s)
{
  ed_Put (s;reg = "*");
}

private define ins_getline (is, s, line)
{
  forever
    {
    is.chr = getch (;on_lang = &_on_lang_change_, on_lang_args = {"insert", s.ptr});

    if (033 == is.chr)
      {
      ins_esc (is, s, line);
      return;
      }

    if (keys->ESC_esc == is.chr)
      {
      s.lins[s.ptr[0] - s.rows[0]] = @line;
      s.lines[is.lnr] = @line;
      s.st_.st_size = Array.getsize (s.lines);
      __vwritefile (s, NULL, s.ptr, NULL, NULL);
      s._flags &= ~VED_MODIFIED;
      send_msg_dr (s._abspath + " written", 0, s.ptr[0], s.ptr[1]);
      sleep (0.02);
      send_msg_dr ("", 0, s.ptr[0], s.ptr[1]);
      continue;
      }

    if ('\r' == is.chr)
      {
      ins_cr (is, s, line);
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
      ins_up (is, s, line);
      continue;
      }

    if (keys->DOWN == is.chr)
      {
      ins_down (is, s, line);
      continue;
      }

    if (keys->NPAGE == is.chr)
      {
      ins_page_down (is, s, line);
      continue;
      }

    if (keys->PPAGE == is.chr)
      {
      ins_page_up (is, s, line);
      continue;
      }

    if (any (keys->rmap.left == is.chr))
      {
      ins_left (is, s, line);
      continue;
      }

    if (any (keys->rmap.right == is.chr))
      {
      ins_right (is, s, line);
      continue;
      }

    if (any (keys->CTRL_y == is.chr))
      {
      ifnot (strlen (is.prev_l))
        continue;

      ins_completeline (is, s, line, is.prev_l);
      continue;
      }

    if (any (keys->CTRL_e == is.chr))
      {
      ifnot (strlen (is.next_l))
        continue;

      ins_completeline (is, s, line, is.next_l);
      continue;
      }

    if (keys->CTRL_r == is.chr)
      {
      ins_reg (s, line);
      continue;
      }

    if (keys->F12 == is.chr)
      {
      paste_xsel (s);
      continue;
      }

    if (any (keys->rmap.home == is.chr))
      {
      ins_bol (is, s, line);
      continue;
      }

    if (any (keys->rmap.end == is.chr))
      {
      ins_eol (is, s, line);
      continue;
      }

    if (any (keys->rmap.backspace == is.chr))
      {
      ins_del_prev (is, s, line);
      continue;
      }

    if (any (keys->rmap.delete == is.chr))
      {
      ins_del_next (is, s, line);
      continue;
      }

    if ('\t' == is.chr)
      {
      ins_tab (is, s, line);
      continue;
      }

    if (' ' <= is.chr <= 126 || 902 <= is.chr <= 974)
      {
      ins_char (is, s, line);
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
    __vdraw_tail (s);

  ins_getline (self, s, line);

  lang = input->getlang ();

  input->setlang (input->get_en_lang ());
}

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
     "y[es]/n[o]/q[uit]/a[ll]/c[ansel]"];

  variable hl_reg = Array_Type[2];
  hl_reg[0] = [5, PROMPTROW - 8, strlen (fpart), 1, strlen (context)];
  hl_reg[1] = [2, PROMPTROW - 4, strlen (fpart), 1, strlen (replace)];

  variable char_ar =  ['y', 'n', 'q', 'a', 'c'];
  widg->askprintstr (ar, char_ar, &cmp_lnrs;hl_region = hl_reg);
}

define __substitute ()
{
  variable global = 0, ask = 1, pat = NULL, sub = NULL, ind, range = NULL;
  variable args = __pop_list (_NARGS);
  variable buf = get_cur_buf ();
  variable lnrs = [0:buf._len];

  args = list_to_array (args, String_Type);

  ind = is_arg ("--pat=", args);
  ifnot (NULL == ind)
    pat = substr (args[ind], strlen ("--pat=") + 1, -1);

  ind = is_arg ("--sub=", args);
  ifnot (NULL == ind)
    sub = substr (args[ind], strlen ("--sub=") + 1, -1);

  if (NULL == pat || NULL == sub)
    {
    send_msg_dr ("--pat= and --sub= are required", 1, buf.ptr[0], buf.ptr[1]);
    return;
    }

  if (0 == strlen (pat) || 0 == strlen (sub))
    {
    send_msg_dr ("--pat= and --sub= are required", 1, buf.ptr[0], buf.ptr[1]);
    return;
    }

  ind = is_arg ("--global", args);
  ifnot (NULL == ind)
    global = 1;

  ind = is_arg ("--dont-ask-when-subst", args);
  ifnot (NULL == ind)
    ask = 0;

  ind = is_arg ("--range=", args);
  ifnot (NULL == ind)
    {
    lnrs = __vparse_arg_range (buf, args[ind], lnrs);
    if (NULL == lnrs)
      return;
    }

  variable s = Subst.new (pat, sub;
    fname = buf._abspath, global = global, askwhensubst = ask, askonsubst = &_askonsubst_);

  if (NULL == s)
    {
    variable err = ();
    IO.tostderr (err);
    return;
    }

  variable retval = Subst.exec (s, buf.lines[lnrs]);

  ifnot (retval)
    {
    variable ar= ();
    ifnot (length (ar) == length (lnrs))
      {
      ifnot (lnrs[0])
        ifnot (lnrs[-1] == buf._len)
          buf.lines = [ar, buf.lines[[lnrs[-1] + 1:]]];
        else
          buf.lines = ar;
      else
        ifnot (lnrs[-1] == buf._len)
          buf.lines = [buf.lines[[:lnrs[0] - 1]], ar, buf.lines[[lnrs[-1] + 1:]]];
        else
          buf.lines = [buf.lines[[:lnrs[0] - 1]], ar];

      buf._len = length (buf.lines) - 1;
      }
    else
      buf.lines[lnrs] = ar;

    buf.st_.st_size = Array.getsize (buf.lines);
    set_modified (buf);
    buf.draw ();
    }
}

private define _register_ (s)
{
  variable reg = getch ();
  ifnot (any (_regs_ () == reg))
    return;

  reg = char (reg);

  variable chr = getch ();
  ifnot (any (['D', 'c', 'd', 'Y', 'p', 'P', 'x', 'X', keys->rmap.delete]
    == chr))
    return;

  if (any (['x', 'X', keys->rmap.delete] == chr))
    ed_del_chr (s;reg = reg, chr = chr);
  else if ('Y' == chr)
    pg_Yank (s;reg = reg);
  else if ('d' == chr)
    ed_del (s;reg = reg);
  else if ('c' == chr)
    ed_change (s;reg = reg);
  else if ('D' == chr)
    ed_del_to_end (s;reg = reg);
  else if ('P' == chr)
    ed_Put (s;reg = reg);
  else
    ed_put (s;reg = reg);
}

private define buffer_other (s) {}
private define handle_comma (s)
{
  variable chr = getch ();

  ifnot (any (['p'] == chr))
    return;

  if ('p' == chr)
    seltoX (get_cur_buf._abspath);
}

VED_PAGER[string (',')]           = &handle_comma;
VED_PAGER[string ('"')]           = &_register_;
VED_PAGER[string (keys->CTRL_a)]  = &_incr_nr_;
VED_PAGER[string (keys->CTRL_x)]  = &_decr_nr_;
VED_PAGER[string (keys->CTRL_l)]  = &__vreread;
VED_PAGER[string (keys->UP)]      = &pg_up;
VED_PAGER[string (keys->DOWN)]    = &pg_down;
VED_PAGER[string (keys->ESC_esc)] = &pg_write_on_esc;
VED_PAGER[string (keys->HOME)]    = &pg_bof;
VED_PAGER[string (keys->NPAGE)]   = &pg_page_down;
VED_PAGER[string (keys->CTRL_f)]  = &pg_page_down;
VED_PAGER[string (keys->CTRL_b)]  = &pg_page_up;
VED_PAGER[string (keys->PPAGE)]   = &pg_page_up;
VED_PAGER[string (keys->RIGHT)]   = &pg_right;
VED_PAGER[string (keys->LEFT)]    = &pg_left;
VED_PAGER[string (keys->END)]     = &pg_eol;
VED_PAGER[string (keys->CTRL_w)]  = &handle_w;
VED_PAGER[string (keys->CTRL_r)]  = &redo;
VED_PAGER[string (keys->BSLASH)]  = &search;
VED_PAGER[string (keys->QMARK)]   = &search;
VED_PAGER[string (keys->CTRL_v)]  = &vis_mode;
VED_PAGER[string (033)]           = &pag_completion;
VED_PAGER[string ('\r')]          = &__pg_on_carriage_return;
VED_PAGER[string ('m')]           = &mark;
VED_PAGER[string ('`')]           = &pg_gotomark;
VED_PAGER[string ('Y')]           = &pg_Yank;
VED_PAGER[string ('j')]           = &pg_down;
VED_PAGER[string ('k')]           = &pg_up;
VED_PAGER[string ('G')]           = &pg_eof;
VED_PAGER[string ('g')]           = &pg_g;
VED_PAGER[string (' ')]           = &pg_page_down;
VED_PAGER[string ('l')]           = &pg_right;
VED_PAGER[string ('h')]           = &pg_left;
VED_PAGER[string ('-')]           = &pg_eos;
VED_PAGER[string ('$')]           = &pg_eol;
VED_PAGER[string ('^')]           = &pg_bolnblnk;
VED_PAGER[string ('0')]           = &pg_bol;
VED_PAGER[string ('u')]           = &undo;
VED_PAGER[string ('#')]           = &s_search_word_;
VED_PAGER[string ('*')]           = &s_search_word_;
VED_PAGER[string ('n')]           = &s_backslash_reg_;
VED_PAGER[string ('N')]           = &s_backslash_reg_;
VED_PAGER[string ('v')]           = &vis_mode;
VED_PAGER[string ('V')]           = &vis_mode;
VED_PAGER[string ('~')]           = &ed_toggle_case;
VED_PAGER[string ('P')]           = &ed_Put;
VED_PAGER[string ('p')]           = &ed_put;
VED_PAGER[string ('o')]           = &ed_newline;
VED_PAGER[string ('O')]           = &ed_newline;
VED_PAGER[string ('c')]           = &ed_change;
VED_PAGER[string ('d')]           = &ed_del;
VED_PAGER[string ('D')]           = &ed_del_to_end;
VED_PAGER[string ('C')]           = &ed_editline;
VED_PAGER[string ('i')]           = &ed_editline;
VED_PAGER[string ('a')]           = &ed_editline;
VED_PAGER[string ('A')]           = &ed_editline;
VED_PAGER[string ('r')]           = &ed_chang_chr;
VED_PAGER[string ('J')]           = &ed_join_line;
VED_PAGER[string ('>')]           = &ed_indent_out;
VED_PAGER[string ('<')]           = &ed_indent_in;
VED_PAGER[string ('x')]           = &ed_del_chr;
VED_PAGER[string ('X')]           = &ed_del_chr;
VED_PAGER[string (keys->F12)]     = &paste_xsel;
VED_PAGER[string (keys->rmap.delete[0])]    = &ed_del_chr;
VED_PAGER[string (keys->rmap.backspace[0])] = &ed_del_trailws;
VED_PAGER[string (keys->rmap.backspace[1])] = &ed_del_trailws;
VED_PAGER[string (keys->rmap.backspace[2])] = &ed_del_trailws;

ifnot (NULL == Env.vget ("display"))
  ifnot (NULL == Env.vget ("xauthority"))
    ifnot (NULL == XCLIP_BIN)
      load.from ("X", "seltoX", NULL;err_handler = &__err_handler__);

private define msg_handler (s, msg)
{
  variable b = get_cur_buf ();
  send_msg_dr (msg, 1, b.ptr[0], b.ptr[1]);
}

new_wind ();
