private variable
  col,
  lnr,
  found,
  search_type,
  histindex = NULL,
  history = {};

private define exit_rout (s)
{
  smg->setrcdr (s.ptr[0], s.ptr[1]);
  send_msg (" ", 0);
  smg->atrcaddnstr (" ", 0, PROMPTROW, 0, COLUMNS);

  draw_tail (s);
}

private define search_backward (s, str)
{
  variable
    i,
    ar,
    pat,
    pos,
    cols,
    match,
    line,
    wrapped = 0,
    clrs = Integer_Type[0],
    rows = Integer_Type[4];
 
  rows[*] = MSGROW;

  try
    {
    pat = pcre_compile (str, PCRE_UTF8);
    }
  catch ParseError:
    {
    send_msg_dr ("error compiling pcre pattern", 1, PROMPTROW, col);
    return;
    }
 
  i = lnr;

  while (i > -1 || (i > lnr && wrapped))
    {
    line = getlinestr (s, s.lines[i], 1);
    if (pcre_exec (pat, line))
      {
      match = pcre_nth_match (pat, 0);
      ar = [
        sprintf ("row %d|", i + 1),
        substrbytes (line, 1, match[0]),
        substrbytes (line, match[0] + 1, match[1] - match[0]),
        substrbytes (line, match[1] + 1, -1)];
      cols = strlen (ar[[:-2]]);
      cols = [0, array_map (Integer_Type, &int, cumsum (cols))];
      clrs = [0, 0, VED_PROMPTCLR, 0];

      pos = [qualifier ("row", PROMPTROW),  col];
      if (qualifier_exists ("context"))
        pos[1] = match[1];

      smg->aratrcaddnstrdr (ar, clrs, rows, cols, pos[0], pos[1], COLUMNS);

      lnr = i;
      found = 1;
      return;
      }
    else
      ifnot (i)
        if (wrapped)
          break;
        else
          {
          i = s._len;
          wrapped = 1;
          }
      else
        i--;
    }
 
  found = 0;
  send_msg_dr ("Nothing found", 0, PROMPTROW, col);
}

private define search_forward (s, str)
{
  variable
    i,
    ar,
    pat,
    pos,
    cols,
    match,
    line,
    wrapped = 0,
    clrs = Integer_Type[0],
    rows = Integer_Type[4];
 
  rows[*] = MSGROW;

  try
    {
    pat = pcre_compile (str, PCRE_UTF8);
    }
  catch ParseError:
    {
    send_msg_dr ("error compiling pcre pattern", 1, PROMPTROW, col);
    return;
    }
 
  i = lnr;
 
  while (i <= s._len || (i < lnr && wrapped))
    {
    line = getlinestr (s, s.lines[i], 1);
    if (pcre_exec (pat, line))
      {
      match = pcre_nth_match (pat, 0);
      ar = [
        sprintf ("row %d|", i + 1),
        substrbytes (line, 1, match[0]),
        substrbytes (line, match[0] + 1, match[1] - match[0]),
        substrbytes (line, match[1] + 1, -1)];
      cols = strlen (ar[[:-2]]);
      cols = [0, array_map (Integer_Type, &int, cumsum (cols))];
      clrs = [0, 0, VED_PROMPTCLR, 0];

      pos = [qualifier ("row", PROMPTROW),  col];
      if (qualifier_exists ("context"))
        pos[1] = match[1];
 
      smg->aratrcaddnstrdr (ar, clrs, rows, cols, pos[0], pos[1], COLUMNS);

      lnr = i;
      found = 1;
      return;
      }
    else
      if (i == s._len)
        if (wrapped)
          break;
        else
          {
          i = 0;
          wrapped = 1;
          }
      else
        i++;
    }
 
  found = 0;
  send_msg_dr ("Nothing found", 0, PROMPTROW, col);
}

