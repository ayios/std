loadfrom ("dir", "evaldir", NULL, &on_eval_err);

rlf_ = struct
  {
  init,
  read,
  rout,
  clear,
  prompt,
  hlitem,
  formar,
  getline,
  printout,
  fnamecmp,
  execline,
  delete_at,
  insert_at,
  parse_args,
  w_comp_rout,
  appendslash,
  listdirectory,
  firstindices,
  };

private define quit ()
{
  if (cf_._flags & RDONLY || 0 == cf_._flags & MODIFIED ||
      (0 == qualifier_exists ("force") && "q!" == rl_.argv[0]))
    cf_.quit (0);
 
  send_msg_dr ("file is modified, save changes? y[es]|n[o]", 0, NULL, NULL);

  variable chr = getch ();
  while (0 == any (chr == ['y', 'n']))
    chr = getch ();

  cf_.quit (chr == 'y');
}

private define write_file ()
{
  variable
    file,
    args = __pop_list (_NARGS);
 
  ifnot (length (args))
    {
    if (cf_._flags & RDONLY)
      {
      send_msg_dr ("file is read only", 1, cf_.ptr[0], cf_.ptr[1]);
      return;
      }

    file = cf_._fname;
    }
  else
    {
    file = args[0];
    ifnot (access (file, F_OK))
      {
      if ("w" == rl_.argv[0])
        {
        send_msg_dr ("file exists, w! to overwrite, press any key to continue", 1,
          NULL, NULL);
        () = getch ();
        send_msg_dr (" ", 0, cf_.ptr[0], cf_.ptr[1]);
        return;
        }

      if (-1 == access (file, W_OK))
        {
        send_msg_dr ("file is not writable, press any key to continue", 1,
          NULL, NULL);
        () = getch ();
        send_msg_dr (" ", 0, cf_.ptr[0], cf_.ptr[1]);
        return;
        }
      }
    }
 
  variable retval = writetofile (file, cf_.lines, cf_._indent);
 
  ifnot (0 == retval)
    {
    send_msg_dr (sprintf ("%s, press any key to continue", errno_string (retval)), 1,
      NULL, NULL);
    () = getch ();
    send_msg_dr (" ", 0, cf_.ptr[0], cf_.ptr[1]);
    return;
    }
 
  if (file == cf_._fname)
    cf_._flags = cf_._flags & ~MODIFIED;
}

private define write_quit ()
{
  variable args = __pop_list (_NARGS);
  cf_.quit (1, __push_list (args));
}

private define edit_other ()
{
  ifnot (_NARGS)
    return;

%  variable key = get_bufkey ();
%  BUFFERS[key] = @Ved_Type;
%  BUFFERS[key]._fd = VED_SOCKET;
%  BUFFERS[key]._state = IDLED;
%  BUFFERS[key].cf_ = @cf_;
%  BUFFERS[key].draw = cf_.draw;
%  BUFFERS[key].vedloop = vedloop;
%  variable args = __pop_list (_NARGS);
%  variable fn = args[0];
%  add_buffer (fn);
%  debug (key, 1);
}

clinef["w"] = &write_file;
clinef["w!"] = &write_file;
clinef["q"] = &quit;
clinef["q!"] = &quit;
clinef["wq"] = &write_quit;
clinef["e"] = &edit_other;

clinec = assoc_get_keys (clinef);

private define init (s)
{
  rl_ = @Rline_Type;
  rl_._col = 1;
  rl_._lin = ":";
  rl_._row = PROMPTROW;
  rl_._ind = 0;
  rl_.lnrs = [rl_._row];
  rl_.argv = [""];
  rl_.com = @clinec;
}

rlf_.init = &init;

private define delete_at (s)
{
  variable
    i,
    arglen,
    len = 0;

  ifnot (qualifier_exists ("is_delete"))
    rl_._col--;
 
  _for i (0, rl_._ind)
    {
    arglen = strlen (rl_.argv[i]);
    len += arglen + 1;
    }
 
  len = rl_._col - (len - arglen);

  if (0 > len)
    {
    if (arglen)
      rl_.argv[i-1] += rl_.argv[i];
 
    rl_.argv[i] = NULL;
    rl_.argv = rl_.argv[wherenot (_isnull (rl_.argv))];
    }
  else
    ifnot (len)
      rl_.argv[i] = substr (rl_.argv[i], 2, -1);
    else
      if (len + 1 == arglen)
        rl_.argv[i] = substr (rl_.argv[i], 1, len);
      else
        rl_.argv[i] = substr (rl_.argv[i], 1, len) +
          substr (rl_.argv[i], len + 2, -1);
}

