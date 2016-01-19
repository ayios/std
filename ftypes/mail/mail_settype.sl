define mail_lexicalhl ();

load.from ("ftypes/mail", "mail_syntax", NULL;err_handler = &__err_handler__);

define mail_settype (s, fname, rows, lines)
{
  variable def = deftype ();

  def._shiftwidth = 2;
  def._expandtab = 1;
  def.lexicalhl = &mail_lexicalhl;

  __vinitbuf (s, fname, rows, lines, def);
}
