private define adjust_col (linlen, plinlen)
{
  if (linlen == 0 || 0 == cf_.ptr[1] - cf_._indent)
    {
    cf_.ptr[1] = cf_._indent;
    cf_._findex = cf_._indent;
    cf_._index = cf_._indent;
    }
  else if (linlen > cf_._linlen && cf_.ptr[1] + 1 == cf_._maxlen ||
    (cf_.ptr[1] - cf_._indent == plinlen - 1 && linlen > cf_._linlen))
      {
      cf_.ptr[1] = cf_._maxlen - 1;
      cf_._findex = cf_._indent;
      cf_._index = cf_._linlen - 1 + cf_._indent;
      }
  else if ((0 != plinlen && cf_.ptr[1] - cf_._indent == plinlen - 1 && (
      linlen < cf_.ptr[1] || linlen < cf_._linlen))
     || (cf_.ptr[1] - cf_._indent && cf_.ptr[1] - cf_._indent >= linlen))
      {
      cf_.ptr[1] = linlen - 1 + cf_._indent;
      cf_._index = linlen - 1 + cf_._indent;
      cf_._findex = cf_._indent;
      }
}

private define down ()
{
  variable
    lnr = v_lnr ('.'),
    linlen,
    plinlen;

  if (lnr == cf_._len)
    return;

  if (is_wrapped_line)
    {
    waddline (getlinestr (v_lin ('.'), 1), 0, cf_.ptr[0]);
    is_wrapped_line = 0;
    }

  plinlen = v_linlen ('.');

  if (cf_.ptr[0] < cf_.vlins[-1])
    {
    cf_.ptr[0]++;
 
    linlen = v_linlen ('.');
 
    adjust_col (linlen, plinlen);

    draw_tail ();

    return;
    }

  if (cf_.lnrs[-1] == cf_._len)
    return;

  cf_._i++;
 
  ifnot (cf_.ptr[0] == cf_.vlins[-1])
    cf_.ptr[0]++;

  cf_.draw (;dont_draw);
 
  linlen = v_linlen ('.');
 
  adjust_col (linlen, plinlen);
 
  smg->setrcdr (cf_.ptr[0], cf_.ptr[1]);
}

private define up ()
{
  variable
    linlen,
    plinlen;

  if (is_wrapped_line)
    {
    waddline (getlinestr (v_lin ('.'), 1), 0, cf_.ptr[0]);
    is_wrapped_line = 0;
    }

  plinlen = v_linlen ('.');

  if (cf_.ptr[0] > cf_.vlins[0])
    {
    cf_.ptr[0]--;
 
    linlen = v_linlen ('.');
    adjust_col (linlen, plinlen);
 
    draw_tail ();
 
    return;
    }

  ifnot (cf_.lnrs[0])
    return;

  cf_._i--;

  cf_.draw (;dont_draw);
 
  linlen = v_linlen ('.');
 
  adjust_col (linlen, plinlen);
 
  smg->setrcdr (cf_.ptr[0], cf_.ptr[1]);
}

private define gotoline ()
{
  if (count <= cf_._len + 1)
    {
    cf_._i = count - (count ? 1 : 0);
    cf_.draw (;dont_draw);

    cf_.ptr[0] = cf_.rows[0];
    cf_.ptr[1] = cf_._indent;
    cf_._findex = cf_._indent;
    cf_._index = cf_._indent;

    smg->setrcdr (cf_.ptr[0], cf_.ptr[1]);
    }
}

private define eof ()
{
  if (count > -1)
    {
    ifnot (count + 1)
      count = 0;

    gotoline ();
    return;
    }

  cf_._i = cf_._len - cf_._avlins;

  cf_.ptr[1] = cf_._indent;
  cf_._findex = cf_._indent;
  cf_._index = cf_._indent;

  if (length (cf_.lins) < cf_._avlins - 1)
    {
    cf_.ptr[0] = cf_.vlins[-1];
    smg->setrcdr (cf_.ptr[0], cf_.ptr[1]);
    return;
    }

  cf_.draw (;dont_draw);

  cf_.ptr[0] = cf_.vlins[-1];

  smg->setrcdr (cf_.ptr[0], cf_.ptr[1]);
}

