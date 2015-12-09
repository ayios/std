define diff_lexicalhl ();

load.from ("ftypes/diff", "diff_syntax", NULL;err_handler = &__err_handler__);

define diff_settype (s, fname, rows, lines)
{
  variable def = deftype ();

  def.lexicalhl = &diff_lexicalhl;

  __vinitbuf (s, fname, rows, lines, def;;__qualifiers ());
}
