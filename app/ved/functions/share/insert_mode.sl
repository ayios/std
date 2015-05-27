loadfrom ("pcre", "find_unique_words_in_lines", 1, &on_eval_err);
loadfrom ("pcre", "find_unique_lines_in_lines", 1, &on_eval_err);

variable insfuncs = struct
  {
  cr,
  esc,
  bol,
  eol,
  up,
  left,
  down,
  right,
  del_prev,
  del_next,
  ins_char,
  ins_tab,
  completeline,
  inscompletion,
  wordcompletion,
  };

define insert ();

private define ins_tab (is, s, line)
{
  @line = substr (@line, 1, s._index) + repeat (" ", s._shiftwidth) +
    substr (@line, s._index + 1, - 1);

  s._index += s._shiftwidth;

  is.modified = 1;

  if (strlen (@line) < s._maxlen && s.ptr[1] + s._shiftwidth < s._maxlen)
    {
    s.ptr[1] += s._shiftwidth;
    waddline (s, getlinestr (s, @line, 1), 0, s.ptr[0]);
    draw_tail (s;chr = decode (substr (@line, s._index + 1, 1))[0]);
    return;
    }

  s._is_wrapped_line = 1;

  variable i = 0;
  if (s.ptr[1] < s._maxlen)
    while (s.ptr[1]++, i++, (s.ptr[1] < s._maxlen && i < s._shiftwidth));
  else
    i = 0;
 
  s._findex += (s._shiftwidth - i);

  variable
    lline = getlinestr (s, @line, s._findex + 1 - s._indent);

  waddline (s, lline, 0, s.ptr[0]);
  draw_tail (s;chr = decode (substr (@line, s._index + 1, 1))[0]);
}

insfuncs.ins_tab = &ins_tab;

private define ins_char (is, s, line)
{
  @line = substr (@line, 1, s._index) + char (is.chr) + substr (@line, s._index + 1, - 1);

  s._index++;

  is.modified = 1;

  if (strlen (@line) < s._maxlen && s.ptr[1] < s._maxlen)
    {
    s.ptr[1]++;
    waddline (s, getlinestr (s, @line, 1), 0, s.ptr[0]);
    draw_tail (s;chr = decode (substr (@line, s._index + 1, 1))[0]);
    return;
    }
 
  s._is_wrapped_line = 1;
 
  if (s.ptr[1] == s._maxlen)
    s._findex++;

  variable
    lline = getlinestr (s, @line, s._findex + 1 - s._indent);

  if (s.ptr[1] < s._maxlen)
    s.ptr[1]++;

  waddline (s, lline, 0, s.ptr[0]);
  draw_tail (s;chr = decode (substr (@line, s._index + 1, 1))[0]);
}

insfuncs.ins_char = &ins_char;