rlf_.delete_at = &delete_at;

private define routine (s)
{
  if (any (keys->rmap.backspace == rl_._chr))
    {
    if (rl_._col > 1)
      rlf_.delete_at ();
 
    return;
    }

  if (any (keys->rmap.left == rl_._chr))
    {
    if (rl_._col > 1)
      {
      rl_._col--;
      smg->setrcdr (rl_._row, rl_._col);
      }

    return;
    }

  if (any (keys->rmap.right == rl_._chr))
    {
    if (rl_._col < strlen (rl_._lin))
      {
      rl_._col++;
      smg->setrcdr (rl_._row, rl_._col);
      }

    return;
    }

  if (any (keys->rmap.home == rl_._chr))
    {
    rl_._col = 1;
    smg->setrcdr (rl_._row, rl_._col);
    return;
    }

  if (any (keys->rmap.end == rl_._chr))
    {
    rl_._col = strlen (rl_._lin);
    smg->setrcdr (rl_._row, rl_._col);
    return;
    }

  if (any (keys->rmap.delete == rl_._chr))
    {
    if (rl_._col <= strlen (rl_._lin))
      ifnot (rl_._col == strlen (strjoin (rl_.argv[[:rl_._ind]], " ")) + 1)
        rlf_.delete_at (;is_delete);
      else
        if (rl_._ind < length (rl_.argv) - 1)
          {
          rl_.argv[rl_._ind] += rl_.argv[rl_._ind+1];
          rl_.argv[rl_._ind+1] = NULL;
          rl_.argv = rl_.argv[wherenot (_isnull (rl_.argv))];
          }

    return;
    }

  if (' ' == rl_._chr)
    {
    if (qualifier_exists ("insert_ws"))
      {
      rlf_.insert_at ();
      return;
      }

    ifnot (rl_._ind)
      {
      if (1 == rl_._col)
        if (qualifier_exists ("accept_ws"))
          {
          rlf_.insert_at ();
          return;
          }
        else
          return;
 
      ifnot (length (rl_.argv) - 1)
        rl_.argv = [
          substr (rl_.argv[0], 1, rl_._col - 1),
          substr (rl_.argv[0], rl_._col, -1)];
      else
        rl_.argv = [
          substr (rl_.argv[0], 1, rl_._col - 1),
          substr (rl_.argv[0], rl_._col, -1),
          rl_.argv[[1:]]];

      rl_._col++;
      return;
      }

    if (' ' == smg->char_at ())
      {
      if (rl_._ind == length (rl_.argv) - 1)
        (rl_.argv = [rl_.argv, ""], rl_._col++);
      else if (strlen (strjoin (rl_.argv[[:rl_._ind]], " ")) == rl_._col - 1)
        (rl_.argv = [rl_.argv[[:rl_._ind]], "", rl_.argv[[rl_._ind + 1:]]],
        rl_._col++);
      else
        rlf_.insert_at ();

      return;
      }
    }

  if (' ' < rl_._chr <= 126 || 902 <= rl_._chr <= 974)
    rlf_.insert_at ();
}

rlf_.rout = &routine;

private define insert_at (s)
{
  variable
    i,
    arglen,
    len = 0,
    chr = char (qualifier ("chr", rl_._chr));

  rl_._col++;

  _for i (0, rl_._ind)
    {
    arglen = strlen (rl_.argv[i]);
    len += arglen + 1;
    }

  len = rl_._col - (len - arglen);

  if (rl_._col == len)
    rl_.argv[i] += chr;
  else
    ifnot (len)
      if (i > 0)
        rl_.argv[i-1] += chr;
      else
        rl_.argv[i] = chr + rl_.argv[i];
    else
      rl_.argv[i] = sprintf ("%s%s%s", substr (rl_.argv[i], 1, len - 1), chr,
        substr (rl_.argv[i], len, -1));
}

rlf_.insert_at = &insert_at;

