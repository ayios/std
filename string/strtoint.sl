define strtoint (str)
{
  variable retval = atoi (str);

  ifnot (retval)
    if (str != "0")
      return NULL;

  return retval;
}
