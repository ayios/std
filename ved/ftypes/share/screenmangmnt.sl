define waddlineat_dr (line, clr, row, col, pos, len)
{
 smg->atrcaddnstrdr (line, clr, row, col, pos[0], pos[1], len);
}

define waddlineat (line, clr, row, col, len)
{
  smg->atrcaddnstr (line, clr, row, col, len);
  cf_.lexicalhl ([line], [row]);
}

define waddline (line, clr, row)
{
  smg->atrcaddnstr (line, clr, row, cf_._indent, cf_._linlen);
  cf_.lexicalhl ([line], [row]);
}

define waddlinear (ar, clrs, rows, cols, len)
{
  smg->aratrcaddnstr (ar, clrs, rows, cols, len);
}

define waddlinear_dr (ar, clrs, rows, cols, pos, len)
{
  smg->aratrcaddnstrdr (ar, clrs, rows, cols, pos[0], pos[1], len);
}

define send_msg_dr (str, clr, row, col)
{
  variable
    lcol = NULL == col ? strlen (str) + 1 : col,
    lrow = NULL == row ? MSGROW : row;

  smg->atrcaddnstrdr (str, clr, MSGROW, 0, lrow, lcol, COLUMNS);
}

define send_msg (str, clr)
{
  smg->atrcaddnstr (str, clr, MSGROW, 0, COLUMNS);
}