private define parse_args (s)
{
  variable
    i,
    found = NULL;

  (rl_._lin, rl_._ind) = ":", NULL;

  _for i (0, length (rl_.argv) - 1)
    ifnot (NULL == rl_.argv[i])
      ifnot (strlen (rl_.argv[i]))
        if (i)
          if (NULL == found)
            found = 1;
          else
            {
            found = NULL;
            rl_.argv[i] = NULL;
            rl_._col--;
            }

  rl_.argv = rl_.argv[wherenot (_isnull (rl_.argv))];
 
  _for i (0, length (rl_.argv) - 1)
    {
    rl_._lin = sprintf ("%s%s%s", rl_._lin, 1 < strlen (rl_._lin) ? " " : "", rl_.argv[i]);
 
    if (NULL == rl_._ind)
      if (rl_._col <= strlen (rl_._lin))
        rl_._ind = i - (rl_._col == strlen (rl_._lin) - strlen (rl_.argv[i]) - 1);
    }
 
  ifnot (strlen (rl_._lin))
    (rl_.argv, rl_._ind) = [""], 0;

  if (NULL == rl_._ind)
    rl_._ind = length (rl_.argv) - 1;

  if (rl_._col == strlen (rl_._lin) && 2 == length (rl_.argv) - rl_._ind)
    rl_.argv = rl_.argv[[:-2]];

  if (rl_._col > strlen (rl_._lin) + 1)
    rl_._col = strlen (rl_._lin) + 1;
}

rlf_.parse_args = &parse_args;

private define printout (s, ar, col, len)
{
  ifnot (length (ar))
    {
    @len = 0;
    return @Array_Type[0];
    }

  variable
    i,
    l,
    lar,
    rows,
    origlen = @len,
    hlreg = qualifier ("hl_region"),
    lines = qualifier ("lines", LINES),
    nar = @len < lines ? @ar : ar[[:lines - 1]];
 
  rlf_.w_comp_rout (nar);

  ifnot (NULL == hlreg)
    smg->hlregion (hlreg[0], hlreg[1], hlreg[2], hlreg[3], hlreg[4]);
 
  @len = @len >= lines;
  
  smg->setrcdr (rl_._row, rl_._col);

  return ar[[origlen >= lines ? lines - 1 : origlen:]];
}

rlf_.printout = &printout;

private define write_completion_routine (s, ar)
{
  variable
    i,
    len = length (ar),
    clrs = Integer_Type[len],
    cols = Integer_Type[len];

  rl_.cmp_lnrs = Integer_Type[len];

  clrs[*] = 5;
  cols[*] = 0;

  len = PROMPTROW - 1 - (strlen (rl_._lin) / COLUMNS) - len + 1;

  _for i (0, length (ar) - 1)
    rl_.cmp_lnrs[i] = len + i;
 
  smg->aratrcaddnstr (ar, clrs, rl_.cmp_lnrs, cols, COLUMNS);
  %srv->write_ar_nstr (ar, clrs, rl_.cmp_lnrs, cols, COLUMNS);
}

rlf_.w_comp_rout = &write_completion_routine;

private define write_rline (line, clr, dim, pos)
{
  waddlineat_dr (line, clr, dim[0], dim[1], pos, COLUMNS);
}

private define write_routine (s)
{
  write_rline (rl_._lin, PROMPTCLR, [rl_._row, 0], [rl_._row, rl_._col]);
}

rlf_.prompt = &write_routine;

private define clear (s, pos)
{
  variable
    ar = String_Type[length (rl_.lnrs)],
    clrs = Integer_Type[length (ar)],
    cols = Integer_Type[length (ar)];

  ar[*] =" ";
  clrs[*] = 0;
  cols[*] = 0;
 
  ifnot (qualifier_exists ("dont_redraw"))
    waddlinear_dr (ar, clrs, rl_.lnrs, cols, pos, COLUMNS);
  else
    waddlinear (ar, clrs, rl_.lnrs, cols, COLUMNS);
}

rlf_.clear = &clear;

private define exec_line (s)
{
  variable list = {};

  array_map (Void_Type, &list_append, list, rl_.argv[[1:]]);
  rlf_.clear (cf_.ptr;dont_redraw);

  if (any (rl_.argv[0] == rl_.com))
    (@clinef[rl_.argv[0]]) (__push_list (list));

  restore (rl_.cmp_lnrs, cf_.ptr);
}

rlf_.execline = &exec_line;

