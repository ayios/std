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
  };

define insert ();

private define ins_tab (s, line)
{
  @line = substr (@line, 1, cf_._index) + repeat (" ", cf_._shiftwidth) +
    substr (@line, cf_._index + 1, - 1);

  cf_._index += cf_._shiftwidth;

  s.modified = 1;

  if (strlen (@line) < cf_._maxlen && cf_.ptr[1] + cf_._shiftwidth < cf_._maxlen)
    {
    cf_.ptr[1] += cf_._shiftwidth;
    waddline (getlinestr (@line, 1), 0, cf_.ptr[0]);
    draw_tail (;chr = decode (substr (@line, cf_._index + 1, 1))[0]);
    return;
    }

  is_wrapped_line = 1;

  variable i = 0;
  if (cf_.ptr[1] < cf_._maxlen)
    while (cf_.ptr[1]++, i++, (cf_.ptr[1] < cf_._maxlen && i < cf_._shiftwidth));
  else
    i = 0;
 
  cf_._findex += (cf_._shiftwidth - i);

  variable
    lline = getlinestr (@line, cf_._findex + 1 - cf_._indent);

  waddline (lline, 0, cf_.ptr[0]);
  draw_tail (;chr = decode (substr (@line, cf_._index + 1, 1))[0]);
}

insfuncs.ins_tab = &ins_tab;

private define ins_char (s, line)
{
  @line = substr (@line, 1, cf_._index) + char (s.chr) + substr (@line, cf_._index + 1, - 1);

  cf_._index++;

  s.modified = 1;

  if (strlen (@line) < cf_._maxlen && cf_.ptr[1] < cf_._maxlen)
    {
    cf_.ptr[1]++;
    waddline (getlinestr (@line, 1), 0, cf_.ptr[0]);
    draw_tail (;chr = decode (substr (@line, cf_._index + 1, 1))[0]);
    return;
    }
 
  is_wrapped_line = 1;
 
  if (cf_.ptr[1] == cf_._maxlen)
    cf_._findex++;

  variable
    lline = getlinestr (@line, cf_._findex + 1 - cf_._indent);

  if (cf_.ptr[1] < cf_._maxlen)
    cf_.ptr[1]++;

  waddline (lline, 0, cf_.ptr[0]);
  draw_tail (;chr = decode (substr (@line, cf_._index + 1, 1))[0]);
}

insfuncs.ins_char = &ins_char;

private define del_prev (s, line)
{
  variable
    lline,
    len;

  ifnot (cf_._index - cf_._indent)
    {
    ifnot (s.lnr)
      return;

   if (cf_.ptr[0] != cf_.rows[0])
     cf_.ptr[0]--;
   else
     cf_._ii--;

    s.lnr--;

    cf_._index = strlen (cf_.lines[s.lnr]);
    cf_.ptr[1] = cf_._index > cf_._maxlen ? cf_._maxlen : cf_._index;

    if (s.lnr == cf_._len)
      @line = cf_.lines[s.lnr];
    else
      @line = cf_.lines[s.lnr] + @line;
 
    cf_.lines[s.lnr] = @line;
    cf_.lines[s.lnr + 1] = NULL;
    cf_.lines = cf_.lines[wherenot (_isnull (cf_.lines))];
    cf_._len--;

    cf_._i = cf_._ii;

    cf_.draw (;dont_draw);

    len = strlen (@line);
    if (len > cf_._maxlen)
      {
      cf_._findex = len - cf_._maxlen;
      cf_.ptr[1] = cf_._maxlen - (len - cf_._index);
      is_wrapped_line = 1;
      }
    else
      cf_._findex = cf_._indent;

    lline = getlinestr (@line, cf_._findex + 1 - cf_._indent);

    waddline (lline, 0, cf_.ptr[0]);
    draw_tail (;chr = decode (substr (@line, cf_._index + 1, 1))[0]);
    s.modified = 1;
    return;
    }

  @line = substr (@line, 1, cf_._index - 1) + substr (@line, cf_._index + 1, - 1);

  len = strlen (@line);
 
  cf_._index--;

  ifnot (cf_.ptr[1])
    {
    if (cf_._index > cf_._maxlen)
      {
      cf_.ptr[1] = cf_._maxlen;
      cf_._findex = len - cf_._linlen;
      lline = substr (@line, cf_._findex + 1, -1);
      waddline (lline, 0, cf_.ptr[0]);
      draw_tail (;chr = decode (substr (@line, cf_._index, 1))[0]);
      return;
      }

    cf_._findex = cf_._indent;
    cf_.ptr[1] = len;
    waddline (@line, 0, cf_.ptr[0]);
    draw_tail (;chr = decode (substr (@line, cf_._index, 1))[0]);
    is_wrapped_line = 0;
    return;
    }

  cf_.ptr[1]--;

  if (cf_._index == len)
    waddlineat (" ", 0, cf_.ptr[0], cf_.ptr[1], cf_._maxlen);
  else
    {
    lline = substr (@line, cf_._index + 1, -1);
    waddlineat (lline, 0, cf_.ptr[0], cf_.ptr[1], cf_._maxlen);
    }
 
  draw_tail (;chr = decode (substr (@line, cf_._index + 1, 1))[0]);

  s.modified = 1;
}

