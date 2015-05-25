define waddlineat (s, line, clr, row, col, len)
{
  smg->atrcaddnstr (line, clr, row, col, len);
  s.lexicalhl ([line], [row]);
}

define waddline (s, line, clr, row)
{
  smg->atrcaddnstr (line, clr, row, s._indent, s._linlen);
  s.lexicalhl ([line], [row]);
}