private define readline (s)
{
  rlf_.init ();
 
  topline (" -- VED COMMAND LINE --");
 
  rlf_.prompt ();

  forever
    {
    rl_._chr = getch ();

    if (033 == rl_._chr)
      {
      rlf_.clear (cf_.ptr;dont_redraw);
      topline (" -- PAGER --");
      restore (rl_.cmp_lnrs, cf_.ptr);
      break;
      }

    if ('\r' == rl_._chr)
      {
      topline (" -- PAGER --");
      rlf_.execline ();
      return;
      }

    if ('\t' == rl_._chr)
      if (rl_._ind && length (rl_.argv))
        {
        variable start = 0 == strlen (rl_.argv[rl_._ind]) ? " " : rl_.argv[rl_._ind];
        if (rlf_.fnamecmp (start) == 1)
          {
          rlf_.execline ();
          return;
          }

        rlf_.prompt ();
        continue;
        }

    rlf_.rout ();

    rlf_.parse_args ();
    rlf_.prompt ();
    }
}

rlf_.read = &readline;

private define first_indices (s, str, ar, pat)
{
  variable
    index = "." == pat ? 0 : strlen (pat),
    len = strlen (ar[0]),
    new_str = len > index ? ar[0][[0:index]] : NULL,
    indices = NULL != new_str ? array_map (Char_Type, &string_match, ar,
        str_quote_string (sprintf ("^%s", new_str), ".+", '\\')) : [0];

  ifnot (length (ar) == length (where (indices)))
    return;

  if ("." != pat)
    @str +=pat;
  else
    @str = "";

  while (NULL != new_str)
    {
    indices = array_map (Char_Type, &string_match, ar,
        str_quote_string (sprintf ("^%s", new_str), ".", '\\'));

    if (length (ar) == length (where (indices)))
      {
      @str += char (new_str[-1]);
      index++;
      new_str = len > index ? ar[0][[0:index]] : NULL;
      }
    else
      return;
    }
}

rlf_.firstindices = &first_indices;

private define append_slash (s, file)
{
  if ('/' != file[-1] && 0 == (1 == strlen (file) && '.' == file[0]))
    return isdirectory (file) ? "/" : "";

  return  "";
}

rlf_.appendslash = &append_slash;;

private define append_dir_indicator (base, files)
{
  variable ar = @files;
  ar[where (array_map (Char_Type, &isdirectory,
    array_map (String_Type, &path_concat, base, files)))] += "/";

  return ar;
}

private define list_directory (s, retval, dir, pat, pos)
{
  variable
    ar = String_Type[0],
    st = stat_file (dir);

  if (NULL == st)
    {
    @retval = -1;
    return ar;
    }

  ifnot (stat_is ("dir", st.st_mode))
    return [dir];

  ar = listdir (dir);

  if (NULL == ar)
    {
    @retval = -1;
    return ar;
    }

  ifnot (NULL == pat)
    ar = ar[wherenot (array_map (Char_Type, &strncmp, ar, pat, pos))];

  return ar[array_sort (ar)];
}

rlf_.listdirectory = &list_directory;

