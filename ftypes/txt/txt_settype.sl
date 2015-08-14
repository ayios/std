define txt_settype (s, fname, rows, lines)
{
  variable def = deftype ();

  initbuf (s, fname, rows, lines, def;;__qualifiers ());
}
