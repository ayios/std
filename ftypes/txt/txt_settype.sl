define txt_settype (s, fname, rows, lines)
{
  variable def = deftype ();

  __vinitbuf (s, fname, rows, lines, def;;__qualifiers ());
}
