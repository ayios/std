define _topline_ (str, columns)
{
  variable t = strftime ("[%a %d %b %I:%M:%S]");
  @str += repeat (" ", columns - strlen (@str) - strlen (t)) + t;
}

