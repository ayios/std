define markbacktick (s)
{
  MARKS[string ('`')]._i = s._ii;
  MARKS[string ('`')].ptr = s.ptr;
}

private define adjust_col (s, linlen, plinlen)
{
  if (linlen == 0 || 0 == s.ptr[1] - s._indent)
    {
    s.ptr[1] = s._indent;
    s._findex = s._indent;
    s._index = s._indent;
    }
  else if (linlen > s._linlen && s.ptr[1] + 1 == s._maxlen ||
    (s.ptr[1] - s._indent == plinlen - 1 && linlen > s._linlen))
      {
      s.ptr[1] = s._maxlen - 1;
      s._findex = s._indent;
      s._index = s._linlen - 1 + s._indent;
      }
  else if ((0 != plinlen && s.ptr[1] - s._indent == plinlen - 1 && (
      linlen < s.ptr[1] || linlen < s._linlen))
     || (s.ptr[1] - s._indent && s.ptr[1] - s._indent >= linlen))
      {
      s.ptr[1] = linlen - 1 + s._indent;
      s._index = linlen - 1 + s._indent;
      s._findex = s._indent;
      }
}

private define down (s)
{
  variable
    lnr = v_lnr (s, '.'),
    linlen,
    plinlen;

  if (lnr == s._len)
    return;

  if (s._is_wrapped_line)
    {
    waddline (s, getlinestr (s, v_lin (s, '.'), 1), 0, s.ptr[0]);
    s._is_wrapped_line = 0;
    }

  plinlen = v_linlen (s, '.');

  if (s.ptr[0] < s.vlins[-1])
    {
    s.ptr[0]++;
 
    linlen = v_linlen (s, '.');
 
    adjust_col (s, linlen, plinlen);

    draw_tail (s);

    return;
    }

  if (s.lnrs[-1] == s._len)
    return;

  s._i++;
 
  ifnot (s.ptr[0] == s.vlins[-1])
    s.ptr[0]++;

  s.draw (;dont_draw);
 
  linlen = v_linlen (s, '.');
 
  adjust_col (s, linlen, plinlen);
 
  smg->setrcdr (s.ptr[0], s.ptr[1]);
}

private define up (s)
{
  variable
    linlen,
    plinlen;

  if (s._is_wrapped_line)
    {
    waddline (s, getlinestr (s, v_lin (s, '.'), 1), 0, s.ptr[0]);
    s._is_wrapped_line = 0;
    }

  plinlen = v_linlen (s, '.');

  if (s.ptr[0] > s.vlins[0])
    {
    s.ptr[0]--;
 
    linlen = v_linlen (s, '.');
    adjust_col (s, linlen, plinlen);
 
    draw_tail (s);
 
    return;
    }

  ifnot (s.lnrs[0])
    return;

  s._i--;

  s.draw (;dont_draw);
 
  linlen = v_linlen (s, '.');
 
  adjust_col (s, linlen, plinlen);
 
  smg->setrcdr (s.ptr[0], s.ptr[1]);
}

private define gotoline (s)
{
  if (VEDCOUNT <= s._len + 1)
    {
    markbacktick (s);
    s._i = VEDCOUNT - (VEDCOUNT ? 1 : 0);
    s.draw (;dont_draw);

    s.ptr[0] = s.rows[0];
    s.ptr[1] = s._indent;
    s._findex = s._indent;
    s._index = s._indent;

    smg->setrcdr (s.ptr[0], s.ptr[1]);
    }
}

private define eof (s)
{

  if (VEDCOUNT > -1)
    {
    ifnot (VEDCOUNT + 1)
      VEDCOUNT = 0;

    gotoline (s);
    return;
    }

  markbacktick (s);

  s._i = s._len - s._avlins;

  s.ptr[1] = s._indent;
  s._findex = s._indent;
  s._index = s._indent;

  if (length (s.lins) < s._avlins - 1)
    {
    s.ptr[0] = s.vlins[-1];
    smg->setrcdr (s.ptr[0], s.ptr[1]);
    return;
    }

  s.draw (;dont_draw);

  s.ptr[0] = s.vlins[-1];

  smg->setrcdr (s.ptr[0], s.ptr[1]);
}

private define bof (s)
{
  if (VEDCOUNT > 0)
    {
    gotoline (s);
    return;
    }

  markbacktick (s);

  s._i = 0;
 
  s.ptr[0] = s.rows[0];
  s.ptr[1] = s._indent;
  s._findex = s._indent;
  s._index = s._indent;
 
  s.draw ();
}

