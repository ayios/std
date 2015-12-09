define sl_lexicalhl ();

load.from ("ftypes/sl", "sl_syntax", NULL;err_handler = &__err_handler__);

define sl_settype (s, fname, rows, lines)
{
  variable def = deftype ();

  def._shiftwidth = 2;
  def._expandtab = 1;
  def.lexicalhl = &sl_lexicalhl;

  __vinitbuf (s, fname, rows, lines, def);
}
