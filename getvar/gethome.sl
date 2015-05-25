define gethome ()
{
  return getenv ("HOME");
}

define v_gethome ()
{
  variable home = getenv ("HOME");

  if (NULL == home)
    tostderr ("HOME environment variable isn't set");

  return home;
}
