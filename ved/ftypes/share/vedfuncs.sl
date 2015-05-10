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

define debug (str, get)
{
  send_msg_dr (str, 1, cf_.ptr[0], cf_.ptr[1]);
  ifnot (NULL == get)
    () = getch ();
}

define set_img ()
{
  variable i;
  IMG = List_Type[PROMPTROW];
  _for i (1, length (IMG) - 1)
    IMG[i] = {" ", 0, i, 0};
  IMG[0] = {strftime ("%c"), 3, 0, 0};
}

define clear (frow, lrow)
{
  variable
    len = lrow - frow + 1,
    ar = String_Type[len],
    cols = Integer_Type[len],
    clrs = Integer_Type[len],
    rows = [frow:lrow],
    pos = [cf_.ptr[0], cf_.ptr[1]];
 
  ar[*] = " ";
  cols[*] = 0;
  clrs[*] = 0;
 
  waddlinear_dr (ar, clrs, rows, cols, pos, COLUMNS);
}

define restore (cmp_lnrs, pos)
{
  variable
    i,
    ar = String_Type[0],
    rows = Integer_Type[0],
    clrs = Integer_Type[0],
    cols = Integer_Type[0];

  if (length (cmp_lnrs) == length (IMG))
    _for i (0, length (IMG) - 1)
      {
      ar = [ar, IMG[i][0]];
      clrs = [clrs, IMG[i][1]];
      rows = [rows, IMG[i][2]];
      cols = [cols, IMG[i][3]];
      }
  else if (length (cmp_lnrs) > length (IMG))
      {
      _for i (0, length (IMG) - 1)
        {
        ar = [ar, IMG[i][0]];
        clrs = [clrs, IMG[i][1]];
        rows = [rows, IMG[i][2]];
        cols = [cols, IMG[i][3]];
        }

      _for i (i + 1, length (cmp_lnrs) - 1)
        {
        ar = [ar, repeat (" ", COLUMNS)];
        clrs = [clrs, 0];
        rows = [rows, rows[-1] + 1];
        cols = [cols, 0];
        }
      }
  else
    _for i (length (IMG) - length (cmp_lnrs), length (IMG) - 1)
      {
      ar = [ar, IMG[i][0]];
      clrs = [clrs, IMG[i][1]];
      rows = [rows, IMG[i][2]];
      cols = [cols, IMG[i][3]];
      }
 
  waddlinear_dr (ar, clrs, rows, cols, pos, COLUMNS);
}

private define _topline_ (str)
{
  variable t = strftime ("[%a %d %b %I:%M:%S]");
  @str += sprintf (" ftype (%s) LANG (%s) ", cf_._type,
    string (getchar_lang) == "&en_getch" ? "US" : "EL");
  @str + repeat (" ", COLUMNS - strlen (@str) - strlen (t)) + t;
}

define topline_dr (str)
{
  _topline_ (&str);
  waddlineat_dr (str, 16, 0, 0, [cf_.ptr[0], cf_.ptr[1]], COLUMNS);
}

define topline (str)
{
  _topline_ (&str);
  waddlineat (str, 16, 0, 0, COLUMNS);
}

define write_prompt (str, col)
{
  waddlineat_dr (str, PROMPTCLR, PROMPTROW, 0, [qualifier ("row", PROMPTROW), col], COLUMNS);
}

define decode (str)
{
  variable
    d,
    i = 0,
    l = {};

  forever
    {
    (i, d) = strskipchar (str, i);
    if (d)
      list_append (l, d);
    else
      break;
    }

  return length (l) ? list_to_array (l) : ['\n'];
}

define calcsize (ar)
{
  return int (sum (strbytelen (ar)) + length (ar));
}

define v_linlen (r)
{
  r = (r == '.' ? cf_.ptr[0] : r) - cf_.rows[0];
  return strlen (cf_.lins[r]) - cf_._indent;
}

define v_lin (r)
{
  r = (r == '.' ? cf_.ptr[0] : r) - cf_.rows[0];
  return cf_.lins[r];
}

define v_lnr (r)
{
  r = (r == '.' ? cf_.ptr[0] : r) - cf_.rows[0];
  return cf_.lnrs[r];
}

%define tail ()
%{
%  variable
%    lnr = v_lnr ('.') + 1,
%    line = v_lin ('.');
%
%  return sprintf (
%    "[find %d) (ind %d) ptr1 %d len (%d), linlen %d, maxlen %d chr %d",
%    cf_._findex, cf_._index,  cf_.ptr[1], v_linlen ('.'), cf_._linlen, cf_._maxlen,
%    qualifier ("chr", decode (substr (line, cf_._index + 1, 1))[0]),
%    );
%}

define tail ()
{
  variable
    lnr = v_lnr ('.') + 1,
    line = v_lin ('.');
 
  return sprintf (
    "[%s] (row %d) (col %d) (linenr %d/%d %.0f%%) (strlen %d) chr (%d), undo (%d/%d)",
    path_basename (cf_._fname), cf_.ptr[0], cf_.ptr[1] - cf_._indent + 1, lnr,
    cf_._len + 1, (100.0 / cf_._len) * lnr, v_linlen ('.'),
    qualifier ("chr", decode (substr (line, cf_._index + 1, 1))[0]),
    cf_._undolevel, length (cf_.undo));
}

define draw_tail ()
{
  if (is_wrapped_line)
    smg->hlregion (1, cf_.ptr[0], COLUMNS - 2, 1, 2);
 
  waddlineat_dr (tail (;;__qualifiers ()), INFOCLRFG, cf_.rows[-1], 0, [cf_.ptr[0], cf_.ptr[1]],
    COLUMNS);
}

define getlinestr (line, ind)
{
  return substr (line, ind + cf_._indent, cf_._linlen);
}

define find_word (line, col, start, end)
{
  variable wchars = [['0':'9'], ['a':'z'], ['A':'Z'], [913:929:1],
    [931:937:1], [945:969:1], '_'];

  wchars = array_map (String_Type, &char, wchars);

  ifnot (col - cf_._indent)
    @start = cf_._indent;
  else
    {
    while (col--, col >= cf_._indent && any (wchars == substr (line, col + 1, 1)));

    @start = col + 1;
    }
 
  variable len = strlen (line);

  while (col++, col < len && any (wchars == substr (line, col + 1, 1)));
 
  @end = col - 1;
 
  return substr (line, @start + 1, @end - @start + 1);
}

define find_Word (line, col, start, end)
{
  ifnot (col - cf_._indent)
    @start = cf_._indent;
  else
    {
    while (col--, col >= cf_._indent && 0 == isblank (substr (line, col + 1, 1)));

    @start = col + 1;
    }
 
  variable len = strlen (line);

  while (col++, col < len && 0 == isblank (substr (line, col + 1, 1)));
 
  @end = col - 1;
 
  return substr (line, @start + 1, @end - @start + 1);
}