private define fname_completion (s, start)
{
  variable
    ar,
    st,
    str,
    tmp,
    file,
    isdir,
    retval,
    chr = 0,
    pat = "";

 if (' ' != start[0])
    {
    tmp = rlf_.appendslash (start);
    if ("/" == tmp)
      {
      rl_.argv[rl_._ind] += tmp;
      rl_._col += strlen (tmp);
      rlf_.parse_args ();
      rlf_.prompt();
      }
    }

  forever
    {
    pat = "";
    tmp = strlen (rl_._lin) ? rl_.argv[rl_._ind] : "";

    file = ' ' == (rl_._lin)[-1] ? getcwd () :
      sprintf ("%s%s", evaldir (tmp;dont_change), rlf_.appendslash (tmp));
 
    if (2 < strlen (file))
      if ("./" == file[[0:1]] && 0 == strlen (rl_.argv[rl_._ind]))
        file = file[[2:]];
 
    if (access (file, F_OK) || '/' != (rl_._lin)[-1])
      {
      pat = path_basename (file);
      file = path_dirname (file);
      }
 
    retval = 0;
    ar = rlf_.listdirectory (&retval, file, pat, strlen (pat));

    if (-1 == retval || 0 == length (ar))
      {
      restore (rl_.cmp_lnrs, [rl_._row, rl_._col]);
      return 0;
      }

    ifnot (1 == length (ar))
      {
      str = "";
      rlf_.firstindices (&str, ar, pat);

      if (strlen (str))
        {
        str = path_concat (file, str);
        rl_.argv[rl_._ind] = sprintf ("%s%s", str, rlf_.appendslash (str));
        if ("./" == rl_.argv[rl_._ind][[0:1]])
          rl_.argv[rl_._ind] = substr (rl_.argv[rl_._ind], 3, -1);

        rl_._col = strlen (strjoin (rl_.argv[[:rl_._ind]], " ")) + 1;
        rlf_.parse_args ();
        rlf_.prompt ();
        }
      }

    tmp = "";
    chr = rlf_.hlitem (append_dir_indicator (file, ar), file, rl_._col, &tmp);
 
    if (033 == chr)
      {
      restore (rl_.cmp_lnrs, [rl_._row, rl_._col]);
      rl_._col = strlen (strjoin (rl_.argv[[:rl_._ind]], " ")) + 1;
      rlf_.parse_args ();

      return 0;
      }

    if (' ' == chr)
      {
      file = path_concat (file, tmp[-1] == '/' ? substr (tmp, 1, strlen (tmp) - 1) : tmp);
      st = lstat_file (file);
 
      ifnot (NULL == st)  % THIS SHOULD NOT FAIL
        {
        isdir = stat_is ("dir", st.st_mode);
        rl_.argv[rl_._ind] = sprintf ("%s%s", file, isdir ? "/" : "");

        if ("./" == rl_.argv[rl_._ind][[0:1]])
          rl_.argv[rl_._ind] = substr (rl_.argv[rl_._ind], 3, -1);
        rl_._col = strlen (strjoin (rl_.argv[[:rl_._ind]], " ")) + 1;
        rlf_.parse_args ();

        if (isdir)
          {
          restore (rl_.cmp_lnrs, [rl_._row, rl_._col]);
          rlf_.prompt ();
          continue;
          }
        }
      }
 
    if (any (keys->rmap.backspace == chr) && strlen (rl_._lin))
      {
      rlf_.delete_at ();
      rlf_.parse_args ();
      restore (rl_.cmp_lnrs, [rl_._row, rl_._col]);
      return 0;
      }

    if (' ' == chr)
      if (length (ar))
        {
        ar = array_map (String_Type, &path_concat, file, ar);
        ar = ar[wherenot (array_map (Char_Type, &strncmp, ar,
          rl_.argv[rl_._ind] + " ", strlen (rl_.argv[rl_._ind]) + 1))];

        if (length (ar))
          {
          rl_.argv[rl_._ind] = sprintf ("%s%s", ar[0], rlf_.appendslash (ar[0]));
          rl_._col = strlen (strjoin (rl_.argv[[:rl_._ind]], " ")) + 1;
          rlf_.parse_args ();
          }
        }
      else
        {
        restore (rl_.cmp_lnrs, [rl_._row, rl_._col]);
        return 0;
        }

    if ('\r' == chr || 0 == chr || 0 == (' ' < chr <= '~'))
      {
      restore (rl_.cmp_lnrs, '\r' == chr ? cf_.ptr : [rl_._row, rl_._col]);
      return '\r' == chr;
      }

    rlf_.insert_at (;chr = chr);

    if (strlen (s.appendslash (rl_.argv[rl_._ind])))
      rlf_.insert_at (;chr = '/');

    rlf_.parse_args ();
    rlf_.prompt ();
    restore (rl_.cmp_lnrs, [rl_._row, rl_._col]);
    }
}

rlf_.fnamecmp = &fname_completion;

private define form_ar (items, fmt, ar, bar)
{
  @bar = String_Type[0];

  ifnot (items)
    return;

  variable i = 0;

  while (i < length (ar))
    {
    if (i + items < length (ar))
      @bar = [@bar, strjoin (array_map (
        String_Type, &sprintf, fmt, ar[[i:i + items - 1]]))];
    else
      @bar = [@bar, strjoin (array_map (String_Type, &sprintf, fmt, ar[[i:]]))];

    i += items;
    }
}

rlf_.formar = &form_ar;

