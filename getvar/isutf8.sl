define islangutf8 (lang)
{
  if (5 > strlen (lang))
    return 0;

  ifnot ("UTF-8" == substr (lang, strlen (lang) - 4, -1))
    return 0;

  return 1;
}

define v_islangutf8 (lang)
{
  if (islangutf8 (lang))
    return 1;

  tostderr ("locale: " + lang + " isn't UTF-8 (Unicode), or misconfigured");

  return 0;
}
