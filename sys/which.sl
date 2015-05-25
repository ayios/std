loadfrom ("dir", "isdirectory", NULL, &on_eval_err);

define which (executable)
{
  variable
    ar,
    st,
    path;

  path = getenv ("PATH");
  if (NULL == path)
    return NULL;

  path = strchop (path, path_get_delimiter (), 0);
  path = array_map (String_Type, &path_concat, path, executable);
  path = path [wherenot (array_map (Integer_Type, &_isdirectory, path))];

  ar = wherenot (array_map (Integer_Type, &access, path, X_OK));

  if (length (ar))
    return path[ar][0];
  else
    return NULL;
}