private define hlitem (s, ar, base, acol, item)
{
  variable
    chr,
    car,
    bar,
    len,
    tmp,
    bcol,
    irow,
    lrow = PROMPTROW - (strlen (rl_._lin) / COLUMNS),
    items,
    i = 0,
    page = 0,
    icol = 0,
    colr = 12,
    index = 0,
    max_len = max (strlen (ar)) + 2,
    fmt = sprintf ("%%-%ds", max_len),
    lines;

  if (max_len < COLUMNS)
    items = COLUMNS / max_len;
  else
    items = 1;
 
  if (max_len < COLUMNS)
    if ((items - 1) + (max_len * items) > COLUMNS)
      items--;

  while ((i + 1) * COLUMNS <= acol)
    i++;

  bcol = acol - (COLUMNS * i);

  rlf_.formar (items, fmt, ar, &bar);
 
  len = length (bar);
  @item = ar[index];
  lines = lrow - 1;

  car = @bar;

  irow = lrow - (length (car) > lines ? lines : length (car));

  bar = rlf_.printout (bar, bcol, &len;lines = lines,
    row = PROMPTROW - (strlen (rl_._lin) / COLUMNS) + i,
    hl_region = [colr, irow, icol * max_len, 1, max_len]);
 
  chr = getch ();
 
  ifnot (len || any (['\t', [keys->UP:keys->RIGHT], keys->PPAGE, keys->NPAGE] == chr))
    {
    restore (rl_.cmp_lnrs, [rl_._row, rl_._col]);
    return chr;
    }
 
  while ( any (['\t', [keys->UP:keys->RIGHT], keys->PPAGE, keys->NPAGE] == chr))
    {
    if ('\t' == chr)
      if (lines >= length (car) && page == 0)
        chr = keys->RIGHT;
      else
        chr = keys->NPAGE;

    if (keys->NPAGE == chr)
      {
      ifnot (len)
        {
        rlf_.formar (items, fmt, ar, &bar);
        page = 0;
        }

      if (len)
        page++;

      len = length (bar);

      index = (page) * ((lines - 1) * items);

      @item = ar[index];
 
      car = @bar;

      irow = lrow - (length (car) > lines ? lines : length (car));
      icol = 0;
 
      if (length (bar) < lines)
        restore (rl_.cmp_lnrs, [rl_._row, rl_._col]);

      bar = rlf_.printout (bar, bcol, &len;lines = lines,
        row = PROMPTROW - (strlen (rl_._lin) / COLUMNS) + i,
        hl_region = [colr, irow, icol * max_len, 1, max_len]);
 
      chr = getch ();
      continue;
      }
 
    if (keys->UP == chr)
      if ((0 == index || index < items) && 1 < length (car))
        {
        (irow, icol, index) =
          lrow - 1,
          length (car) >= lines
            ? items - 1
            : length (car) mod items
              ? (length (strtok (strjoin (car, " "))) mod items) - 1
              : items - 1,
          length (car) >= lines
            ? ((page) * (lines * items)) + ((lines - 1) * items) + items - 1
            : length (ar) - 1;
        }
      else
        {
        irow--;
        index -= items;
        if (0 == irow || 1 == length (car))
          (irow, icol, index) =
            lrow - 1,
            length (car) >= lines
              ? items - 1
              : length (strtok (strjoin (car, " "))) mod items
                ? (length (strtok (strjoin (car, " "))) mod items) - 1
                : items - 1,
            length (car) >= lines
              ? ((page) * ((lines - 1) * items)) + ((lines - 1) * items) + items - 1
              : length (ar) - 1;
        }

    if (keys->DOWN == chr)
      if (irow + 1 > lines || index + items > length (ar) - 1)
        (irow, icol, index) =
          lrow - (length (car) > lines ? lines : length (car)),
          0,
          page * ((lines - 1) * items);
      else
        {
        irow++;
        index += items;
        }

    if (keys->LEFT == chr)
      {
      icol--;
      index--;
      if (-1 == index)
        if (length (car) < lines)
          (irow, icol, index) =
            lrow - 1,
            length (strtok (strjoin (car, " "))) mod items
              ? (length (strtok (strjoin (car, " "))) mod items) - 1
              : items - 1,
              length (ar) - 1;

      if (-1 == icol)
        {
        irow--;
        icol = length (car) mod items
          ? (length (strtok (strjoin (car, " "))) mod items) - 1
          : items - 1;
        }

      ifnot (irow)
        if (lines > length (car))
          {
          irow++;
          icol = 0;
          index++;
          }
        else
          (irow, icol, index) =
            lrow - 1,
            items - 1,
           ((page) * ((lines - 1) * items)) + ((lines - 1) * items) + items - 1;
      }

    if (keys->RIGHT == chr)
      if (index + 1 > length (ar) - 1)
        (irow, icol, index) =
          lrow - (length (car) > lines ? lines : length (car)),
          0,
          (page) * ((lines - 1) * items);
      else if (icol + 1 == items)
        ifnot (irow > lines)
          {
          irow++;
          icol = 0;
          index++;
          }
        else
          (irow, icol, index) =
            lrow - (length (car) > lines ? lines : length (car)),
            0,
            (page) * ((lines - 1) * items);
      else
        {
        index++;
        icol++;
        }
 
    if (keys->PPAGE== chr)
      {
      ifnot (page)
        {
        if (length (car) > lines)
          page = 0;

        rlf_.formar (items, fmt, ar, &car);
        len = length (car);

        while (len > lines)
          {
          page++;
          car = car[[lines - 1:]];
          bar = car;
          len = length (car);
          }

        (irow, icol, index) =
          lrow - (length (car) > lines ? lines : length (car)),
          0,
          (page) * ((lines - 1) * items);

        if (length (car) < lines)
          restore (rl_.cmp_lnrs, [rl_._row, rl_._col]);
        }
      else
        {
        page--;
        rlf_.formar (items, fmt, ar, &car);
        loop (page)
          {
          len = length (car);
          car = car[[lines - 1:]];
          }

        bar = car[[lines - 1:]];

        (irow, icol, index) =
          lrow - (length (car) > lines ? lines : length (car)),
          0,
          (page) * ((lines - 1) * items);
        }
      }

    @item = ar[index];

    len = length (car);

    () = rlf_.printout (car, bcol, &len;lines = lines,
      row = PROMPTROW - (strlen (rl_._lin) / COLUMNS) + i,
      hl_region = [colr, irow, icol * max_len, 1, max_len]);

    chr = getch ();
    }

  return chr;
}

