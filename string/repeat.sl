define repeat (chr, count)
{
  ifnot (0 < count)
    return "";

  variable ar = String_Type[count];
  ar[*] = chr;
  return strjoin (ar);
}