define p_left (s)
{
  ifnot (s.ptr[1] - s._indent)
    ifnot (s._is_wrapped_line)
      return -1;

  s._index--;

  if (s._is_wrapped_line && 0 == s.ptr[1] - s._indent)
    {
    s._findex--;
 
    ifnot (s._findex)
      s._is_wrapped_line = 0;
 
    return 1;
    }

  s.ptr[1]--;
 
  return 0;
}

private define left (s)
{
  variable retval = p_left (s);
 
  if (-1 == retval)
    return;

  if (retval)
    {
    variable line;
    if (s._is_wrapped_line)
      line = getlinestr (s, v_lin (s, '.'), s._findex + 1);
    else
      line = getlinestr (s, v_lin (s, '.'), 1);

    waddline (s, line, 0, s.ptr[0]);
    }

  draw_tail (s);
}

define p_right (s, linlen)
{
  if (s._index - s._indent == linlen - 1 || 0 == linlen)
    return -1;

  if (s.ptr[1] < s._maxlen - 1)
    {
    s.ptr[1]++;
    s._index++;
    return 0;
    }
 
  s._index++;
  s._findex++;
 
  return 1;
}

private define right (s)
{
  variable
    line = v_lin (s, '.'),
    retval = p_right (s, v_linlen (s, '.'));

  if (-1 == retval)
    return;

  if (retval)
    {
    line = getlinestr (s, line, s._findex + 1 - s._indent);
    waddline (s, line, 0, s.ptr[0]);
    s._is_wrapped_line = 1;
    }

  draw_tail (s);
}

private define page_down (s)
{
  if (s._i + s._avlins > s._len)
    return;
 
  markbacktick (s);

  s._is_wrapped_line = 0;
  s._i += (s._avlins);

  s.ptr[1] = s._indent;
  s._index = s._indent;
  s._findex = s._indent;

  s.draw ();
}

private define page_up (s)
{
  ifnot (s.lnrs[0] - 1)
    return;
 
  markbacktick (s);

  if (s.lnrs[0] >= s._avlins)
    s._i = s.lnrs[0] - s._avlins;
  else
    s._i = 0;

  s._is_wrapped_line = 0;
  s.ptr[1] = s._indent;
  s._findex = s._indent;
  s._index = s._indent;

  s.draw ();
}

private define eos (s)
{
  variable linlen = v_linlen (s, '.');

  markbacktick (s);

  if (linlen > s._linlen)
    {
    s.ptr[1] = s._maxlen - 1;
    s._index = s._findex + s._linlen - 1 + s._indent;
    }
  else if (0 == linlen)
    {
    s.ptr[1] = s._indent;
    s._index = s._indent;
    s._findex = s._indent;
    }
  else
    {
    s.ptr[1] = linlen + s._indent - 1;
    s._findex = s._indent;
    s._index = linlen - 1 + s._indent;
    }
 
  draw_tail (s);
}

private define eol (s)
{
  variable linlen = v_linlen (s, s.ptr[0]);
 
  s._index = linlen - 1;

  if (linlen < s._linlen)
    s.ptr[1] = linlen + s._indent - 1;
  else
    {
    s.ptr[1] = s._maxlen - 1;
    s._index += s._indent;

    s._findex = linlen - s._linlen;

    variable line = getlinestr (s, v_lin (s, '.'), s._findex + 1);
 
    waddline (s, line, 0, s.ptr[0]);

    s._is_wrapped_line = 1;
    }
 
  draw_tail (s);
}

private define bol (s)
{
  s.ptr[1] = s._indent;
  s._findex = s._indent;
  s._index = s._indent;

  if (s._is_wrapped_line)
    {
    variable line = getlinestr (s, v_lin (s, '.'), 1);
    waddline (s, line, 0, s.ptr[0]);
    s._is_wrapped_line = 0;
    }

  draw_tail (s);
}

private define bolnblnk (s)
{
  s.ptr[1] = s._indent;

  variable linlen = v_linlen (s, '.');

  loop (linlen)
    {
    ifnot (isblank (s.lins[s.ptr[0] - s.rows[0]][s.ptr[1]]))
      break;

    s.ptr[1]++;
    }

  s._findex = s._indent;
  s._index = s.ptr[1] - s._indent;

  draw_tail (s);
}

private define word_change_case (s, what)
{
  variable
    ii,
    end,
    start,
    word,
    func_cond = what == "toupper" ? &islower : &isupper,
    func = what == "toupper" ? &toupper : &tolower,
    col = s._index,
    i = v_lnr (s, '.'),
    line = v_lin (s, '.');
 
  word = find_word (s, line, col, &start, &end);

  variable ar = decode (word);
  _for ii (0, length (ar) - 1)
    if ((@func_cond) (ar[ii]))
      word += char ((@func) (ar[ii]));
    else
      word += char (ar[ii]);

  line = sprintf ("%s%s%s", substr (line, 1, start), word, substr (line, end + 2, -1));
  s.lins[s.ptr[0] - s.rows[0]] = line;
  s.lines[i] = line;
  s.ptr[1] = start;
  s._index = start;

  set_modified (s);
 
  s.st_.st_size = getsizear (s.lines);

  waddline (s, line, 0, s.ptr[0]);

  draw_tail (s);
}