insfuncs.del_prev = &del_prev;

private define del_next (s, line)
{
  ifnot (cf_._index - cf_._indent)
    if (1 == strlen (@line))
      if (" " == @line)
        {
        if (s.lnr < cf_._len)
          {
          @line += cf_.lines[s.lnr + 1];
          cf_.lines[s.lnr + 1 ] = NULL;
          cf_.lines = cf_.lines[wherenot (_isnull (cf_.lines))];
          cf_._len--;
          cf_._i = cf_._ii;
          cf_.draw (;dont_draw);
          s.modified = 1;
          waddline (getlinestr (@line, 1), 0, cf_.ptr[0]);
          draw_tail (;chr = decode (substr (@line, cf_._index + 1, 1))[0]);
          }

        return;
        }
      else
        {
        @line = " ";
        waddline (@line, 0, cf_.ptr[0]);
        draw_tail (;chr = decode (substr (@line, cf_._index + 1, 1))[0]);
        s.modified = 1;
        return;
        }

  if (cf_._index == strlen (@line))
    {
    if (s.lnr < cf_._len)
      {
      @line += getlinestr (cf_.lines[s.lnr + 1], 1);
      cf_.lines[s.lnr + 1 ] = NULL;
      cf_.lines = cf_.lines[wherenot (_isnull (cf_.lines))];
      cf_._len--;
      cf_._i = cf_._ii;
      cf_.draw (;dont_draw);
      s.modified = 1;
      if (is_wrapped_line)
        waddline (getlinestr (@line, cf_._findex + 1 - cf_._indent), 0, cf_.ptr[0]);
      else
        waddline (getlinestr (@line, 1), 0, cf_.ptr[0]);

      draw_tail (;chr = decode (substr (@line, cf_._index + 1, 1))[0]);
      }

    return;
    }

  @line = substr (@line, 1, cf_._index) + substr (@line, cf_._index + 2, - 1);

  if (is_wrapped_line)
    waddline (getlinestr (@line, cf_._findex + 1 - cf_._indent), 0, cf_.ptr[0]);
  else
    waddline (getlinestr (@line, 1), 0, cf_.ptr[0]);
 
  draw_tail (;chr = decode (substr (@line, cf_._index + 1, 1))[0]);
  s.modified = 1;
}

insfuncs.del_next = &del_next;

private define eol (s, line)
{
  variable
    lline,
    len = strlen (@line);
 
  cf_._index = len;

  if (len > cf_._linlen)
    {
    cf_._findex = len - cf_._linlen;
    lline = getlinestr (@line, cf_._findex + 1 - cf_._indent);
 
    waddline (lline, 0, cf_.ptr[0]);

    cf_.ptr[1] = cf_._maxlen;
    is_wrapped_line = 1;
    }
  else
    cf_.ptr[1] = len;

  draw_tail (;chr = decode (substr (@line, cf_._index + 1, 1))[0]);
}

insfuncs.eol = &eol;

private define bol (s, line)
{
  cf_._findex = cf_._indent;
  cf_._index = cf_._indent;
  cf_.ptr[1] = cf_._indent;
  waddline (getlinestr (@line, 1), 0, cf_.ptr[0]);
  draw_tail (;chr = decode (substr (@line, cf_._index + 1, 1))[0]);
  is_wrapped_line = 0;
}

insfuncs.bol = &bol;

private define completeline (s, line, comp_line)
{
  if (is_wrapped_line)
    return;

  if (cf_._index < strlen (comp_line) - cf_._indent)
    {
    @line = substr (@line, 1, cf_._index + cf_._indent) +
      substr (comp_line, cf_._index + 1 + cf_._indent, 1) +
      substr (@line, cf_._index + 1 + cf_._indent, -1);

    cf_._index++;

    if (cf_.ptr[1] + 1 < cf_._maxlen)
      cf_.ptr[1]++;

    waddline (getlinestr (@line, 1), 0, cf_.ptr[0]);
    draw_tail (;chr = decode (substr (@line, cf_._index + 1, 1))[0]);
    s.modified = 1;
    }
}

insfuncs.completeline = &completeline;

