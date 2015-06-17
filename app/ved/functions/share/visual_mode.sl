private variable vis = struct
  {
  clr = 18,
  l_mode,
  l_down,
  l_up,
  c_mode,
  c_left,
  c_right,
  at_exit,
  };

private define v_unhl_line (vs, s, index)
{
  smg->hlregion (0, vs.vlins[index], 0, 1, s._maxlen);
}

private define v_hl_ch (vs, s)
{
  variable i;
  _for i (0, length (vs.vlins) - 1)
    {
    v_unhl_line (vs, s, i);
    smg->hlregion (vs.clr, vs.vlins[i], vs.col[i], 1, strlen (vs.sel[i]));
    }

  smg->refresh ();
}

private define v_hl_line (vs, s)
{
  variable i;
  _for i (0, length (vs.vlins) - 1)
    ifnot (-1 == vs.vlins[i])
      if (vs.vlins[i] == s.rows[-1])
        break;
      else if (vs.vlins[i] < s.rows[0])
        continue;
      else
        smg->hlregion (vs.clr, vs.vlins[i], 0, 1,
          s._maxlen > vs.linlen[i] ? vs.linlen[i] : s._maxlen);

  smg->refresh ();
}

private define v_l_up (vs, s)
{
  ifnot (v_lnr (s, '.'))
    return;

  if (s.ptr[0] == s.vlins[0]) %for now FIXME
    {
    vs._i--;
    s.draw ();

    vs.lines = [v_lin (s, '.'), vs.lines];
    vs.lnrs = [vs.lnrs[0] - 1, vs.lnrs];
    vs.vlins++;
    vs.vlins = [vs.ptr[0], vs.vlins];
    vs.linlen = [strlen (vs.lines[0]), vs.linlen];
    v_hl_line (vs, s);
    return;
    }
 
  s.ptr[0]--;

  if (vs.lnrs[-1] > vs.startrow)
    {
    v_unhl_line (vs, s, -1);
    vs.lines = vs.lines[[:-2]];
    vs.lnrs = vs.lnrs[[:-2]];
    vs.vlins = vs.vlins[[:-2]];
    vs.linlen = vs.linlen[[:-2]];
    }
  else
    {
    vs.lines = [v_lin (s, '.'), vs.lines];
    vs.lnrs = [vs.lnrs[0] - 1, vs.lnrs];
    vs.vlins = [s.ptr[0], vs.vlins];
    vs.linlen = [strlen (vs.lines[0]), vs.linlen];
    }

  v_hl_line (vs, s);
}

vis.l_up = &v_l_up;

private define v_l_down (vs, s)
{
  if (v_lnr (s, '.') == s._len)
      return;

  if (s.ptr[0] == s.vlins[-1]) %for now FIXME
    {
    s._i++;
 
    s.draw ();
    vs.lines = [vs.lines, v_lin (s, '.')];
    vs.lnrs = [vs.lnrs, vs.lnrs[-1] + 1];
    vs.vlins--;
    vs.vlins = [vs.vlins, s.ptr[0]];
    vs.linlen = [vs.linlen, strlen (vs.lines[-1])];
    v_hl_line (vs, s);
    return;
    }

  s.ptr[0]++;

  if (vs.lnrs[0] < vs.startrow)
    {
    v_unhl_line (vs, s, 0);
    vs.lines = vs.lines[[1:]];
    vs.lnrs = vs.lnrs[[1:]];
    vs.vlins = vs.vlins[[1:]];
    vs.linlen = vs.linlen[[1:]];
    }
  else
    {
    vs.lines = [vs.lines, v_lin (s, '.')];
    vs.lnrs = [vs.lnrs, vs.lnrs[-1] + 1];
    vs.vlins = [vs.vlins, s.ptr[0]];
    vs.linlen = [vs.linlen, strlen (vs.lines[-1])];
    }

  v_hl_line (vs, s);
}

