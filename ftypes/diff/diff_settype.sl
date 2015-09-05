define diff_lexicalhl ();

loadfrom ("ftypes/diff", "diff_syntax", NULL, &on_eval_err);

define diff_settype (s, fname, rows, lines)
{
  variable def = deftype ();

  def.lexicalhl = &diff_lexicalhl;

  __vinitbuf (s, fname, rows, lines, def;;__qualifiers ());
}
