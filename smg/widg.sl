private variable defclr = 11;
private variable headerclr = 5;

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

static define write_completion_routine (ar, startrow)
{
  variable
    lheaderclr = qualifier ("headerclr", headerclr),
    len = length (ar),
    cmpl_lnrs = [startrow:startrow + len - 1],
    columns = qualifier ("columns", COLUMNS),
    clrs = Integer_Type[len],
    cols = Integer_Type[len];

  clrs[*] = qualifier ("clr", defclr);
  ifnot (NULL == qualifier ("header")) clrs[0] = lheaderclr;
  cols[*] = qualifier ("startcol", 0);

  smg->aratrcaddnstr (ar, clrs, cmpl_lnrs, cols, columns);
  return cmpl_lnrs;
}

static define printtoscreen (ar, lastrow, len, cmpl_lnrs)
{
  ifnot (length (ar))
    {
    @len = 0;
    return @Array_Type[0];
    }

  variable lines = qualifier ("lines", lastrow - 2);
  variable origlen = @len;
  variable hlreg = qualifier ("hl_region");
  variable lar = @len < lines ? @ar : ar[[:lines - 1]];
  variable startrow = lastrow - (length (lar) > lines ? lines : length (lar));
  variable header = qualifier ("header");

  ifnot (NULL == header)  lar = [header, lar];

  @cmpl_lnrs = write_completion_routine (lar, startrow - (NULL == header ? 0 : 1)
    ;;__qualifiers ());

  ifnot (NULL == hlreg)
    smg->hlregion (hlreg[0], hlreg[1], hlreg[2], hlreg[3], hlreg[4]);

  @len = @len >= lines;

  if (qualifier_exists ("refresh"))
    smg->setrcdr (lastrow - 1, strlen (lar)[-1] + 1);

  return ar[[origlen >= lines ? lines - 1 : origlen:]];
}

static define printstrar (ar, lastrow, len, cmpl_lnrs)
{
  variable
    orig = ar,
    chr;

  ar = printtoscreen (ar, lastrow, len, cmpl_lnrs;;
    struct {@__qualifiers (), refresh});

  if (@len)
    {
    send_msg_dr ("Press any key except tab to exit, press tab to scroll",
      2, NULL, NULL);

    chr = getch (;disable_langchange);
 
    while ('\t' == chr)
      {
      smg->restore (@cmpl_lnrs, NULL, NULL);
 
      @len = length (ar);

      ar = printtoscreen (ar, lastrow, len, cmpl_lnrs;;
        struct {@__qualifiers (), refresh});

      ifnot (@len)
        ar = orig;

      chr = getch (;disable_langchange);
      }
    }
 
  return ar;
}

static define askprintstr (str, charar, cmp_lnrs)
{
  variable header = " ";
  variable headclr = headerclr;
  variable chr = NULL;
  variable type = typeof (str);
  variable ar = (String_Type == type || BString_Type == type) ? strchop (strtrim_end (str), '\n', 0) : str;
  variable len = length (ar);

  if ('@' == ar[0][0])
    {
    header = substr (ar[0], 2, -1);
    ar = ar[[1:]];
    len--;
    headclr = qualifier ("headerclr", headerclr);
    }
 
  ar = printstrar (ar,  PROMPTROW - 1, &len, cmp_lnrs;
    header = header, headerclr = headclr);

  ifnot (NULL == charar)
    {
    while (chr = getch (), 0 == any (chr == charar));
 
    smg->restore (@cmp_lnrs, NULL, 1);
    }

  return chr;
}
