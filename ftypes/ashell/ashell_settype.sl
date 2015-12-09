define ashell_lexicalhl ();

load.from ("ftypes/ashell", "ashell_syntax", NULL;err_handler = &__err_handler__);

define ashell_settype (s, fname, rows, lines)
{
  variable def = deftype ();

  def.lexicalhl = &ashell_lexicalhl;

  __vinitbuf (s, fname, rows, lines, def;;__qualifiers ());
}
