private define eval (dir)
{
  if ('~' == dir[0])
    (dir,) = strreplace (dir, "~", Env.vget ("home"), 1);
  else if (0 == path_is_absolute (dir)
          && '$' != dir[0]
          && 0 == qualifier_exists ("dont_change"))
    dir = path_concat (getcwd (), dir);
  else
    dir = eval ("\"" + dir + "\"$");

  return dir;
}