private define _g_ (s)
{
  variable
    chr = getch ();

  if ('g' == chr)
    {
    bof (s);
    return;
    }

  if ('U' == chr)
    {
    word_change_case (s, "toupper");
    return;
    }

  if ('u' == chr)
    {
    word_change_case (s, "tolower");
    return;
    }
}

private define Yank (s)
{
  variable
    line = v_lin (s, '.');

  REG["\""] = line + "\n";
  seltoX (line + "\n");
}

private define reread (s)
{
  s.lines = getlines (s._fname, s._indent, s.st_);

  s._len = length (s.lines) - 1;
 
  ifnot (s._len)
    {
    s._ii = 0;
    s.ptr[0] = s.rows[0];
    }
  else if (s._ii < s._len)
    {
    s._i = s._ii;
    while (s.ptr[0] - s.rows[0] + s._ii > s._len)
      s.ptr[0]--;
    }
  else
    {
    while (s._ii > s._len)
      s._ii--;

    s.ptr[0] = s.rows[0];
    }

  s.ptr[1] = 0;
 
  s._i = s._ii;

  s.draw ();
}

define gotomark (s)
{
  variable marks = assoc_get_keys (MARKS);
  variable mark = getch (;disable_langchange);
 
  mark = string (mark);

  if (any (mark == marks))
    {
    variable keep = @MARKS[mark];

    if (keep._i > s._len)
      return;

    MARKS[mark]._i = s._ii;
    MARKS[mark].ptr = s.ptr;

    s._i = keep._i;
    s.ptr = keep.ptr;

    s.draw ();
    }
}

define mark (s)
{
  variable mark = getch (;disable_langchange);
 
  if ('a' <= mark <= 'z')
    {
    mark = string (mark);
 
    ifnot (assoc_key_exists (MARKS, mark))
      MARKS[mark] = @Mark_Type;

    MARKS[mark]._i = s._ii;
    MARKS[mark].ptr = s.ptr;
    }
}

define _change_frame_ (s)
{
  change_frame ();
  s = get_cur_buf ();
}

define _new_frame_ (s)
{ 
  new_frame (TEMPDIR + "/" + string (_time) + ".noname");
  s = get_cur_buf ();
}

define _del_frame_ (s)
{
  del_frame ();
  s = get_cur_buf ();
}

define handle_w (s)
{
  variable chr = getch ();
 
  if (any (['w', 's', keys->CTRL_w, 'd'] == chr))
    {
    if (any (['w', keys->CTRL_w, keys->DOWN] == chr))
      {
      _change_frame_ (s);
      return;
      }
    
    if ('s' == chr)
      {
      _new_frame_ (s);
      return;
      }

    if ('d' == chr)
      {
      _del_frame_ (s);
      return;
      }
    }
}

define on_cariage_return (s)
{
}

VED_PAGER[string ('\r')] = &on_cariage_return;
VED_PAGER[string ('m')] = &mark;
VED_PAGER[string ('`')] = &gotomark;
VED_PAGER[string (keys->CTRL_l)] = &reread;
VED_PAGER[string ('Y')] = &Yank;
VED_PAGER[string (keys->DOWN)] = &down;
VED_PAGER[string ('j')] = &down;
VED_PAGER[string ('k')] = &up;
VED_PAGER[string (keys->UP)] = &up;
VED_PAGER[string ('G')]= &eof;
VED_PAGER[string (keys->HOME)] = &bof;
VED_PAGER[string ('g')]= &_g_;
VED_PAGER[string (' ')]= &page_down;
VED_PAGER[string (keys->NPAGE)] = &page_down;
VED_PAGER[string (keys->CTRL_f)] = &page_down;
VED_PAGER[string (keys->CTRL_b)] = &page_up;
VED_PAGER[string (keys->PPAGE)] = &page_up;
VED_PAGER[string (keys->RIGHT)] = &right;
VED_PAGER[string ('l')] = &right;
VED_PAGER[string ('h')] = &left;
VED_PAGER[string (keys->LEFT)] = &left;
VED_PAGER[string ('-')] = &eos;
VED_PAGER[string (keys->END)] = &eol;
VED_PAGER[string ('$')] = &eol;
VED_PAGER[string ('^')] = &bolnblnk;
VED_PAGER[string ('0')] = &bol;
VED_PAGER[string (keys->CTRL_w)] = &handle_w;
