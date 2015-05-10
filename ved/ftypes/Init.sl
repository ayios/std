typedef struct
  {
  _i,
  _ii,
  _len,
  _chr,
  _type,
  _fname,
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
  ved,
  draw,
  mainloop,
  lexicalhl,
  autoindent,
  } Ftype_Type;

typedef struct
  {
  _row,
  _col,
  _chr,
  _lin,
  _ind,
  lnrs,
  argv,
  com,
  cmp_lnrs,
  } Rline_Type;

typedef struct
  {
  chr,
  lnr,
  prev_l,
  next_l,
  modified,
  } Insert_Type;

variable BUFFERS = Assoc_Type[Ftype_Type];
variable TTY_INITED = 0;
define set_modified ();
define writetofile ();
define seltoX ();
define getch ();

variable
  cf_,
  rl_,
  rlf_,
  count = 0,
  IMG,
  REG = Assoc_Type[String_Type],
  clinef = Assoc_Type[Ref_Type],
  clinec,
  pagerf = Assoc_Type[Ref_Type],
  pagerc,
  is_wrapped_line = 0;

private define quit (t)
{
  () = evalfile (sprintf ("%s/share/%s", path_dirname (__FILE__), _function_name ()));

  return __get_reference (sprintf ("%s", _function_name ()));
}

private define ved (t)
{
  () = evalfile (sprintf ("%s/%s/%s", path_dirname (__FILE__), t, _function_name ()));

  return __get_reference (sprintf ("%s", _function_name ()));
}

private define draw (t)
{
  () = evalfile (sprintf ("%s/%s/%s", path_dirname (__FILE__), t, _function_name ()));

  return __get_reference (sprintf ("%s", _function_name ()));
}

private define lexicalhl ();
private define autoindent ();

define init_ftype (ftype)
{
  variable type = @Ftype_Type;
 
  ifnot (FTYPES[ftype])
    {
    set_slang_load_path (sprintf ("%s/%s%c%s", path_dirname (__FILE__), ftype,
      path_get_delimiter (), get_slang_load_path ()));
    FTYPES[ftype] = 1;
    }

  type._type = ftype;
  type.ved = ved (ftype);
  type.draw = draw (ftype);
  type.quit = quit (ftype);
  type.lexicalhl = &lexicalhl;
  type.autoindent = &autoindent;
  type._autoindent = 0;

  return type;
}