private define del_prev (is, s, line)
{
  variable
    lline,
    len;

  ifnot (s._index - s._indent)
    {
    ifnot (is.lnr)
      return;

   if (s.ptr[0] != s.rows[0])
     s.ptr[0]--;
   else
     s._ii--;

    is.lnr--;

    s._index = strlen (s.lines[is.lnr]);
    s.ptr[1] = s._index > s._maxlen ? s._maxlen : s._index;

    if (is.lnr == s._len)
      @line = s.lines[is.lnr];
    else
      @line = s.lines[is.lnr] + @line;
 
    s.lines[is.lnr] = @line;
    s.lines[is.lnr + 1] = NULL;
    s.lines = s.lines[wherenot (_isnull (s.lines))];
    s._len--;

    s._i = s._ii;

    s.draw (;dont_draw);

    len = strlen (@line);
    if (len > s._maxlen)
      {
      s._findex = len - s._maxlen;
      s.ptr[1] = s._maxlen - (len - s._index);
      s._is_wrapped_line = 1;
      }
    else
      s._findex = s._indent;

    lline = getlinestr (s, @line, s._findex + 1 - s._indent);

    waddline (s, lline, 0, s.ptr[0]);
    draw_tail (s;chr = decode (substr (@line, s._index + 1, 1))[0]);
    is.modified = 1;
    return;
    }

  @line = substr (@line, 1, s._index - 1) + substr (@line, s._index + 1, - 1);

  len = strlen (@line);
 
  s._index--;

  ifnot (s.ptr[1])
    {
    if (s._index > s._maxlen)
      {
      s.ptr[1] = s._maxlen;
      s._findex = len - s._linlen;
      lline = substr (@line, s._findex + 1, -1);
      waddline (s, lline, 0, s.ptr[0]);
      draw_tail (s;chr = decode (substr (@line, s._index, 1))[0]);
      return;
      }

    s._findex = s._indent;
    s.ptr[1] = len;
    waddline (s, @line, 0, s.ptr[0]);
    draw_tail (s;chr = decode (substr (@line, s._index, 1))[0]);
    s._is_wrapped_line = 0;
    return;
    }

  s.ptr[1]--;

  if (s._index == len)
    waddlineat (s, " ", 0, s.ptr[0], s.ptr[1], s._maxlen);
  else
    {
    lline = substr (@line, s._index + 1, -1);
    waddlineat (s, lline, 0, s.ptr[0], s.ptr[1], s._maxlen);
    }
 
  draw_tail (s;chr = decode (substr (@line, s._index + 1, 1))[0]);

  is.modified = 1;
}

insfuncs.del_prev = &del_prev;

private define del_next (is, s, line)
{
  ifnot (s._index - s._indent)
    if (1 == strlen (@line))
      if (" " == @line)
        {
        if (is.lnr < s._len)
          {
          @line += s.lines[is.lnr + 1];
          s.lines[is.lnr + 1 ] = NULL;
          s.lines = s.lines[wherenot (_isnull (s.lines))];
          s._len--;
          s._i = s._ii;
          s.draw (;dont_draw);
          is.modified = 1;
          waddline (s, getlinestr (s, @line, 1), 0, s.ptr[0]);
          draw_tail (s;chr = decode (substr (@line, s._index + 1, 1))[0]);
          }

        return;
        }
      else
        {
        @line = " ";
        waddline (s, @line, 0, s.ptr[0]);
        draw_tail (s;chr = decode (substr (@line, s._index + 1, 1))[0]);
        is.modified = 1;
        return;
        }

  if (s._index == strlen (@line))
    {
    if (is.lnr < s._len)
      {
      @line += getlinestr (s, s.lines[is.lnr + 1], 1);
      s.lines[is.lnr + 1 ] = NULL;
      s.lines = s.lines[wherenot (_isnull (s.lines))];
      s._len--;
      s._i = s._ii;
      s.draw (;dont_draw);
      is.modified = 1;
      if (s._is_wrapped_line)
        waddline (s, getlinestr (s, @line, s._findex + 1 - s._indent), 0, s.ptr[0]);
      else
        waddline (s, getlinestr (s, @line, 1), 0, s.ptr[0]);

      draw_tail (s;chr = decode (substr (@line, s._index + 1, 1))[0]);
      }

    return;
    }

  @line = substr (@line, 1, s._index) + substr (@line, s._index + 2, - 1);

  if (s._is_wrapped_line)
    waddline (s, getlinestr (s, @line, s._findex + 1 - s._indent), 0, s.ptr[0]);
  else
    waddline (s, getlinestr (s, @line, 1), 0, s.ptr[0]);
 
  draw_tail (s;chr = decode (substr (@line, s._index + 1, 1))[0]);
  is.modified = 1;
}

insfuncs.del_next = &del_next;

private define eol (is, s, line)
{
  variable
    lline,
    len = strlen (@line);
 
  s._index = len;

  if (len > s._linlen)
    {
    s._findex = len - s._linlen;
    lline = getlinestr (s, @line, s._findex + 1 - s._indent);
 
    waddline (s, lline, 0, s.ptr[0]);

    s.ptr[1] = s._maxlen;
    s._is_wrapped_line = 1;
    }
  else
    s.ptr[1] = len;

  draw_tail (s;chr = decode (substr (@line, s._index + 1, 1))[0]);
}

