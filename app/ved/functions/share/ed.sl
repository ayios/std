loadfile ("insert_mode", NULL, &on_eval_err);

private define newline_str (s)
{
  return repeat (" ", s._indent + (s._autoindent ? s._shiftwidth : 0));
}

private define indent_in (s)
{
  variable
    i_ = s._indent,
    i = v_lnr (s, '.'),
    line = v_lin (s, '.');
 
  ifnot (strlen (line) - s._indent)
    return;

  ifnot (isblank (line[i_]))
    return;
 
  while (isblank (line[i_]) && i_ < s._shiftwidth + s._indent)
    i_++;

  line = substr (line, i_ + 1 - s._indent, -1);

  s.lins[s.ptr[0] - s.rows[0]] = line;
  s.lines[i] = line;
  s.ptr[1] -= i_;
  s._index -= i_;

  if (0 > s.ptr[1] - s._indent)
    s.ptr[1] = s._indent;

  if (0 > s._index - s._indent)
    s._index = s._indent;

  set_modified (s);

  s.st_.st_size += s._shiftwidth;

  waddline (s, line, 0, s.ptr[0]);
 
  draw_tail (s);
}

private define indent_out (s)
{
  variable
    i = v_lnr (s, '.'),
    line = v_lin (s, '.');

  line = sprintf ("%s%s", repeat (" ", s._shiftwidth), line);

  s.lins[s.ptr[0] - s.rows[0]] = line;
  s.lines[i] = line;
  s.ptr[1] += s._shiftwidth;
  s._index += s._shiftwidth;

  if (s.ptr[1] >= s._maxlen)
    s.ptr[1] = s._maxlen - 1;

  set_modified (s);

  s.st_.st_size += s._shiftwidth;

  waddline (s, line, 0, s.ptr[0]);

  draw_tail (s);
}

private define join_line (s)
{
  variable
    i = v_lnr (s, '.'),
    line = v_lin (s, '.');

  if (0 == s._len || i == s._len)
    return;

  s.lines[i] = line + " " + s.lines[i + 1];
  s.lines[i + 1] = NULL;
  s.lines = s.lines[wherenot (_isnull (s.lines))];
  s._len--;
 
  s._i = s._ii;
 
  set_modified (s);

  s.draw ();
}

private define del_line (s)
{
  variable
    i = v_lnr (s, '.'),
    line = v_lin (s, '.');

  if (0 == s._len && (0 == v_linlen (s, '.') || " " == line))
    return 1;

  ifnot (i)
    ifnot (s._len)
      {
      s.lines[0] = " ";
      s.st_.st_size = 0;
      s.ptr[1] = s._indent;
      s._index = s._indent;
      s._findex = s._indent;
      set_modified (s);
      return 0;
      }

  REG["\""] = s.lines[i] + "\n";

  s.lines[i] = NULL;
  s.lines = s.lines[wherenot (_isnull (s.lines))];
  s._len--;
 
  s._i = s._ii;
 
  s.ptr[1] = s._indent;
  s._index = s._indent;
  s._findex = s._indent;

  if (s.ptr[0] == s.vlins[-1] && 1 < length (s.vlins))
    s.ptr[0]--;

  s.st_.st_size -= strbytelen (line);

  if (s._i > s._len)
    s._i = s._len;
 
  set_modified (s;_i = s._i);

  return 0;
}

private define del_word (s, what)
{
  variable
    end,
    word,
    start,
    func = islower (what) ? &find_word : &find_Word,
    col = s._index,
    i = v_lnr (s, '.'),
    line = v_lin (s, '.');
 
  if (isblank (substr (line, col + 1, 1)))
    return;
 
  word = (@func) (s, line, col, &start, &end);
 
  REG["\""] = word;

  line = sprintf ("%s%s", substr (line, 1, start), substr (line, end + 2, -1));
 
  s.lins[s.ptr[0] - s.rows[0]] = line;
  s.lines[i] = line;
  s.ptr[1] = start;
  s._index = start;

  set_modified (s);
 
  s.st_.st_size = getsizear (s.lines);

  waddline (s, getlinestr (s, line, 1), 0, s.ptr[0]);

  draw_tail (s);
}

