define repeat (str, count)
{
  ifnot (0 < count)
    return "";

  variable ar = String_Type[count];
  ar[*] = str;
  return strjoin (ar);
}
