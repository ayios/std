loadfrom ("string", "decode", NULL, &on_eval_err);
loadfrom ("array", "getsize", NULL, &on_eval_err);

define getlines (fname, indent, st)
{
  indent = repeat (" ", indent);
  if (-1 == access (fname, F_OK) || 0 == st.st_size)
    {
    st.st_size = 0;
    return [sprintf ("%s\000", indent)];
    }

  return array_map (String_Type, &sprintf, "%s%s", indent, readfile (fname));
}

define clear (s, frow, lrow)
{
  variable
    len = lrow - frow + 1,
    ar = String_Type[len],
    cols = Integer_Type[len],
    clrs = Integer_Type[len],
    rows = [frow:lrow],
    pos = [s.ptr[0], s.ptr[1]];
 
  ar[*] = " ";
  cols[*] = 0;
  clrs[*] = 0;
 
  smg->aratrcaddnstrdr (ar, clrs, rows, cols, pos[0], pos[1], COLUMNS);
}

define write_prompt (str, col)
{
  smg->atrcaddnstrdr (str, VED_PROMPTCLR, PROMPTROW, 0, qualifier ("row", PROMPTROW), col, COLUMNS);
}

define v_linlen (s, r)
{
  r = (r == '.' ? s.ptr[0] : r) - s.rows[0];
  return strlen (s.lins[r]) - s._indent;
}

define v_lin (s, r)
{
  r = (r == '.' ? s.ptr[0] : r) - s.rows[0];
  return s.lins[r];
}

define v_lnr (s, r)
{
  r = (r == '.' ? s.ptr[0] : r) - s.rows[0];
  return s.lnrs[r];
}

define tail (s)
{
  variable
    lnr = v_lnr (s, '.') + 1,
    line = v_lin (s, '.');
 
  return sprintf (
    "[%s] (row %d) (col %d) (linenr %d/%d %.0f%%) (strlen %d) chr (%d), undo (%d/%d)",
    path_basename (s._fname), s.ptr[0], s.ptr[1] - s._indent + 1, lnr,
    s._len + 1, (100.0 / s._len) * (lnr - 1), v_linlen (s, '.'),
    qualifier ("chr", decode (substr (line, s._index + 1, 1))[0]),
    s._undolevel, length (s.undo));
}

define draw_tail (s)
{
  if (s._is_wrapped_line)
    smg->hlregion (1, s.ptr[0], COLUMNS - 2, 1, 2);
 
  smg->atrcaddnstrdr (tail (s;;__qualifiers ()), VED_INFOCLRFG, s.rows[-1], 0, s.ptr[0], s.ptr[1],
    COLUMNS);
}

define getlinestr (s, line, ind)
{
  return substr (line, ind + s._indent, s._linlen);
}

define fpart_of_word (s, line, col, start)
{
  ifnot (strlen (line))
    return "";

  variable origcol = col;

  ifnot (col - s._indent)
    @start = s._indent;
  else
    {
    while (col--, col >= s._indent && any (WCHARS == substr (line, col + 1, 1)));

    @start = col + 1;
    }
 
  return substr (line, @start + 1, origcol - @start + 1);
}

define find_word (s, line, col, start, end)
{
  ifnot (col - s._indent)
    @start = s._indent;
  else
    {
    while (col--, col >= s._indent && any (WCHARS == substr (line, col + 1, 1)));

    @start = col + 1;
    }
 
  variable len = strlen (line);

  while (col++, col < len && any (WCHARS == substr (line, col + 1, 1)));
 
  @end = col - 1;
 
  return substr (line, @start + 1, @end - @start + 1);
}

define find_Word (s, line, col, start, end)
{
  ifnot (col - s._indent)
    @start = s._indent;
  else
    {
    while (col--, col >= s._indent && 0 == isblank (substr (line, col + 1, 1)));

    @start = col + 1;
    }
 
  variable len = strlen (line);

  while (col++, col < len && 0 == isblank (substr (line, col + 1, 1)));
 
  @end = col - 1;
 
  return substr (line, @start + 1, @end - @start + 1);
}


define drawfile (s)
{
  variable st = lstat_file (s._absfname);
  
  if (s.st_.st_size)
    if (st.st_atime == s.st_.st_atime && st.st_size == s.st_.st_size)
      {
      s.draw ();
      return;
      }

  s.st_ = st;
 
  s.lines = getlines (s, s._absfname, s._indent, st);

  s._len = length (s.lines) - 1;
 
  variable _i = qualifier ("_i");
  variable pos = qualifier ("pos");
  variable len = length (s.rows) - 1;

  ifnot (NULL == pos)
    (s.ptr[0] = pos[0], s.ptr[1] = pos[1]);
  else
    (s.ptr[1] = 0, s.ptr[0] = s._len + 1 <= len ? s._len + 1 : s.rows[-2]);
  
  ifnot (NULL == _i)
    s._i = _i;
  else  
    s._i = s._len + 1 <= len ? 0 : s._len + 1 - len;

  s.draw ();
}
