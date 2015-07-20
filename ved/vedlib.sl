loadfrom ("stdio", "readfile", NULL, &on_eval_err);
loadfrom ("ved", "vedtypes", NULL, &on_eval_err);
loadfrom ("ved", "vedvars", NULL, &on_eval_err);

set_slang_load_path (sprintf ("%s%c%s", get_slang_load_path ( ), path_get_delimiter (),
  VEDDIR + "/share"));

VED_RLINE = 0;
VED_ISONLYPAGER = 1;

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
