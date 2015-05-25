define getterm ()
{
  return getenv ("TERM");
}

define v_getterm ()
{
  variable term = getenv ("TERM");

  if (NULL == term)
    tostderr ("TERM environment variable isn't set");

  return term;
}
