define sl_lexicalhl ();

loadfrom ("ftypes/sl", "sl_syntax", NULL, &on_eval_err);

define sl_settype (s, fname, rows, lines)
{
  variable def = deftype ();

  def._shiftwidth = 2;
  def._expandtab = 1;
  def.lexicalhl = &sl_lexicalhl;

  __vinitbuf (s, fname, rows, lines, def);
}
