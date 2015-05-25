define sl_lexicalhl ();

loadfile ("sl_syntax", NULL, &on_eval_err);

define sl_settype (s, fname, rows, lines)
{
  variable def = deftype ();

  def._shiftwidth = 2;
  def._autoindent = 1;
  def.lexicalhl = &sl_lexicalhl;

  initbuf (s, fname, rows, lines, def);
}