insfuncs.eol = &eol;

private define bol (is, s, line)
{
  s._findex = s._indent;
  s._index = s._indent;
  s.ptr[1] = s._indent;
  waddline (s, getlinestr (s, @line, 1), 0, s.ptr[0]);
  draw_tail (s;chr = decode (substr (@line, s._index + 1, 1))[0]);
  s._is_wrapped_line = 0;
}

insfuncs.bol = &bol;

private define completeline (is, s, line, comp_line)
{
  if (s._is_wrapped_line)
    return;

  if (s._index < strlen (comp_line) - s._indent)
    {
    @line = substr (@line, 1, s._index + s._indent) +
      substr (comp_line, s._index + 1 + s._indent, 1) +
      substr (@line, s._index + 1 + s._indent, -1);

    s._index++;

    if (s.ptr[1] + 1 < s._maxlen)
      s.ptr[1]++;

    waddline (s, getlinestr (s, @line, 1), 0, s.ptr[0]);
    draw_tail (s;chr = decode (substr (@line, s._index + 1, 1))[0]);
    is.modified = 1;
    }
}

insfuncs.completeline = &completeline;

private define right (is, s, line)
{
  variable len = strlen (@line);

  if (s._index + 1 > len || 0 == len)
    return;

  s._index++;
 
  ifnot (s.ptr[1] == s._maxlen)
    s.ptr[1]++;
 
  if (s._index + 1 > s._maxlen)
    {
    s._findex++;
    s._is_wrapped_line = 1;
    }
 
  variable lline;

  if (s.ptr[1] + 1 > s._maxlen)
    {
    lline = getlinestr (s, @line, s._findex - s._indent);
    waddline (s, lline, 0, s.ptr[0]);
    }

  draw_tail (s;chr = decode (substr (@line, s._index + 1, 1))[0]);
}

insfuncs.right = &right;

private define left (is, s, line)
{
  if (0 < s.ptr[1] - s._indent)
    {
    s._index--;
    s.ptr[1]--;
    draw_tail (s;chr = decode (substr (@line, s._index + 1, 1))[0]);
    }
  else
    if (s._is_wrapped_line)
      {
      s._index--;
      variable lline;
      lline = getlinestr (s, @line, s._index - s._indent);

      waddline (s, lline, 0, s.ptr[0]);
 
      draw_tail (s;chr = decode (substr (@line, s._index, 1))[0]);

      if (s._index - 1 == s._indent)
        s._is_wrapped_line = 0;
      }
}

insfuncs.left = &left;

private define down (is, s, line)
{
  if (is.lnr == s._len)
    return;

  s.lins[s.ptr[0] - s.rows[0]] = @line;
  s.lines[is.lnr] = @line;
 
  s._findex = s._indent;

  is.lnr++;

  is.prev_l = @line;
  if (is.lnr + 1 > s._len)
    is.next_l = "";
  else
    is.next_l = s.lines[is.lnr + 1];

  if (s._is_wrapped_line)
    {
    waddline (s, getlinestr (s, @line, 1), 0, s.ptr[0]);
    s._is_wrapped_line = 0;
    s.ptr[1] = s._maxlen;
    }

  s._index = s.ptr[1];

  @line = s.lines[is.lnr];

  variable len = strlen (@line);
 
  if (s._index > len)
    {
    s.ptr[1] = len ? len : s._indent;
    s._index = len ? len : s._indent;
    }
 
  if (s.ptr[0] < s.vlins[-1])
    {
    s.ptr[0]++;
    draw_tail (s;chr = strlen (@line)
      ? s._index > s._indent
        ? decode (substr (@line, s._index, 1))[0]
        : decode (substr (@line, s._indent + 1, 1))[0]
      : ' ');

    return;
    }

  if (s.lnrs[-1] == s._len)
    return;

  ifnot (s.ptr[0] == s.vlins[-1])
    s.ptr[0]++;

  s._i++;

  variable chr = strlen (@line)
    ? s._index > s._indent
      ? decode (substr (@line, s._index, 1))[0]
      : decode (substr (@line, s._indent + 1, 1))[0]
    : ' ';
  s.draw (;chr = chr);
}