private define bof ()
{
  if (count > 0)
    {
    gotoline ();
    return;
    }

  cf_._i = 0;
 
  cf_.ptr[0] = cf_.rows[0];
  cf_.ptr[1] = cf_._indent;
  cf_._findex = cf_._indent;
  cf_._index = cf_._indent;
 
  cf_.draw ();
}

define p_left ()
{
  ifnot (cf_.ptr[1] - cf_._indent)
    ifnot (is_wrapped_line)
      return -1;

  cf_._index--;

  if (is_wrapped_line && 0 == cf_.ptr[1] - cf_._indent)
    {
    cf_._findex--;
 
    ifnot (cf_._findex)
      is_wrapped_line = 0;
 
    return 1;
    }

  cf_.ptr[1]--;
 
  return 0;
}

variable i = 0;
private define left ()
{
  variable retval = p_left ();
 
  if (-1 == retval)
    return;

  if (retval)
    {
    variable line;
    if (is_wrapped_line)
      line = getlinestr (v_lin ('.'), cf_._findex + 1);
    else
      line = getlinestr (v_lin ('.'), 1);

    waddline (line, 0, cf_.ptr[0]);
    }

  draw_tail ();
}

define p_right (linlen)
{
  if (cf_._index - cf_._indent == linlen - 1 || 0 == linlen)
    return -1;

  if (cf_.ptr[1] < cf_._maxlen - 1)
    {
    cf_.ptr[1]++;
    cf_._index++;
    return 0;
    }
 
  cf_._index++;
  cf_._findex++;
 
  return 1;
}

private define right ()
{
  variable
    line = v_lin ('.'),
    retval = p_right (v_linlen ('.'));

  if (-1 == retval)
    return;

  if (retval)
    {
    line = getlinestr (line, cf_._findex + 1 - cf_._indent);
    waddline (line, 0, cf_.ptr[0]);
    is_wrapped_line = 1;
    }

  draw_tail ();
}

private define page_down ()
{
  if (cf_._i + cf_._avlins > cf_._len)
    return;

  is_wrapped_line = 0;
  cf_._i += (cf_._avlins);

  cf_.ptr[1] = cf_._indent;
  cf_._index = cf_._indent;
  cf_._findex = cf_._indent;

  cf_.draw ();
}

private define page_up ()
{
  ifnot (cf_.lnrs[0] - 1)
    return;
 
  if (cf_.lnrs[0] >= cf_._avlins)
    cf_._i = cf_.lnrs[0] - cf_._avlins;
  else
    cf_._i = 0;

  is_wrapped_line = 0;
  cf_.ptr[1] = cf_._indent;
  cf_._findex = cf_._indent;
  cf_._index = cf_._indent;

  cf_.draw ();
}

private define eos ()
{
  variable linlen = v_linlen ('.');

  if (linlen > cf_._linlen)
    {
    cf_.ptr[1] = cf_._maxlen - 1;
    cf_._index = cf_._findex + cf_._linlen - 1 + cf_._indent;
    }
  else if (0 == linlen)
    {
    cf_.ptr[1] = cf_._indent;
    cf_._index = cf_._indent;
    cf_._findex = cf_._indent;
    }
  else
    {
    cf_.ptr[1] = linlen + cf_._indent - 1;
    cf_._findex = cf_._indent;
    cf_._index = linlen - 1 + cf_._indent;
    }

  draw_tail ();
}

private define eol ()
{
  variable linlen = v_linlen (cf_.ptr[0]);
 
  cf_._index = linlen - 1;

  if (linlen < cf_._linlen)
    cf_.ptr[1] = linlen + cf_._indent - 1;
  else
    {
    cf_.ptr[1] = cf_._maxlen - 1;
    cf_._index += cf_._indent;

    cf_._findex = linlen - cf_._linlen;

    variable line = getlinestr (v_lin ('.'), cf_._findex + 1);
 
    waddline (line, 0, cf_.ptr[0]);

    is_wrapped_line = 1;
    }
 
  draw_tail ();
}