rlf_.hlitem = &hlitem;

private define getline (s, line, prev_l, next_l)
{
  topline_dr (" -- INSERT --");

  variable
    lline,
    i,
    modified = qualifier ("modified", 0),
    gl_ = @Rline_Type;

  gl_._col = cf_.ptr[1];
  gl_._row = cf_.ptr[0];

  forever
    {
    gl_._chr = getch ();

    if (033 == gl_._chr)
      {
      if (0 < cf_.ptr[1] - cf_._indent)
        cf_.ptr[1]--;
 
      if (modified)
        {
        set_modified ();
 
        cf_.lins[cf_.ptr[0] - cf_.rows[0]] = @line;
        cf_.lines["next" == qualifier ("dir") ? qualifier ("i") + 1 :qualifier ("i")] = @line;

        cf_.st_.st_size = calcsize (cf_.lines);
        }

      topline (" -- PAGER --");
      draw_tail ();

      return;
      }

    if ('\r' == gl_._chr)
      if (strlen (@line) == cf_.ptr[1])
        {
        cf_.lins[cf_.ptr[0] - cf_.rows[0]] = @line;
        cf_.lines["next" == qualifier ("dir") ? qualifier ("i") + 1 :qualifier ("i")] = @line;

        cf_._chr = 'o';
 
        (@pagerf[string ('o')]) (;modified = 1);

        return;
        }
      else
        {
        lline = 0 == cf_.ptr[1] - cf_._indent ? " " : substr (@line, 1, cf_.ptr[1]);
        i = qualifier ("i");
        @line = substr (@line, cf_.ptr[1] + 1, -1);

        prev_l = lline;

        if (i + 1 >= cf_._len)
          next_l = "";
        else
          next_l = v_lin (cf_.ptr[0] + 1);

        cf_.ptr[1] = cf_._indent;
        cf_._i = cf_._ii;

        if (cf_.ptr[0] == cf_.rows[-2] && cf_.ptr[0] + 1 > cf_._avlins)
          cf_._i++;
        else
          cf_.ptr[0]++;

        ifnot (i)
          cf_.lines = [lline, @line, cf_.lines[[i + 1:]]];
        else
          cf_.lines = [cf_.lines[[:i - 1]], lline, @line, cf_.lines[[i + 1:]]];

        cf_._len++;
 
        cf_.draw ();
 
        rlf_.getline (line, prev_l, next_l;dir = "next", i = i, modified = 1);

        return;
        }

    if (keys->UP == gl_._chr)
      {
      i = v_lnr ('.');
      ifnot (i)
        continue;

      cf_.lins[cf_.ptr[0] - cf_.rows[0]] = @line;
      cf_.lines["next" == qualifier ("dir") ? qualifier ("i") + 1 :qualifier ("i")] = @line;

      (@pagerf[string (keys->UP)]);

      cf_._chr = 'i';

      (@pagerf[string ('i')]) (;modified = modified);

      return;
      }
 
    if (keys->DOWN == gl_._chr)
      {
      i = v_lnr ('.');
      ifnot (i < cf_._len)
        continue;

      cf_.lins[cf_.ptr[0] - cf_.rows[0]] = @line;
      cf_.lines["next" == qualifier ("dir") ? qualifier ("i") + 1 :qualifier ("i")] = @line;

      (@pagerf[string (keys->DOWN)]);

      cf_._chr = 'i';

      (@pagerf[string ('i')]) (;modified = modified);

      return;
      }

    if (any (keys->rmap.left == gl_._chr))
      {
      if (0 < cf_.ptr[1] - cf_._indent)
        {
        gl_._col--;
        cf_.ptr[1]--;
        smg->setrcdr (cf_.ptr[0], cf_.ptr[1]);
        }

      continue;
      }
 
    if (any (keys->CTRL_y == gl_._chr))
      {
      if (cf_.ptr[1] < strlen (prev_l))
        {
        @line = substr (@line, 1, gl_._col) + substr (prev_l, cf_.ptr[1] + 1, 1)
          + substr (@line, gl_._col + 1, - 1);
        gl_._col++;
        cf_.ptr[1]++;
        waddlineat_dr (@line, 0, cf_.ptr[0], 0, [cf_.ptr[0], cf_.ptr[1]], cf_._maxlen);
        modified = 1;
        }

      continue;
      }

    if (any (keys->CTRL_e == gl_._chr))
      {
      if (cf_.ptr[1] < strlen (next_l))
        {
        @line = substr (@line, 1, gl_._col) + substr (next_l, cf_.ptr[1] + 1, 1) +
          substr (@line, gl_._col + 1, - 1);
        gl_._col++;
        cf_.ptr[1]++;
        waddlineat_dr (@line, 0, cf_.ptr[0], 0, [cf_.ptr[0], cf_.ptr[1]], cf_._maxlen);
        modified = 1;
        }

      continue;
      }

    if (any (keys->rmap.right == gl_._chr))
      {
      if (gl_._col < strlen (@line))
        {
        gl_._col++;
        cf_.ptr[1]++;
        smg->setrcdr (cf_.ptr[0], cf_.ptr[1]);
        }

      continue;
      }

    if (any (keys->rmap.home == gl_._chr))
      {
      gl_._col = cf_._indent;
      cf_.ptr[1] = cf_._indent;
      smg->setrcdr (cf_.ptr[0], cf_.ptr[1]);
      continue;
      }

    if (any (keys->rmap.end == gl_._chr))
      {
      gl_._col = strlen (@line);
      cf_.ptr[1] = strlen (@line);
      smg->setrcdr (cf_.ptr[0], cf_.ptr[1]);
      continue;
      }

    if (any (keys->rmap.backspace == gl_._chr))
      {
      if (0 < cf_.ptr[1] - cf_._indent)
        {
        @line = substr (@line, 1, gl_._col - 1) + substr (@line, gl_._col + 1, - 1);
        cf_.ptr[1]--;
        gl_._col--;
        }

      waddlineat_dr (@line, 0, cf_.ptr[0], 0, [cf_.ptr[0], cf_.ptr[1]], cf_._maxlen);
      modified = 1;
      continue;
      }

    if (any (keys->rmap.delete == gl_._chr))
      {
      @line = substr (@line, 1, gl_._col) + substr (@line, gl_._col + 2, - 1);

      waddlineat_dr (@line, 0, cf_.ptr[0], 0, [cf_.ptr[0], cf_.ptr[1]], cf_._maxlen);
      modified = 1;
      continue;
      }

    if (' ' <= gl_._chr <= 126 || 902 <= gl_._chr <= 974)
      {
      @line = substr (@line, 1, gl_._col) + char (gl_._chr) +  substr (@line, gl_._col + 1, - 1);
      gl_._col++;
      if (strlen (@line) < cf_._maxlen)
        {
        cf_.ptr[1]++;
        waddline (@line, 0, cf_.ptr[0]);
        draw_tail (;line = @line, col = cf_.ptr[1] + 1);
        }
      else
        {
        lline = substr (@line, strlen (@line) - cf_._maxlen + 1, -1);
        waddline (lline, 0, cf_.ptr[0]);
        draw_tail (;lline = @line, col = gl_._col);
        }

      modified = 1;
      continue;
      }
    }
}

rlf_.getline = &getline;