insfuncs.down = &down;

private define up (is, s, line)
{
  variable i = v_lnr (s, '.');

  ifnot (is.lnr)
    return;

  s.lins[s.ptr[0] - s.rows[0]] = @line;
  s.lines[is.lnr] = @line;

  is.lnr--;

  is.next_l = @line;
  if (-1 == is.lnr - 1)
    is.prev_l = "";
  else
    is.prev_l = s.lines[is.lnr - 1];

  s._findex = s._indent;

  if (s._is_wrapped_line)
    {
    waddline (s, getlinestr (s, @line, s._indent + 1 - s._indent), 0, s.ptr[0]);
    s._is_wrapped_line = 0;
    s.ptr[1] = s._maxlen;
    }
 
  s._index = s.ptr[1];
 
  @line = s.lines[is.lnr];
 
  variable len = strlen (@line);

  if (s._index > len)
    {
    s.ptr[1] = len ? len : s._indent;
    s._index = len ? len : s._indent;
    }
 
  if (s.ptr[0] > s.vlins[0])
    {
    s.ptr[0]--;
    draw_tail (s;chr = strlen (@line)
      ? s._index > s._indent
        ? decode (substr (@line, s._index, 1))[0]
        : decode (substr (@line, s._indent + 1, 1))[0]
      : ' ');
    return;
    }
 
  s._i = s._ii - 1;
 
  variable chr = strlen (@line)
    ? s._index > s._indent
      ? decode (substr (@line, s._index, 1))[0]
      : decode (substr (@line, s._indent + 1, 1))[0]
    : ' ';

  s.draw (;chr = chr);
}

insfuncs.up = &up;

private define cr (is, s, line)
{
  variable
    prev_l,
    next_l,
    lline;

  if (strlen (@line) == s._index)
    {
    s.lines[is.lnr] = @line;

    s._chr = 'o';
 
    (@pagerf[string ('o')]) (s;modified);

    return;
    }
  else
    {
    lline = 0 == s._index - s._indent ? " " : substr (@line, 1, s._index);
    @line = substr (@line, s._index + 1, -1);

    prev_l = lline;

    if (is.lnr + 1 >= s._len)
      next_l = "";
    else
      if (s.ptr[0] == s.rows[-2])
        next_l = s.lines[is.lnr + 1];
      else
        next_l = v_lin (s, s.ptr[0] + 1);

    s.ptr[1] = s._indent;
    s._i = s._ii;

    if (s.ptr[0] == s.rows[-2] && s.ptr[0] + 1 > s._avlins)
      s._i++;
    else
      s.ptr[0]++;

    ifnot (is.lnr)
      s.lines = [lline, @line, s.lines[[is.lnr + 1:]]];
    else
      s.lines = [s.lines[[:is.lnr - 1]], lline, @line, s.lines[[is.lnr + 1:]]];

    s._len++;
 
    s.draw (;dont_draw);
 
    @line = repeat (" ", s._indent) + @line;
    waddline (s, @line, 0, s.ptr[0]);
    draw_tail (s;chr = decode (substr (@line, s._index + 1, 1))[0]);

    s._index = s._indent;
    s._findex = s._indent;

    insert (s, line, is.lnr + 1, prev_l, next_l;modified, dont_draw_tail);
    }
}

insfuncs.cr = &cr;

private define esc (is, s, line)
{
  if (0 < s.ptr[1] - s._indent)
    s.ptr[1]--;

  if (0 < s._index - s._indent)
    s._index--;
 
  if (is.modified)
    {
    s.lins[s.ptr[0] - s.rows[0]] = @line;
    s.lines[is.lnr] = @line;

    set_modified (s);
 
    s.st_.st_size = getsizear (s.lines);
    }
 
  topline (" -- pager --");
  draw_tail (s);
}

insfuncs.esc = &esc;