private define search (s)
{
  variable
    origlnr,
    dothesearch,
    type,
    typesearch,
    chr,
    pchr,
    str,
    pat = "";
 
  found = 0;

  lnr = v_lnr (s, '.');
 
  origlnr = lnr;

  type = keys->BSLASH == s._chr ? "forward" : "backward";
  pchr = type == "forward" ? "/" : "?";
  str = pchr;
  col = 1;
 
  typesearch = type == "forward" ? &search_forward : &search_backward;
  write_prompt (str, col);
 
  forever
    {
    dothesearch = 0;
    chr = getch ();

    if (033 == chr)
      {
      exit_rout (s);
      break;
      }
 
    if ((' ' <= chr < 64505) &&
        0 == any (chr == [keys->rmap.backspace, keys->rmap.delete,
        [keys->UP:keys->RIGHT], [keys->F1:keys->F12]]))
      {
      if (col == strlen (pat) + 1)
        pat += char (chr);
      else
        pat = substr (pat, 1, col - 1) + char (chr) + substr (pat, col, -1);

      col++;
      dothesearch = 1;
      }
 
    if (any (chr == keys->rmap.backspace) && strlen (pat))
      if (col - 1)
        {
        if (col == strlen (pat) + 1)
          pat = substr (pat, 1, strlen (pat) - 1);
        else
          pat = substr (pat, 1, col - 2) + substr (pat, col, -1);
 
        lnr = origlnr;

        col--;
        dothesearch = 1;
        }

    if (any (chr == keys->rmap.delete) && strlen (pat))
      {
      ifnot (col - 1)
        (pat = substr (pat, 2, -1), dothesearch = 1);
      else if (col != strlen (pat) + 1)
        (pat = substr (pat, 1, col - 1) + substr (pat, col + 1, -1),
         dothesearch = 1);
      }
 
    if (any (chr == keys->rmap.left) && col != 1)
      col--;
 
    if (any (chr == keys->rmap.right) && col != strlen (pat) + 1)
      col++;
 
    if ('\r' == chr)
      {
      if (found)
        {
        list_insert (history, pat);
        if (NULL == histindex)
          histindex = 0;

        s._i = lnr;
        s.ptr[0] = s.rows[0];
        s.ptr[1] = s._indent;
        s._index = s._indent;
        s._findex = s._indent;

        s.draw ();
        }

      exit_rout (s);
      break;
      }
 
    if (chr == keys->UP)
      ifnot (NULL == histindex)
        {
        pat = history[histindex];
        if (histindex == length (history) - 1)
          histindex = 0;
        else
          histindex++;

        col = strlen (pat) + 1;
        str = pchr + pat;
        write_prompt (str, col);
        (@typesearch) (s, pat);
        continue;
        }

    if (chr == keys->DOWN)
      ifnot (NULL == histindex)
        {
        pat = history[histindex];
        ifnot (histindex)
          histindex = length (history) - 1;
        else
          histindex--;

        col = strlen (pat) + 1;
        str = pchr + pat;
        write_prompt (str, col);
        (@typesearch) (s, pat);
        continue;
        }

    if (chr == keys->CTRL_n)
      {
      if (type == "forward")
        if (lnr == s._len)
          lnr = 0;
        else
          lnr++;
      else
        ifnot (lnr)
          lnr = s._len;
        else
          lnr--;

      (@typesearch) (s, pat);
      }

    str = pchr + pat;
    write_prompt (str, col);

    if (dothesearch)
      (@typesearch) (s, pat);
    }
}

private define on_lang_change (col)
{
  topline (" -- pager --");
  smg->setrcdr (PROMPTROW, col);
}
 
private define search_word (s)
{
  variable
    str,
    pat,
    end,
    chr,
    lcol,
    type,
    start,
    origlnr,
    typesearch,
    line = v_lin (s, '.');
 
  found = 0;

  lnr = v_lnr (s, '.');

  type = '*' == s._chr ? "forward" : "backward";
 
  typesearch = type == "forward" ? &search_forward : &search_backward;

  if (type == "forward")
    if (lnr == s._len)
      lnr = 0;
    else
      lnr++;
  else
    if (lnr == 0)
      lnr = s._len;
    else
      lnr--;

  col = s._index;
  lcol = col;

  if (isblank (substr (line, lcol + 1, 1)))
    return;
 
  pat = find_word (s, line, lcol, &start, &end);

  if (col - s._indent)
    pat = "\\W+" + pat;
  else
    pat = "^" + pat;

  if (s._index < v_linlen (s, '.'))
    pat += "\\W";

  (@typesearch) (s, pat;row = MSGROW, context);

  forever
    {
    ifnot (found)
      {
      exit_rout (s);
      return;
      }

    chr = getch (;on_lang = &on_lang_change, on_lang_args = col);
 
    ifnot (any ([keys->CTRL_n, 033, '\r'] == chr))
      continue;

    if (033 == chr)
      {
      exit_rout (s);
      break;
      }
 
    if ('\r' == chr)
      {
      if (found)
        {
        list_insert (history, pat);
        if (NULL == histindex)
          histindex = 0;

        s._i = lnr;
        s.ptr[0] = s.rows[0];
        s.ptr[1] = s._indent;
        s._index = s._indent;
        s._findex = s._indent;
        s.draw ();
        }

      exit_rout (s);
      return;
      }
 
    if (chr == keys->CTRL_n)
      {
      if (type == "forward")
        if (lnr == s._len)
          lnr = 0;
        else
          lnr++;
      else
        ifnot (lnr)
          lnr = s._len;
        else
          lnr--;

      (@typesearch) (s, pat;row = MSGROW, context);
      }
    }
}

VED_PAGER[string ('#')] = &search_word;
VED_PAGER[string ('*')] = &search_word;
VED_PAGER[string (keys->BSLASH)] = &search;
VED_PAGER[string (keys->QMARK)] = &search;