private define right (s, line)
{
  variable len = strlen (@line);

  if (cf_._index + 1 > len || 0 == len)
    return;

  cf_._index++;
 
  ifnot (cf_.ptr[1] == cf_._maxlen)
    cf_.ptr[1]++;
 
  if (cf_._index + 1 > cf_._maxlen)
    {
    cf_._findex++;
    is_wrapped_line = 1;
    }
 
  variable lline;

  if (cf_.ptr[1] + 1 > cf_._maxlen)
    {
    lline = getlinestr (@line, cf_._findex - cf_._indent);
    waddline (lline, 0, cf_.ptr[0]);
    }

  draw_tail (;chr = decode (substr (@line, cf_._index + 1, 1))[0]);
}

insfuncs.right = &right;

private define left (s, line)
{
  if (0 < cf_.ptr[1] - cf_._indent)
    {
    cf_._index--;
    cf_.ptr[1]--;
    draw_tail (;chr = decode (substr (@line, cf_._index + 1, 1))[0]);
    }
  else
    if (is_wrapped_line)
      {
      cf_._index--;
      variable lline;
      lline = getlinestr (@line, cf_._index - cf_._indent);
      waddline (lline, 0, cf_.ptr[0]);
      draw_tail (;chr = decode (substr (@line, cf_._index, 1))[0]);
      if (cf_._index - 1 == cf_._indent)
        is_wrapped_line = 0;
      }
}

insfuncs.left = &left;

private define down (s, line)
{
  if (s.lnr == cf_._len)
    return;

  cf_.lins[cf_.ptr[0] - cf_.rows[0]] = @line;
  cf_.lines[s.lnr] = @line;
 
  cf_._findex = cf_._indent;

  s.lnr++;

  s.prev_l = @line;
  if (s.lnr + 1 > cf_._len)
    s.next_l = "";
  else
    s.next_l = cf_.lines[s.lnr + 1];

  if (is_wrapped_line)
    {
    waddline (getlinestr (@line, 1), 0, cf_.ptr[0]);
    is_wrapped_line = 0;
    cf_.ptr[1] = cf_._maxlen;
    }

  cf_._index = cf_.ptr[1];

  @line = cf_.lines[s.lnr];

  variable len = strlen (@line);
 
  if (cf_._index > len)
    {
    cf_.ptr[1] = len ? len : cf_._indent;
    cf_._index = len ? len : cf_._indent;
    }
 
  if (cf_.ptr[0] < cf_.vlins[-1])
    {
    cf_.ptr[0]++;
    draw_tail (;chr = strlen (@line)
      ? cf_._index > cf_._indent
        ? decode (substr (@line, cf_._index, 1))[0]
        : decode (substr (@line, cf_._indent + 1, 1))[0]
      : ' ');

    return;
    }

  if (cf_.lnrs[-1] == cf_._len)
    return;

  ifnot (cf_.ptr[0] == cf_.vlins[-1])
    cf_.ptr[0]++;

  cf_._i++;

  variable chr = strlen (@line)
    ? cf_._index > cf_._indent
      ? decode (substr (@line, cf_._index, 1))[0]
      : decode (substr (@line, cf_._indent + 1, 1))[0]
    : ' ';
  cf_.draw (;chr = chr);
}

insfuncs.down = &down;

private define up (s, line)
{
  variable i = v_lnr ('.');

  ifnot (s.lnr)
    return;

  cf_.lins[cf_.ptr[0] - cf_.rows[0]] = @line;
  cf_.lines[s.lnr] = @line;

  s.lnr--;

  s.next_l = @line;
  if (-1 == s.lnr - 1)
    s.prev_l = "";
  else
    s.prev_l = cf_.lines[s.lnr - 1];

  cf_._findex = cf_._indent;

  if (is_wrapped_line)
    {
    waddline (getlinestr (@line, cf_._indent + 1 - cf_._indent), 0, cf_.ptr[0]);
    is_wrapped_line = 0;
    cf_.ptr[1] = cf_._maxlen;
    }
 
  cf_._index = cf_.ptr[1];
 
  @line = cf_.lines[s.lnr];
 
  variable len = strlen (@line);

  if (cf_._index > len)
    {
    cf_.ptr[1] = len ? len : cf_._indent;
    cf_._index = len ? len : cf_._indent;
    }
 
  if (cf_.ptr[0] > cf_.vlins[0])
    {
    cf_.ptr[0]--;
    draw_tail (;chr = strlen (@line)
      ? cf_._index > cf_._indent
        ? decode (substr (@line, cf_._index, 1))[0]
        : decode (substr (@line, cf_._indent + 1, 1))[0]
      : ' ');
    return;
    }
 
  cf_._i = cf_._ii - 1;
 
  variable chr = strlen (@line)
    ? cf_._index > cf_._indent
      ? decode (substr (@line, cf_._index, 1))[0]
      : decode (substr (@line, cf_._indent + 1, 1))[0]
    : ' ';

  cf_.draw (;chr = chr);
}