vis.l_down = &v_l_down;

private define v_linewise_mode (vs, s)
{
  variable
    chr;
 
  vs.linlen = [strlen (vs.lines[0])];

  v_hl_line (vs, s);

  while (chr = getch (), any (['y', 'd', keys->DOWN, keys->UP] == chr))
    {
    if (chr == keys->DOWN)
      {
      vs.l_down (s);
      continue;
      }

    if (chr == keys->UP)
      {
      vs.l_up (s);
      continue;
      }

    if ('y' == chr)
      {
      REG["\""] = strjoin (vs.lines, "\n") + "\n";
      seltoX (strjoin (vs.lines, "\n") + "\n");
      return 1;
      }

    if ('d' == chr)
      {
      REG["\""] = strjoin (vs.lines, "\n") + "\n";
      seltoX (strjoin (vs.lines, "\n") + "\n");
      s.lines[vs.lnrs] = NULL;
      s.lines = s.lines[wherenot (_isnull (s.lines))];
      s._len = length (s.lines) - 1;

      s._i = vs.lnrs[0] ? vs.lnrs[0] - 1 : 0;
      s.ptr[0] = s.rows[0];
      s.ptr[1] = s._indent;
      s._index = s._indent;
      s._findex = s._indent;
 
      if (-1 == s._len)
        {
        variable indent = repeat (" ", s._indent);
        s.lines = [sprintf ("%s\000", indent)];
        s._len = 0;
        }
 
      set_modified (s);
      s.draw ();
      return 0;
      }
    }

  return 1;
}

vis.l_mode = &v_linewise_mode;

private define v_c_left (vs, s, cur)
{
  variable retval = p_left (s);

  if (-1 == retval)
    return;
 
  vs.index[cur]--;

  if (retval)
    {
    variable lline;
    if (s._is_wrapped_line)
      {
      lline = getlinestr (s, vs.lines[cur], s._findex + 1 - s._indent);
      vs.wrappedmot--;
      }
    else
      lline = vs.lines[cur];

    waddline (s, lline, 0, s.ptr[0]);
    }

  if (s.ptr[1] < vs.startcol[cur])
    vs.col[cur] = s.ptr[1];
  else
    vs.col[cur] = vs.startcol[cur];

% if (s.ptr[1])
%   if (s.ptr[1] < vs.startcol[cur])
%     if (s._is_wrapped_line)
%       vs.col[cur] = vs.startcol[cur] - vs.wrappedmot;
%     else
%       vs.col[cur] = s.ptr[1];
%   else
%     if (s._is_wrapped_line)
%       vs.col[cur] = vs.startcol[cur] - vs.wrappedmot;
%     else
%      vs.col[cur] = vs.startcol[cur];
% else
%   if (s._is_wrapped_line)
%     vs.col[cur] = (l++, l - strlen (vs.sel[cur]) + 1);
%   else
%     vs.col[cur] = s.ptr[1];

  %s.col[cur] = s.ptr[1] < vs.startcol[cur] ? s.ptr[1] : vs.startcol[cur];
 % vs.col[cur] = s.ptr[1] < vs.startcol[cur]
 %   ? s._is_wrapped_line
 %     ? 0 == s.ptr[1]
 %       ? vs.startcol[cur] - vs.wrappedmot
 %       : vs.startcol[cur]
 %     : s.ptr[1]
 %   : s._is_wrapped_line
 %     ? vs.startcol[cur] - vs.wrappedmot
 %     : vs.startcol[cur];
  vs.col[cur] = s.ptr[1] < vs.startcol[cur]
    ? s._is_wrapped_line
      ? vs.startcol[cur] - vs.wrappedmot
      : s.ptr[1]
    : s._is_wrapped_line
      ? vs.startcol[cur] - vs.wrappedmot
      : vs.startcol[cur];
  vs.col[cur] = s.ptr[1] < vs.startcol[cur]
    ? s._is_wrapped_line
      ? vs.startcol[cur] - strlen (vs.sel[cur]) + 1
      : s.ptr[1]
    : s._is_wrapped_line
      ? vs.startcol[cur] - vs.wrappedmot
      : vs.startcol[cur];

  if (vs.index[cur] >= vs.startindex[cur])
    vs.sel[cur] = substr (vs.sel[cur], 1, strlen (vs.sel[cur]) - 1);
  else
    vs.sel[cur] = substr (vs.lines[cur], vs.index[cur] + 1, 1) + vs.sel[cur];

  v_hl_ch (vs, s);
}