private define chang_chr (s)
{
  variable
    chr = getch (),
    col = s._index,
    i = v_lnr (s, '.'),
    line = v_lin (s, '.');

  if (' ' <= chr <= 126 || 902 <= chr <= 974)
    {
    s.st_.st_size -= strbytelen (line);
    line = substr (line, 1, col) + char (chr) + substr (line, col + 2, - 1);
    s.lins[s.ptr[0] - s.rows[0]] = line;
    s.lines[i] = line;
    s.st_.st_size += strbytelen (line);
    set_modified (s);
    waddline (s, getlinestr (s, line, 1), 0, s.ptr[0]);
    draw_tail (s);
    }
}

private define del_chr (s)
{
  variable
    col = s._index,
    i = v_lnr (s, '.'),
    line = v_lin (s, '.'),
    len = strlen (line);

  if ((0 == s.ptr[1] - s._indent && 'X' == s._chr) || 0 > len - s._indent)
    return;
 
  if (any (['x', keys->rmap.delete] == s._chr))
    {
    REG["\""] = substr (line, col + 1, 1);
    line = substr (line, 1, col) + substr (line, col + 2, - 1);
    if (s._index == strlen (line))
      {
      s.ptr[1]--;
      s._index--;
      }
    }
  else
    if (0 < s.ptr[1] - s._indent)
      {
      REG["\""] = substr (line, col, 1);
      line = substr (line, 1, col - 1) + substr (line, col + 1, - 1);
      s.ptr[1]--;
      s._index--;
      }
 
  ifnot (strlen (line))
    line = sprintf ("%s ", repeat (" ", s._indent));
 
  if (s.ptr[1] - s._indent < 0)
    s.ptr[1] = s._indent;

  if (s._index - s._indent < 0)
    s._index = s._indent;

  s.lins[s.ptr[0] - s.rows[0]] = line;
  s.lines[i] = line;

  s.st_.st_size = getsizear (s.lines);
 
  set_modified (s);
 
  waddline (s, getlinestr (s, line, 1), 0, s.ptr[0]);
 
  draw_tail (s);
}

private define change_word (s, what)
{
  variable
    end,
    word,
    start,
    lline,
    prev_l,
    next_l,
    func = islower (what) ? &find_word : &find_Word,
    col = s._index,
    lnr = v_lnr (s, '.'),
    line = v_lin (s, '.');
 
  if (isblank (substr (line, col + 1, 1)))
    return;
 
  word = (@func) (s, line, col, &start, &end);
 
  REG["\""] = word;

  line = sprintf ("%s%s", substr (line, 1, start), substr (line, end + 2, -1));
 
  ifnot (lnr)
    prev_l = "";
  else
    prev_l = v_lin (s, s.ptr[0] - 1);

  if (lnr == s._len)
    next_l = "";
  else
    next_l = s.lines[lnr + 1];
 
  if (s._index - s._indent > s._maxlen)
    lline = getlinestr (s, line, s._findex + 1);
  else
    lline = getlinestr (s, line, 1);
 
  if (strlen (lline))
    {
    waddline (s, lline, 0, s.ptr[0]);
    smg->refresh ();
    }
  
  s.ptr[1] = start;
  s._index = start;

  insert (s, &line, lnr, prev_l, next_l;modified);
}

private define change (s)
{
  variable chr = getch ();
 
  if (any (['w', 'W'] == chr))
    {
    if ('w' == chr)
      {
      change_word (s, 'w');
      return;
      }

    if ('W' == chr)
      {
      change_word (s, 'W');
      return;
      }
    }
}

