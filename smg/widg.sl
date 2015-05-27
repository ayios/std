static define ask (questar, charar, pos)
{
  smg->aratrcaddnstrdr (questar, 7, [PROMPTROW - length (questar):PROMPTROW - 1], 0,
    PROMPTROW - 1, strlen (questar[-1]) + 1, COLUMNS);
 
  variable chr;

  while (chr = getch (), 0 == any (chr == charar));
 
  smg->restore ([PROMPTROW - length (questar) - 1:PROMPTROW - 1], pos, 1);

  return chr;
}

static define getpasswd ()
{
  send_msg_dr ("Password:", 1, NULL, NULL);
 
  variable chr;
  variable passwd = "";
 
  forever
    {
    chr = getch ();
    if ('\r' == chr)
      break;
    passwd += char (chr);
    }

  send_msg_dr (" ", 0, NULL, NULL);

  return passwd + "\n";
}

static define _pop_up_ (ar, row, col, ifocus)
{
  variable lar = array_map (String_Type, &sprintf, " %s", ar);

  variable i;
  variable len = length (lar);
  variable fgclr = qualifier ("fgclr", 5);
  variable bgclr = qualifier ("bgclr", 11);
  variable maxlen = max (strlen (lar)) + 1;
  
%  if (maxlen > COLUMNS)
%    _for i (0, len - 1)
%      if (strlen (lar[i]) > COLUMNS)
%        lar[i] = substr (lar[i], 1, COLUMNS);
%
%  if (maxlen > COLUMNS)
%    col = 0;
%  else
%    while (col + maxlen > COLUMNS)
%      col--;

  variable rows = [row:row + len - 1];
  variable clrs = Integer_Type[len];
  variable cols = Integer_Type[len];

  clrs[*] = bgclr;
  clrs[ifocus - 1] = fgclr;
  cols[*] = col;
 
  smg->aratrcaddnstr (lar, clrs, rows, cols, maxlen);

  return rows;
}

static define pop_up (ar, row, col, ifocus)
{
  ifnot (length (ar))
    return Integer_Type[0];

  variable avail_lines = LINES - 4;
  variable lar;
  variable lrow = row;

  if (length (ar) > avail_lines)
    lar = ar[[:avail_lines - 1]];
  else
    lar = @ar;

  while (lrow--, lrow - 1 + length (lar) >= avail_lines);
  lrow++;
 
  return _pop_up_ (lar, lrow, col, ifocus;;__qualifiers ());
}