private define linecompletion (s, line)
{
  variable
    chr,
    lines,
    item = @line,
    rows = Integer_Type[0],
    indexchanged = 0,
    index = 1,
    origlen = strlen (@line),
    col = s._index - 1,
    iwchars = [MAPS, ['0':'9'], '_'];

  forever
    {
    ifnot (indexchanged)
      lines = pcre->find_unique_lines_in_lines (s.lines, @line, NULL);
          
    ifnot (length (lines))
      if (length (lines))
        {
        smg->restore (rows, s.ptr, 1);
        return;
        }

    indexchanged = 0;

    if (index > length (lines))
      index = length (lines);

    rows = widg->pop_up (lines, s.ptr[0], s.ptr[1] + 1, index);

    smg->setrcdr (s.ptr[0], s.ptr[1]);

    chr = getch ();

    if (any (keys->rmap.backspace == chr))
      {
      if (1 == strlen (item))
        {
        smg->restore (rows, s.ptr, 1);
        return;
        }
      else
        item = substr (item, 1, strlen (item) - 1);
      
      smg->restore (rows, NULL, NULL);
      continue;
      }

    if (any ([' ', '\r'] == chr))
      {
      smg->restore (rows, NULL, NULL);
      
      @line = lines[index - 1] + substr (@line, s._index + 1, -1);
      
      waddline (s, getlinestr (s, @line, 1), 0, s.ptr[0]);
      
      variable len = strlen (@line);

      %bug here (if len > maxlen) (wrapped line)
      if (len < origlen)
        s._index -= (origlen - len);
      else if (len > origlen)
        s._index += len - origlen;

      s.ptr[1] = s._index; 

      draw_tail (s;chr = decode (substr (@line, s._index + 1, 1))[0]);
      
      return;
      }

    if (any ([keys->CTRL_n, keys->DOWN] == chr))
      {
      index++;
      if (index > length (lines))
        index = 1;

      indexchanged = 1;
      }

    if (any ([keys->CTRL_p, keys->UP] == chr))
      {
      index--;
      ifnot (index)
        index = length (lines);

      indexchanged = 1;
      }

    ifnot (any ([iwchars, keys->CTRL_n, keys->DOWN, keys->CTRL_p, keys->UP,
      keys->rmap.backspace, '\r', ' '] == chr))
      {
      smg->restore (rows, s.ptr, 1);
      return;
      }
    else
      item += char (chr);
    
    ifnot (indexchanged) 
      smg->restore (rows, NULL, NULL);
   
   % BUG HERE 
    if (indexchanged)
      if (index > LINES - 4)
        lines = lines[[1:]];
    % when words ar has been changed and index = 1
    }
}

private define inscompletion (is, s, line)
{
  variable chr = getch ();

  if (any ([keys->CTRL_l] == chr))
    linecompletion (s, line);
}

insfuncs.inscompletion = &inscompletion;

