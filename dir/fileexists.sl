define fileexists (file)
{
  ifnot (access (file, F_OK))
    return 1;

  return 0;
}
