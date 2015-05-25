define getxauth ()
{
  return getenv ("XAUTHORITY");
}

define v_getxauth ()
{
  variable xauth = getenv ("XAUTHORITY");

  if (NULL == xauth)
    tostderr ("XAUTHORITYE environment variable isn't set");

  return xauth;
}