private define del (s)
{
  variable chr = getch ();
 
  if (any (['d', 'w', 'W'] == chr))
    {
    if ('d' == chr)
      {
      if (1 == del_line (s))
        return;

      s.draw ();
      return;
      }
 
    if ('w' == chr)
      {
      del_word (s, 'w');
      return;
      }

    if ('W' == chr)
      {
      del_word (s, 'W');
      return;
      }
 
    }
}

private define del_to_end (s)
{
  variable
    col = s._index,
    i = v_lnr (s, '.'),
    line = v_lin (s, '.'),
    len = strlen (line);
 
  if (s._index == len)
    return;
 
  ifnot (s.ptr[1] - s._indent)
    {
    if (strlen (line))
      REG["\""] = line;

    line = repeat (" ", s._indent);
    ifnot (strlen (line))
      line = " ";
 
    s.ptr[1] = s._indent;
    s._index = s._indent;

    s.lines[i] = line;
    s.lins[s.ptr[0] - s.rows[0]] = line;
 
    set_modified (s);

    s.st_.st_size = getsizear (s.lines);

    waddline (s, getlinestr (s, line, 1), 0, s.ptr[0]);

    draw_tail (s);

    return;
    }
 
  variable reg = substr (line, col, -1);
  if (strlen (line))
    REG["\""] = reg;

  line = substr (line, 1, col);

  s.lins[s.ptr[0] - s.rows[0]] = line;
  s.lines[i] = line;
 
  s.st_.st_size = getsizear (s.lines);

  s.ptr[1]--;
  s._index--;

  set_modified (s);

  waddline (s, getlinestr (s, line, 1), 0, s.ptr[0]);

  draw_tail (s);
}

private define edit_line (s)
{
  variable
    prev_l,
    next_l,
    lline,
    lnr = v_lnr (s, '.'),
    line = v_lin (s, '.'),
    len = strlen (line);

  ifnot (lnr)
    prev_l = "";
  else
    prev_l = v_lin (s, s.ptr[0] - 1);

  if (lnr == s._len)
    next_l = "";
  else
    next_l = s.lines[lnr + 1];
 
  if ('C' == s._chr)
    line = substr (line, 1, s._index);
  else if ('a' == s._chr && len)
    {
    s._index++;
    s.ptr[1]++;
    }
  else if ('A' == s._chr)
    {
    s._index = len;
    s.ptr[1] = len;
    }
 
  if (s._index - s._indent > s._maxlen)
    lline = getlinestr (s, line, s._findex + 1);
  else
    lline = getlinestr (s, line, 1);
 
  if (strlen (lline))
    {
    waddline (s, lline, 0, s.ptr[0]);
    smg->refresh ();
    }

  if ('C' == s._chr)
    insert (s, &line, lnr, prev_l, next_l;modified);
  else
    insert (s, &line, lnr, prev_l, next_l);
}

private define newline (s)
{
  variable
    dir = s._chr == 'O' ? "prev" : "next",
    prev_l,
    next_l,
    col = s._index,
    lnr = v_lnr (s, '.'),
    line = v_lin (s, '.'),
    len = strlen (line);

    if ("prev" == dir)
      ifnot (lnr)
        prev_l = "";
      else
        prev_l = v_lin (s, s.ptr[0] - 1);
    else
      prev_l = line;
 
  if ("prev" == dir)
    next_l = line;
  else
    if (lnr == s._len)
      next_l = "";
    else
      next_l = v_lin (s, s.ptr[0] + 1);
 
  s._len++;

  if (0 == lnr && "prev" == dir)
    s.lines = [newline_str (s), s.lines];
  else
    s.lines = [s.lines[[:"next" == dir ? lnr : lnr - 1]], newline_str (s),
      s.lines[["next" == dir ? lnr + 1 : lnr:]]];

  s._i = lnr == 0 ? 0 : s._ii;
 
  if ("next" == dir)
    if (s.ptr[0] == s.rows[-2] && s.ptr[0] + 1 > s._avlins)
      s._i++;
    else
      s.ptr[0]++;

  s.ptr[1] = s._indent + (s._autoindent ? s._shiftwidth : 0);
  s._index = s._indent + (s._autoindent ? s._shiftwidth : 0);
  s._findex = s._indent + (s._autoindent ? s._shiftwidth : 0);
 
  s.draw (;dont_draw);
 
  line = newline_str (s);
  insert (s, &line, "next" == dir ? lnr + 1 : lnr, prev_l, next_l;;__qualifiers ());
}

