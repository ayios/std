define send_msg_dr (str, clr, row, col)
{
  variable
    lcol = NULL == col ? strlen (str) : col,
    lrow = NULL == row ? MSGROW : row;

  smg->atrcaddnstrdr (str, clr, MSGROW, 0, lrow, lcol, COLUMNS);
}

define send_msg (str, clr)
{
  smg->atrcaddnstr (str, clr, MSGROW, 0, COLUMNS);
}
