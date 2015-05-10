private variable
  col,
  lnr,
  found,
  search_type,
  histindex = NULL,
  history = {};

private define exit_rout ()
{
  smg->setrcdr (cf_.ptr[0], cf_.ptr[1]);
  send_msg (" ", 0);
  waddlinear ([" "], [0], [PROMPTROW], [0], COLUMNS);
  draw_tail ();
}

private define search_backward (str)
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
    line = getlinestr (cf_.lines[i], 1);
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
      clrs = [0, 0, PROMPTCLR, 0];

      pos = [qualifier ("row", PROMPTROW),  col];
      if (qualifier_exists ("context"))
        pos[1] = match[1];

      waddlinear_dr (ar, clrs, rows, cols, pos, COLUMNS);

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
          i = cf_._len;
          wrapped = 1;
          }
      else
        i--;
    }
 
  found = 0;
  send_msg_dr ("Nothing found", 0, PROMPTROW, col);
}

private define search_forward (str)
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
 
  while (i <= cf_._len || (i < lnr && wrapped))
    {
    line = getlinestr (cf_.lines[i], 1);
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
      clrs = [0, 0, PROMPTCLR, 0];

      pos = [qualifier ("row", PROMPTROW),  col];
      if (qualifier_exists ("context"))
        pos[1] = match[1];
 
      waddlinear_dr (ar, clrs, rows, cols, pos, COLUMNS);

      lnr = i;
      found = 1;
      return;
      }
    else
      if (i == cf_._len)
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

private define search ()
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

  lnr = v_lnr ('.');
 
  origlnr = lnr;

  type = keys->BSLASH == cf_._chr ? "forward" : "backward";
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
      exit_rout ();
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
 
    if (any (chr == keys->rmap.changelang))
      {
      getchar_lang = string (getchar_lang) == "&en_getch" ? input->get_el_lang : getchar_lang;
      topline (" -- PAGER --");
      smg->setrcdr (PROMPTROW, col);
      continue;
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

        cf_._i = lnr;
        cf_.ptr[0] = cf_.rows[0];
        cf_.ptr[1] = cf_._indent;
        cf_._index = cf_._indent;
        cf_._findex = cf_._indent;

        cf_.draw ();
        }

      exit_rout ();
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
        (@typesearch) (pat);
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
        (@typesearch) (pat);
        continue;
        }

    if (chr == keys->CTRL_n)
      {
      if (type == "forward")
        if (lnr == cf_._len)
          lnr = 0;
        else
          lnr++;
      else
        ifnot (lnr)
          lnr = cf_._len;
        else
          lnr--;

      (@typesearch) (pat);
      }

    str = pchr + pat;
    write_prompt (str, col);

    if (dothesearch)
      (@typesearch) (pat);
    }
}

private define search_word ()
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
    line = v_lin ('.');
 
  lnr = v_lnr ('.');

  type = '*' == cf_._chr ? "forward" : "backward";
 
  typesearch = type == "forward" ? &search_forward : &search_backward;

  if (type == "forward")
    if (lnr == cf_._len)
      lnr = 0;
    else
      lnr++;
  else
    if (lnr == 0)
      lnr = cf_._len;
    else
      lnr--;

  col = cf_._index;
  lcol = col;

  if (isblank (substr (line, lcol + 1, 1)))
    return;
 
  pat = find_word (line, lcol, &start, &end);

  if (col - cf_._indent)
    pat = "\\W+" + pat;
  else
    pat = "^" + pat;

  if (cf_._index < v_linlen ('.'))
    pat += "\\W";

  (@typesearch) (pat;row = MSGROW, context);

  forever
    {
    ifnot (found)
      {
      exit_rout ();
      return;
      }

    chr = getch ();
 
    ifnot (any ([keys->CTRL_n, 033, '\r'] == chr))
      continue;

    if (033 == chr)
      {
      exit_rout ();
      break;
      }
 
    if ('\r' == chr)
      {
      if (found)
        {
        list_insert (history, pat);
        if (NULL == histindex)
          histindex = 0;

        cf_._i = lnr;
        cf_.ptr[0] = cf_.rows[0];
        cf_.ptr[1] = cf_._indent;
        cf_._index = cf_._indent;
        cf_._findex = cf_._indent;
        cf_.draw ();
        }

      exit_rout ();
      return;
      }
 
    if (chr == keys->CTRL_n)
      {
      if (type == "forward")
        if (lnr == cf_._len)
          lnr = 0;
        else
          lnr++;
      else
        ifnot (lnr)
          lnr = cf_._len;
        else
          lnr--;

      (@typesearch) (pat;row = MSGROW, context);
      }
    }
}

pagerf[string ('#')] = &search_word;
pagerf[string ('*')] = &search_word;
pagerf[string (keys->BSLASH)] = &search;
pagerf[string (keys->QMARK)] = &search;
