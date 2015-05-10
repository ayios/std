define read_fd (fd)
{
  variable
    buf,
    str = "";

  while (read (fd, &buf, 1024) > 0)
    str = sprintf ("%s%s", str, buf);

  return strlen (str) ? str : NULL;
}

define isdirectory (file)
{
  variable st = qualifier ("st", stat_file (file));
  return NULL != st && stat_is ("dir", st.st_mode);
}

define which (executable)
{
  variable
    ar,
    path;

  path = getenv ("PATH");
  if (NULL == path)
    return NULL;

  path = strchop (path, path_get_delimiter (), 0);
  path = array_map (String_Type, &path_concat, path, executable);
  path = path [wherenot (array_map (Integer_Type, &isdirectory, path))];

  ar = wherenot (array_map (Integer_Type, &access, path, X_OK));

  if (length (ar))
    return path[ar][0];
  else
    return NULL;
}

define eval_dir (dir)
{
  if ('~' == dir[0])
    (dir,) = strreplace (dir, "~", getenv ("HOME"), 1);
  else if (0 == path_is_absolute (dir)
          && '$' != dir[0]
          && 0 == qualifier_exists ("dont_change"))
    dir = path_concat (getcwd (), dir);
  else
    dir = eval ("\"" + dir + "\"$");

  return dir;
}

define repeat (chr, count)
{
  ifnot (0 < count)
    return "";

  variable ar = String_Type[count];
  ar[*] = chr;
  return strjoin (ar);
}