vis.c_left = &v_c_left;

private define v_c_right (vs, s, cur)
{
  variable retval = p_right (s, vs.linlen[-1]);

  if (-1 == retval)
    return;
 
  vs.index[cur]++;

  if (retval)
    {
    variable lline = getlinestr (s, vs.lines[cur], s._findex + 1 - s._indent);
    waddline (s, lline, 0, s.ptr[0]);
    s._is_wrapped_line = 1;
    vs.wrappedmot++;
    }

  vs.col[cur] = s.ptr[1] < vs.startcol[cur]
    ? s.ptr[1]
    : s._is_wrapped_line
      ? vs.startcol[cur] - vs.wrappedmot
      : vs.startcol[cur];
 
  if (vs.index[cur] <= vs.startindex[cur])
    vs.sel[cur] = substr (vs.sel[cur], 2, -1);
  else
    vs.sel[cur] += substr (vs.lines[cur], vs.index[cur] + 1, 1);

  v_hl_ch (vs, s);
}

vis.c_right = &v_c_right;

private define v_char_mode (vs, s)
{
  variable
    chr,
    cur = 0;
 
  vs.startcol = [vs.col[0]];
  vs.startindex = [vs.index];
  vs.index = [vs.index];

  vs.sel = [substr (vs.lines[cur], vs.index[cur] + 1, 1)];

  v_hl_ch (vs, s);

  while (chr = getch (), any (['y', keys->DOWN, keys->RIGHT, keys->UP, keys->LEFT]
    == chr))
    {
    if (keys->RIGHT == chr)
      {
      vs.c_right (s, cur);
      continue;
      }

    if (keys->LEFT == chr)
      {
      vs.c_left (s, cur);
      continue;
      }

    if ('y' == chr)
      {
      REG["\""] = strjoin (vs.sel, "\n");
      seltoX (strjoin (vs.sel, "\n"));
      vs.index = vs.startindex[cur];
      vs.col = vs.startcol[cur];
      return;
      }
    }

  vs.index = vs.startindex[cur];
  vs.col = [vs.startcol[cur]];
}

vis.c_mode = &v_char_mode;

private define v_atexit (vs, s, draw)
{
  topline ("-- pager --");
 
  if (draw)
    {
    s._i = s._ii;
    s.ptr[1] = vs.col[0];
    s._index = vs.index;
 
    s.draw ();
    }
}

vis.at_exit = &v_atexit;

private define v_init (s)
{
  toplinedr ("-- visual --");

  return struct
    {
    startrow,
    startcol,
    wrappedmot = 0,
    startindex,
    findex = s._findex,
    index = s._index,
    col = [s.ptr[1]],
    vlins = [s.ptr[0]],
    lnrs = [v_lnr (s, '.')],
    linlen = [v_linlen (s, '.')],
    lines = [v_lin (s, '.')],
    sel,
    @vis,
    };
}

private define vis_mode (s)
{
  variable
    draw = 1,
    vs = v_init (s);
 
  vs.startrow = vs.lnrs[0];

  if (s._chr == 'v')
    vs.c_mode (s);
  else
    draw = vs.l_mode (s);

  vs.at_exit (s, draw);
}

pagerf[string ('v')] = &vis_mode;
pagerf[string ('V')] = &vis_mode;
