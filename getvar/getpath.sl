define getpath ()
{
  return getenv ("PATH");
}

define v_getpath ()
{
  variable path = getenv ("PATH");

  if (NULL == path)
    tostderr ("PATH environment variable isn't set");

  return path;
}