private define Put (s)
{
  ifnot (assoc_key_exists (REG, "\""))
    return;

  variable
    lines = strchop (REG["\""], '\n', 0),
    lnr = v_lnr (s, '.');

  if ('\n' == REG["\""][-1])
    {
    lines = lines[[:-2]];
    ifnot (lnr)
      s.lines = [lines, s.lines];
    else
      s.lines = [s.lines[[:lnr - 1]], lines, s.lines[[lnr:]]];

    s._len += length (lines);
    }
  else
    s.lines[lnr] = substr (s.lines[lnr], 1, s._index) + strjoin (lines) +
      substr (s.lines[lnr], s._index + 1, -1);

  s._i = lnr == 0 ? 0 : s._ii;
 
  s.st_.st_size = getsizear (s.lines);
 
  set_modified (s);
 
  s.draw ();
}

private define put (s)
{
  ifnot (assoc_key_exists (REG, "\""))
    return;

  variable
    lines = strchop (REG["\""], '\n', 0),
    lnr = v_lnr (s, '.');

  if ('\n' == REG["\""][-1])
    {
    lines = lines[[:-2]];
    s.lines = [s.lines[[:lnr]], lines, s.lines[[lnr + 1:]]];
    s._len += length (lines);
    }
  else
    s.lines[lnr] = substr (s.lines[lnr], 1, s._index + 1) + strjoin (lines) +
      substr (s.lines[lnr], s._index + 2, -1);

  s._i = lnr == 0 ? 0 : s._ii;
 
  s.st_.st_size = getsizear (s.lines);
 
  set_modified (s);
 
  s.draw ();
}

private define toggle_case (s)
{
  variable
    func,
    col = s._index,
    i = v_lnr (s, '.'),
    line = v_lin (s, '.'),
    chr = substr (line, col + 1, 1);

  chr = decode (chr)[0];

  func = islower (chr) ? &toupper : &tolower;

  chr = char ((@func) (chr));
 
  s.st_.st_size -= strbytelen (line);
  line = substr (line, 1, col) + chr + substr (line, col + 2, - 1);
  s.lins[s.ptr[0] - s.rows[0]] = line;
  s.lines[i] = line;
  s.st_.st_size += strbytelen (line);
  set_modified (s);
 
  waddline (s, getlinestr (s, line, 1), 0, s.ptr[0]);

  if (s._index - s._indent == v_linlen (s, s.ptr[0]) - 1)
    draw_tail (s);
  else
    (@pagerf[string ('l')]) (s);
}

pagerf[string ('~')] = &toggle_case;
pagerf[string ('P')] = &Put;
pagerf[string ('p')] = &put;
pagerf[string ('o')] = &newline;
pagerf[string ('O')] = &newline;
pagerf[string ('c')] = &change;
pagerf[string ('d')] = &del;
pagerf[string ('x')] = &del_chr;
pagerf[string ('X')] = &del_chr;
pagerf[string (keys->rmap.delete[0])] = &del_chr;
if (2 == length (keys->rmap.delete))
  pagerf[string (keys->rmap.delete[1])] = &del_chr;
pagerf[string ('D')] = &del_to_end;
pagerf[string ('C')] = &edit_line;
pagerf[string ('i')] = &edit_line;
pagerf[string ('a')] = &edit_line;
pagerf[string ('A')] = &edit_line;
pagerf[string ('r')] = &chang_chr;
pagerf[string ('J')] = &join_line;
pagerf[string ('>')] = &indent_out;
pagerf[string ('<')] = &indent_in;

