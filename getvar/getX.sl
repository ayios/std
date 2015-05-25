define getX ()
{
  return getenv ("DISPLAY");
}

define v_getX ()
{
  variable display = getenv ("DISPLAY");

  if (NULL == display)
    tostderr ("X server is not running");

  return display;
}
