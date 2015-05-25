define getch ();

variable clinef = Assoc_Type[Ref_Type];

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
  type.ved = ved (ftype);
  type.quit = quit (ftype);

  return type;
}
