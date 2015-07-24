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
  VED_FRAME = 0,
  VED_MAXFRAMES = 2,
  VED_FRAME_ROWS,
  VED_BUFINDEX = 0,
  VED_BUFNAMES = String_Type[0],
  VED_BUFFERS = Assoc_Type[Ftype_Type];

public variable
  VED_ISONLYPAGER = 0,
  VED_RLINE = 1,
  VED_INITDONE = 0;

public variable VED_CB;
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
