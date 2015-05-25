define getlang ()
{
  return getenv ("LANG");
}

define v_getlang ()
{
  variable lang = getenv ("LANG");

  if (NULL == lang)
    tostderr ("LANG environment variable isn't set");
 
  return lang;
}
