public variable
  FTYPES = Assoc_Type[Integer_Type],
  VED_MODIFIED = 0x01,
  VED_ONDISKMODIFIED = 0x02,
  VED_RDONLY = 0x04,
  VED_ROWS,
  VED_PROMPTCLR,
  VED_INFOCLRBG,
  VED_INFOCLRFG,
  XCLIP_BIN = which ("xclip");

public variable
  MSGROW,
  PROMPTROW;

public variable
  VED_FRAME = 0,
  VED_MAXFRAMES = 2,
  VED_FRAME_ROWS,
  VED_BUFINDEX = 0,
  VED_BUFNAMES = String_Type[0],
  VED_BUFFERS = Assoc_Type[Ftype_Type];

public variable
  VED_EDITOTHER = 1,
  VED_ISONLYPAGER = 0,
  VED_DRAWONLY = 0,
  VED_RLINE = 1,
  VED_INITDONE = 0;

public variable
  EL_MAP = [[913:929:1], [931:937:1], [945:969:1]],
  EN_MAP = [['a':'z'], ['A':'Z']],
  MAPS = [EL_MAP, EN_MAP],
  WCHARS = array_map (String_Type, &char, [['0':'9'], EN_MAP, EL_MAP, '_']);

public variable VED_TEMPDIR;

public variable VED_SCRATCH_BUF = "/tmp/scratch.txt";
 
private define _invalid ()
{
  return;
}

public variable
  VED_CB,
  pagerf = Assoc_Type[Ref_Type, &_invalid],
  VEDCOUNT = 0,
  REG = Assoc_Type[String_Type];

FTYPES["ashell"] = 0;
FTYPES["txt"] = 0;
FTYPES["sl"] = 0;
FTYPES["list"] = 0;

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
