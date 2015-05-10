loadfile ("insert_mode", NULL, &exit_on_eval_err);

private define newline_str (s)
{
  return repeat (" ", s._indent + (s._autoindent ? s._shiftwidth : 0)); 
}

private define indent_in ()
{
  variable
    i_ = cf_._indent,
    i = v_lnr ('.'),
    line = v_lin ('.');
  
  ifnot (strlen (line) - cf_._indent)
    return;

  ifnot (isblank (line[i_]))
    return;
  
  while (isblank (line[i_]) && i_ < cf_._shiftwidth + cf_._indent)
    i_++;

  line = substr (line, i_ + 1 - cf_._indent, -1);

  cf_.lins[cf_.ptr[0] - cf_.rows[0]] = line;
  cf_.lines[i] = line;
  cf_.ptr[1] -= i_;
  cf_._index -= i_;

  if (0 > cf_.ptr[1] - cf_._indent)
    cf_.ptr[1] = cf_._indent;

  if (0 > cf_._index - cf_._indent)
    cf_._index = cf_._indent;

  set_modified ();

  cf_.st_.st_size += cf_._shiftwidth;

  waddline (line, 0, cf_.ptr[0]);
 
  draw_tail ();
}

private define indent_out ()
{
  variable
    i = v_lnr ('.'),
    line = v_lin ('.');

  line = sprintf ("%s%s", repeat (" ", cf_._shiftwidth), line);

  cf_.lins[cf_.ptr[0] - cf_.rows[0]] = line;
  cf_.lines[i] = line;
  cf_.ptr[1] += cf_._shiftwidth;
  cf_._index += cf_._shiftwidth;

  if (cf_.ptr[1] >= cf_._maxlen)
    cf_.ptr[1] = cf_._maxlen - 1;

  set_modified ();

  cf_.st_.st_size += cf_._shiftwidth;

  waddline (line, 0, cf_.ptr[0]);

  draw_tail ();
}

private define join_line ()
{
  variable
    i = v_lnr ('.'),
    line = v_lin ('.');

  if (0 == cf_._len || i == cf_._len)
    return;

  cf_.lines[i] = line + " " + cf_.lines[i + 1];
  cf_.lines[i + 1] = NULL;
  cf_.lines = cf_.lines[wherenot (_isnull (cf_.lines))];
  cf_._len--;
 
  cf_._i = cf_._ii;
 
  set_modified ();

  cf_.draw ();
}

private define del_line ()
{
  variable
    i = v_lnr ('.'),
    line = v_lin ('.');

  if (0 == cf_._len && (0 == v_linlen ('.') || " " == line))
    return 1;

  ifnot (i)
    ifnot (cf_._len)
      {
      cf_.lines[0] = " ";
      cf_.st_.st_size = 0;
      cf_.ptr[1] = cf_._indent;
      cf_._index = cf_._indent;
      cf_._findex = cf_._indent;
      set_modified ();
      return 0;
      }

  REG["\""] = cf_.lines[i] + "\n";

  cf_.lines[i] = NULL;
  cf_.lines = cf_.lines[wherenot (_isnull (cf_.lines))];
  cf_._len--;
 
  cf_._i = cf_._ii;
 
  cf_.ptr[1] = cf_._indent;
  cf_._index = cf_._indent;
  cf_._findex = cf_._indent;

  if (cf_.ptr[0] == cf_.vlins[-1] && 1 < length (cf_.vlins))
    cf_.ptr[0]--;

  cf_.st_.st_size -= strbytelen (line);

  if (cf_._i > cf_._len)
    cf_._i = cf_._len;
 
  set_modified (;_i = cf_._i);

  return 0;
}

private define del_word (what)
{
  variable
    end,
    word,
    start,
    func = islower (what) ? &find_word : &find_Word,
    col = cf_._index,
    i = v_lnr ('.'),
    line = v_lin ('.');
 
  if (isblank (substr (line, col + 1, 1)))
    return;
 
  word = (@func) (line, col, &start, &end);
 
  REG["\""] = word;

  line = sprintf ("%s%s", substr (line, 1, start), substr (line, end + 2, -1));
 
  cf_.lins[cf_.ptr[0] - cf_.rows[0]] = line;
  cf_.lines[i] = line;
  cf_.ptr[1] = start;
  cf_._index = start;

  set_modified ();
 
  cf_.st_.st_size = calcsize (cf_.lines);

  waddline (getlinestr (line, 1), 0, cf_.ptr[0]);

  draw_tail ();
}

