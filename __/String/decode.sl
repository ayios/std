private define decode (self, str)
{
  variable
    d,
    i = 0,
    l = {};

  forever
    {
    (i, d) = strskipchar (str, i);
    if (d)
      list_append (l, d);
    else
      break;
    }

  length (l) ? list_to_array (l) : ['\n'];
}