private define bol ()
{
  cf_.ptr[1] = cf_._indent;
  cf_._findex = cf_._indent;
  cf_._index = cf_._indent;

  if (is_wrapped_line)
    {
    variable line = getlinestr (v_lin ('.'), 1);
    waddline (line, 0, cf_.ptr[0]);
    is_wrapped_line = 0;
    }

  draw_tail ();
}

private define bolnblnk ()
{
  cf_.ptr[1] = cf_._indent;

  variable linlen = v_linlen ('.');

  loop (linlen)
    {
    ifnot (isblank (cf_.lins[cf_.ptr[0] - cf_.rows[0]][cf_.ptr[1]]))
      break;

    cf_.ptr[1]++;
    }

  cf_._findex = cf_._indent;
  cf_._index = cf_.ptr[1] - cf_._indent;

  draw_tail ();
}

private define word_change_case (what)
{
  variable
    ii,
    end,
    start,
    word,
    func_cond = what == "toupper" ? &islower : &isupper,
    func = what == "toupper" ? &toupper : &tolower,
    col = cf_._index,
    i = v_lnr ('.'),
    line = v_lin ('.');
 
  word = find_word (line, col, &start, &end);

  variable ar = decode (word);
  _for ii (0, length (ar) - 1)
    if ((@func_cond) (ar[ii]))
      word += char ((@func) (ar[ii]));
    else
      word += char (ar[ii]);

  line = sprintf ("%s%s%s", substr (line, 1, start), word, substr (line, end + 2, -1));
  cf_.lins[cf_.ptr[0] - cf_.rows[0]] = line;
  cf_.lines[i] = line;
  cf_.ptr[1] = start;
  cf_._index = start;

  set_modified ();
 
  cf_.st_.st_size = calcsize (cf_.lines);

  waddline (line, 0, cf_.ptr[0]);

  draw_tail ();
}

private define _g_ ()
{
  variable
    chr = getch ();

  if ('g' == chr)
    {
    bof ();
    return;
    }

  if ('U' == chr)
    {
    word_change_case ("toupper");
    return;
    }

  if ('u' == chr)
    {
    word_change_case ("tolower");
    return;
    }
}

private define Yank ()
{
  variable
    line = v_lin ('.');

  REG["\""] = line + "\n";
  seltoX (line + "\n");
}

private define reread ()
{
  cf_.lines = getlines (cf_._fname, cf_._indent, cf_.st_);

  cf_._len = length (cf_.lines) - 1;
 
  ifnot (cf_._len)
    {
    cf_._ii = 0;
    cf_.ptr[0] = cf_.rows[0];
    }
  else if (cf_._ii < cf_._len)
    {
    cf_._i = cf_._ii;
    while (cf_.ptr[0] - cf_.rows[0] + cf_._ii > cf_._len)
      cf_.ptr[0]--;
    }
  else
    {
    while (cf_._ii > cf_._len)
      cf_._ii--;

    cf_.ptr[0] = cf_.rows[0];
    }

  cf_.ptr[1] = 0;
 
  cf_._i = cf_._ii;

  cf_.draw ();
}

pagerf[string (keys->CTRL_l)] = &reread;
pagerf[string ('Y')] = &Yank;
pagerf[string (keys->DOWN)] = &down;
pagerf[string ('j')] = &down;
pagerf[string ('k')] = &up;
pagerf[string (keys->UP)] = &up;
pagerf[string ('G')]= &eof;
pagerf[string (keys->HOME)] = &bof;
pagerf[string ('g')]= &_g_;
pagerf[string (keys->NPAGE)] = &page_down;
pagerf[string (keys->CTRL_f)] = &page_down;
pagerf[string (keys->CTRL_b)] = &page_up;
pagerf[string (keys->PPAGE)] = &page_up;
pagerf[string (keys->RIGHT)] = &right;
pagerf[string ('l')] = &right;
pagerf[string ('h')] = &left;
pagerf[string (keys->LEFT)] = &left;
pagerf[string ('-')] = &eos;
pagerf[string (keys->END)] = &eol;
pagerf[string ('$')] = &eol;
pagerf[string ('^')] = &bolnblnk;
pagerf[string ('0')] = &bol;