private define chang_chr ()
{
  variable
    chr = getch (),
    col = cf_._index,
    i = v_lnr ('.'),
    line = v_lin ('.');

  if (' ' <= chr <= 126 || 902 <= chr <= 974)
    {
    cf_.st_.st_size -= strbytelen (line);
    line = substr (line, 1, col) + char (chr) + substr (line, col + 2, - 1);
    cf_.lins[cf_.ptr[0] - cf_.rows[0]] = line;
    cf_.lines[i] = line;
    cf_.st_.st_size += strbytelen (line);
    set_modified ();
    waddline (getlinestr (line, 1), 0, cf_.ptr[0]);
    draw_tail ();
    }
}

private define del_chr ()
{
  variable
    col = cf_._index,
    i = v_lnr ('.'),
    line = v_lin ('.'),
    len = strlen (line);

  if ((0 == cf_.ptr[1] - cf_._indent && 'X' == cf_._chr) || 0 > len - cf_._indent)
    return;
 
  if (any (['x', keys->rmap.delete] == cf_._chr))
    {
    REG["\""] = substr (line, col + 1, 1);
    line = substr (line, 1, col) + substr (line, col + 2, - 1);
    if (cf_._index == strlen (line))
      {
      cf_.ptr[1]--;
      cf_._index--;
      }
    }
  else
    if (0 < cf_.ptr[1] - cf_._indent)
      {
      REG["\""] = substr (line, col, 1);
      line = substr (line, 1, col - 1) + substr (line, col + 1, - 1);
      cf_.ptr[1]--;
      cf_._index--;
      }
 
  ifnot (strlen (line))
    line = sprintf ("%s ", repeat (" ", cf_._indent));

  if (cf_.ptr[1] - cf_._indent < 0)
    cf_.ptr[1] = cf_._indent;

  cf_.lins[cf_.ptr[0] - cf_.rows[0]] = line;
  cf_.lines[i] = line;

  cf_.st_.st_size = calcsize (cf_.lines);
 
  set_modified ();
 
  waddline (getlinestr (line, 1), 0, cf_.ptr[0]);
 
  draw_tail ();
}

private define del ()
{
  variable chr = getch ();
 
  if (any (['d', 'w', 'W'] == chr))
    {
    if ('d' == chr)
      {
      if (1 == del_line ())
        return;

      cf_.draw ();
      return;
      }
 
    if ('w' == chr)
      {
      del_word ('w');
      return;
      }

    if ('W' == chr)
      {
      del_word ('W');
      return;
      }
 
    }
}

private define del_to_end ()
{
  variable
    col = cf_._index,
    i = v_lnr ('.'),
    line = v_lin ('.'),
    len = strlen (line);
 
  if (cf_._index == len)
    return;
 
  ifnot (cf_.ptr[1] - cf_._indent)
    {
    if (strlen (line))
      REG["\""] = line;

    line = repeat (" ", cf_._indent);
    ifnot (strlen (line))
      line = " ";
 
    cf_.ptr[1] = cf_._indent;
    cf_._index = cf_._indent;

    cf_.lines[i] = line;
    cf_.lins[cf_.ptr[0] - cf_.rows[0]] = line;
 
    set_modified ();

    cf_.st_.st_size = calcsize (cf_.lines);

    waddline (getlinestr (line, 1), 0, cf_.ptr[0]);

    draw_tail ();

    return;
    }
 
  variable reg = substr (line, col, -1);
  if (strlen (line))
    REG["\""] = reg;

  line = substr (line, 1, col);

  cf_.lins[cf_.ptr[0] - cf_.rows[0]] = line;
  cf_.lines[i] = line;
 
  cf_.st_.st_size = calcsize (cf_.lines);

  cf_.ptr[1]--;
  cf_._index--;

  set_modified ();

  waddline (getlinestr (line, 1), 0, cf_.ptr[0]);

  draw_tail ();
}

private define edit_line ()
{
  variable
    prev_l,
    next_l,
    lline,
    lnr = v_lnr ('.'),
    line = v_lin ('.'),
    len = strlen (line);

  ifnot (lnr)
    prev_l = "";
  else
    prev_l = v_lin (cf_.ptr[0] - 1);

  if (lnr == cf_._len)
    next_l = "";
  else
    next_l = cf_.lines[lnr + 1];
 
  if ('C' == cf_._chr)
    line = substr (line, 1, cf_._index);
  else if ('a' == cf_._chr && len)
    {
    cf_._index++;
    cf_.ptr[1]++;
    }
  else if ('A' == cf_._chr)
    {
    cf_._index = len;
    cf_.ptr[1] = len;
    }
 
  if (cf_._index - cf_._indent > cf_._maxlen)
    lline = getlinestr (line, cf_._findex + 1);
  else
    lline = getlinestr (line, 1);
  
  if (strlen (lline))
    {
    waddline (lline, 0, cf_.ptr[0]);
    smg->refresh ();
    }

  if ('C' == cf_._chr)
    insert (&line, lnr, prev_l, next_l;modified);
  else
    insert (&line, lnr, prev_l, next_l);
}