insfuncs.up = &up;

private define cr (s, line)
{
  variable
    prev_l,
    next_l,
    lline;

  if (strlen (@line) == cf_._index)
    {
    cf_.lines[s.lnr] = @line;

    cf_._chr = 'o';
 
    (@pagerf[string ('o')]) (;modified);
    return;
    }
  else
    {
    lline = 0 == cf_._index - cf_._indent ? " " : substr (@line, 1, cf_._index);
    @line = substr (@line, cf_._index + 1, -1);

    prev_l = lline;

    if (s.lnr + 1 >= cf_._len)
      next_l = "";
    else
      next_l = v_lin (cf_.ptr[0] + 1);

    cf_.ptr[1] = cf_._indent;
    cf_._i = cf_._ii;

    if (cf_.ptr[0] == cf_.rows[-2] && cf_.ptr[0] + 1 > cf_._avlins)
      cf_._i++;
    else
      cf_.ptr[0]++;

    ifnot (s.lnr)
      cf_.lines = [lline, @line, cf_.lines[[s.lnr + 1:]]];
    else
      cf_.lines = [cf_.lines[[:s.lnr - 1]], lline, @line, cf_.lines[[s.lnr + 1:]]];

    cf_._len++;
 
    cf_.draw (;dont_draw);
 
    @line = repeat (" ", cf_._indent) + @line;
    waddline (@line, 0, cf_.ptr[0]);
    draw_tail (;chr = decode (substr (@line, cf_._index + 1, 1))[0]);
    cf_._index = cf_._indent;
    cf_._findex = cf_._indent;

    insert (line, s.lnr + 1, prev_l, next_l;modified, dont_draw_tail);
    }
}

insfuncs.cr = &cr;

private define esc (s, line)
{
  getchar_lang = input->get_en_lang;

  if (0 < cf_.ptr[1] - cf_._indent)
    cf_.ptr[1]--;

  if (0 < cf_._index - cf_._indent)
    cf_._index--;
 
  if (s.modified)
    {
    cf_.lins[cf_.ptr[0] - cf_.rows[0]] = @line;
    cf_.lines[s.lnr] = @line;

    set_modified ();
 
    cf_.st_.st_size = calcsize (cf_.lines);
    }
 
  topline (" -- PAGER --");
  draw_tail ();
}

insfuncs.esc = &esc;

private define getline (self, line)
{
  self = struct {@insfuncs, @self};
 
  forever
    {
    self.chr = getch ();

    if (any (keys->rmap.changelang == self.chr))
      {
      getchar_lang = string (getchar_lang) == "&en_getch" ? input->get_el_lang : getchar_lang;
      topline_dr (" -- INSERT --");
      continue;
      }

    if (033 == self.chr)
      {
      self.esc (line);
      return;
      }
 
    if ('\r' == self.chr)
      {
      self.cr (line);
      return;
      }

    if (keys->UP == self.chr)
      {
      self.up (line);
      continue;
      }
 
    if (keys->DOWN == self.chr)
      {
      self.down (line);
      continue;
      }

    if (any (keys->rmap.left == self.chr))
      {
      self.left (line);
      continue;
      }
 
    if (any (keys->rmap.right == self.chr))
      {
      self.right (line);
      continue;
      }

    if (any (keys->CTRL_y == self.chr))
      {
      ifnot (strlen (self.prev_l))
        continue;

      self.completeline (line, self.prev_l);
      continue;
      }

    if (any (keys->CTRL_e == self.chr))
      {
      ifnot (strlen (self.next_l))
        continue;

      self.completeline (line, self.next_l);
      continue;
      }

    if (any (keys->rmap.home == self.chr))
      {
      self.bol (line);
      continue;
      }

    if (any (keys->rmap.end == self.chr))
      {
      self.eol (line);
      continue;
      }

    if (any (keys->rmap.backspace == self.chr))
      {
      self.del_prev (line);
      continue;
      }

    if (any (keys->rmap.delete == self.chr))
      {
      self.del_next (line);
      continue;
      }
 
    if ('\t' == self.chr)
      {
      self.ins_tab (line);
      continue;
      }

    if (' ' <= self.chr <= 126 || 902 <= self.chr <= 974)
      {
      self.ins_char (line);
      continue;
      }
    }
}

define insert (line, lnr, prev_l, next_l)
{
  topline (" -- INSERT --");

  variable
    self = @Insert_Type;

  self.lnr = lnr;
  self.modified = qualifier_exists ("modified");
  self.prev_l = prev_l;
  self.next_l = next_l;

  ifnot (qualifier_exists ("dont_draw_tail")) 
    draw_tail ();

  getline (self, line);
}
