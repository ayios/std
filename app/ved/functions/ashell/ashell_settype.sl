define ashell_lexicalhl ();

loadfile ("ashell_syntax", NULL, &on_eval_err);

define ashell_settype (s, fname, rows, lines)
{
  variable def = deftype ();

  def.lexicalhl = &ashell_lexicalhl;

  initbuf (s, fname, rows, lines, def;;__qualifiers ());
}