private define newline ()
{
  variable
    dir = cf_._chr == 'O' ? "prev" : "next",
    prev_l,
    next_l,
    col = cf_._index,
    lnr = v_lnr ('.'),
    line = v_lin ('.'),
    len = strlen (line);

    if ("prev" == dir)
      ifnot (lnr)
        prev_l = "";
      else
        prev_l = v_lin (cf_.ptr[0] - 1);
    else
      prev_l = line;
 
  if ("prev" == dir)
    next_l = line;
  else
    if (lnr == cf_._len)
      next_l = "";
    else
      next_l = v_lin (cf_.ptr[0] + 1);
 
  cf_._len++;

  if (0 == lnr && "prev" == dir)
    cf_.lines = [repeat (" ", newline_str (cf_)), cf_.lines];
  else
    cf_.lines = [cf_.lines[[:"next" == dir ? lnr : lnr - 1]], newline_str (cf_),
      cf_.lines[["next" == dir ? lnr + 1 : lnr:]]];

  cf_._i = lnr == 0 ? 0 : cf_._ii;
 
  if ("next" == dir)
    if (cf_.ptr[0] == cf_.rows[-2] && cf_.ptr[0] + 1 > cf_._avlins)
      cf_._i++;
    else
      cf_.ptr[0]++;

  cf_.ptr[1] = cf_._indent + (cf_._autoindent ? cf_._shiftwidth : 0);
  cf_._index = cf_._indent + (cf_._autoindent ? cf_._shiftwidth : 0);
  cf_._findex = cf_._indent + (cf_._autoindent ? cf_._shiftwidth : 0);
 
  cf_.draw (;dont_draw);
 
  line = newline_str (cf_);
  insert (&line, "next" == dir ? lnr + 1 : lnr, prev_l, next_l;;__qualifiers ());
}

private define Put ()
{
  ifnot (assoc_key_exists (REG, "\""))
    return;

  variable
    lines = strchop (REG["\""], '\n', 0),
    lnr = v_lnr ('.');

  if ('\n' == REG["\""][-1])
    {
    lines = lines[[:-2]];
    ifnot (lnr)
      cf_.lines = [lines, cf_.lines];
    else
      cf_.lines = [cf_.lines[[:lnr - 1]], lines, cf_.lines[[lnr:]]];

    cf_._len += length (lines);
    }
  else
    cf_.lines[lnr] = substr (cf_.lines[lnr], 1, cf_._index) + strjoin (lines) +
      substr (cf_.lines[lnr], cf_._index + 1, -1);

  cf_._i = lnr == 0 ? 0 : cf_._ii;
 
  cf_.st_.st_size = calcsize (cf_.lines);
 
  set_modified ();
 
  cf_.draw ();
}

private define put ()
{
  ifnot (assoc_key_exists (REG, "\""))
    return;

  variable
    lines = strchop (REG["\""], '\n', 0),
    lnr = v_lnr ('.');

  if ('\n' == REG["\""][-1])
    {
    lines = lines[[:-2]];
    cf_.lines = [cf_.lines[[:lnr]], lines, cf_.lines[[lnr + 1:]]];
    cf_._len += length (lines);
    }
  else
    cf_.lines[lnr] = substr (cf_.lines[lnr], 1, cf_._index + 1) + strjoin (lines) +
      substr (cf_.lines[lnr], cf_._index + 2, -1);

  cf_._i = lnr == 0 ? 0 : cf_._ii;
 
  cf_.st_.st_size = calcsize (cf_.lines);
 
  set_modified ();
 
  cf_.draw ();
}

private define toggle_case ()
{
  variable
    func,
    col = cf_._index,
    i = v_lnr ('.'),
    line = v_lin ('.'),
    chr = substr (line, col + 1, 1);

  chr = decode (chr)[0];

  func = islower (chr) ? &toupper : &tolower;

  chr = char ((@func) (chr));
 
  cf_.st_.st_size -= strbytelen (line);
  line = substr (line, 1, col) + chr + substr (line, col + 2, - 1);
  cf_.lins[cf_.ptr[0] - cf_.rows[0]] = line;
  cf_.lines[i] = line;
  cf_.st_.st_size += strbytelen (line);
  set_modified ();
 
  waddline (getlinestr (line, 1), 0, cf_.ptr[0]);

  if (cf_._index - cf_._indent == v_linlen (cf_.ptr[0]) - 1)
    draw_tail ();
  else
    (@pagerf[string ('l')]);
}

pagerf[string ('~')] = &toggle_case;
pagerf[string ('P')] = &Put;
pagerf[string ('p')] = &put;
pagerf[string ('o')] = &newline;
pagerf[string ('O')] = &newline;
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