private define wordcompletion (is, s, line)
{
  variable
    word,
    chr,
    words,
    start,
    rows = Integer_Type[0],
    indexchanged = 0,
    index = 1,
    origlen = strlen (@line),
    col = s._index - 1,
    iwchars = [MAPS, ['0':'9'], '_'];

  word = fpart_of_word (s, @line, col, &start);

  forever
    {
    ifnot (indexchanged)
      words = pcre->find_unique_words_in_lines (s.lines, word, NULL);
          
    ifnot (length (words))
      if (length (rows))
        {
        smg->restore (rows, s.ptr, 1);
        return;
        }

    indexchanged = 0;

    if (index > length (words))
      index = length (words);

    rows = widg->pop_up (words, s.ptr[0], s.ptr[1] + 1, index);

    smg->setrcdr (s.ptr[0], s.ptr[1]);

    chr = getch ();

    if (any (keys->rmap.backspace == chr))
      {
      if (1 == strlen (word))
        {
        smg->restore (rows, s.ptr, 1);
        return;
        }
      else
        word = substr (word, 1, strlen (word) - 1);
      
      smg->restore (rows, NULL, NULL);
      continue;
      }

    if (any ([' ', '\r'] == chr))
      {
      smg->restore (rows, NULL, NULL);
      
      @line = substr (@line, 1, start) + words[index - 1] + substr (@line, s._index + 1, -1);
      
      waddline (s, getlinestr (s, @line, 1), 0, s.ptr[0]);
      
      variable len = strlen (@line);

      %bug here (if len > maxlen) (wrapped line)
      if (len < origlen)
        s._index -= (origlen - len);
      else if (len > origlen)
        s._index += len - origlen;

      s.ptr[1] = s._index; 

      draw_tail (s;chr = decode (substr (@line, s._index + 1, 1))[0]);
      
      return;
      }

    if (any ([keys->CTRL_n, keys->DOWN] == chr))
      {
      index++;
      if (index > length (words))
        index = 1;

      indexchanged = 1;
      }

    if (any ([keys->CTRL_p, keys->UP] == chr))
      {
      index--;
      ifnot (index)
        index = length (words);

      indexchanged = 1;
      }

    ifnot (any ([iwchars, keys->CTRL_n, keys->DOWN, keys->CTRL_p, keys->UP,
      keys->rmap.backspace, '\r', ' '] == chr))
      {
      smg->restore (rows, s.ptr, 1);
      return;
      }
    else
      word += char (chr);
    
    ifnot (indexchanged) 
      smg->restore (rows, NULL, NULL);
   
   % BUG HERE 
    if (indexchanged)
      if (index > LINES - 4)
        words = words[[1:]];
    % when words ar has been changed and index = 1
    }
}

insfuncs.wordcompletion = &wordcompletion;

private define on_lang_change (s)
{
  toplinedr (" -- insert --";row = s.ptr[0], col = s.ptr[1]);
}
 
private define getline (is, s, line)
{
  is = struct {@insfuncs, @is};
 
  forever
    {
    is.chr = getch (;on_lang = &on_lang_change, on_lang_args = s);

    if (033 == is.chr)
      {
      is.esc (s, line);
      return;
      }
 
    if ('\r' == is.chr)
      {
      is.cr (s, line);
      return;
      }
    
    if (keys->CTRL_n == is.chr)
      {
      is.wordcompletion (s, line);
      continue;
      }

    if (keys->CTRL_x == is.chr)
      {
      is.inscompletion (s, line);
      continue;
      }

    if (keys->UP == is.chr)
      {
      is.up (s, line);
      continue;
      }
 
    if (keys->DOWN == is.chr)
      {
      is.down (s, line);
      continue;
      }

    if (any (keys->rmap.left == is.chr))
      {
      is.left (s, line);
      continue;
      }
 
    if (any (keys->rmap.right == is.chr))
      {
      is.right (s, line);
      continue;
      }

    if (any (keys->CTRL_y == is.chr))
      {
      ifnot (strlen (is.prev_l))
        continue;

      is.completeline (s, line, is.prev_l);
      continue;
      }

    if (any (keys->CTRL_e == is.chr))
      {
      ifnot (strlen (is.next_l))
        continue;

      is.completeline (s, line, is.next_l);
      continue;
      }

    if (any (keys->rmap.home == is.chr))
      {
      is.bol (s, line);
      continue;
      }

    if (any (keys->rmap.end == is.chr))
      {
      is.eol (s, line);
      continue;
      }

    if (any (keys->rmap.backspace == is.chr))
      {
      is.del_prev (s, line);
      continue;
      }

    if (any (keys->rmap.delete == is.chr))
      {
      is.del_next (s, line);
      continue;
      }
 
    if ('\t' == is.chr)
      {
      is.ins_tab (s, line);
      continue;
      }

    if (' ' <= is.chr <= 126 || 902 <= is.chr <= 974)
      {
      is.ins_char (s, line);
      continue;
      }
    }
}

define insert (s, line, lnr, prev_l, next_l)
{
  topline (" -- insert --");

  variable
    self = @Insert_Type;

  self.lnr = lnr;
  self.modified = qualifier_exists ("modified");
  self.prev_l = prev_l;
  self.next_l = next_l;

  ifnot (qualifier_exists ("dont_draw_tail"))
    draw_tail (s);

  getline (self, s, line);
}
