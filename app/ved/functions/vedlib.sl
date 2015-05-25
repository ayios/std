set_slang_load_path (sprintf ("%s%c%s", get_slang_load_path ( ), path_get_delimiter (),
  path_dirname (__FILE__) + "/share"));

loadfrom ("stdio", "readfile", NULL, &on_eval_err);
loadfrom ("sys", "which", NULL, &on_eval_err);

loadfile (path_dirname (__FILE__) + "/types", NULL, &on_eval_err);
loadfile (path_dirname (__FILE__) + "/vars", NULL, &on_eval_err);

VED_RLINE = 0;
VED_ISONLYPAGER = 1;

define init_ftype (ftype)
{
  ifnot (FTYPES[ftype])
    {
    set_slang_load_path (sprintf ("%s/%s%c%s", path_dirname (__FILE__), ftype,
      path_get_delimiter (), get_slang_load_path ()));
    FTYPES[ftype] = 1;
    }

  variable type = @Ftype_Type;

  loadfile (ftype + "_functions", NULL, &on_eval_err);

  type._type = ftype;
  return type;
}
