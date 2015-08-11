private variable func = [&smg->setrcdr, &smg->setrc];

private define _draw_ (s)
{
  if (-1 == s._len)
    {
    s.lins = [" "];
    s.lnrs = [0];
    s._ii = 0;
 
    smg->aratrcaddnstrdr ([repeat (" ", COLUMNS), tail (s)], [0, VED_INFOCLRFG],
      [s.rows[0], s.rows[-1]], [0, 0], s.rows[0], 0, COLUMNS);

    return;
    }

  s.lnrs = Integer_Type[0];
  s.lins = String_Type[0];

  variable
    i = s.rows[0],
    ar = String_Type[0];

  s._ii = s._i;

  while (s._i <= s._len && i <= s.rows[-2])
    {
    s.lnrs = [s.lnrs, s._i];
    s.lins = [s.lins, s.lines[s._i]];
    s._i++;
    i++;
    }

  s.vlins = [s.rows[0]:s.rows[0] + length (s.lins) - 1];

  s._i = s._i - (i) + s.rows[0];

  if (-1 == s._i)
    s._i = 0;

  if (s.ptr[0] >= i)
    s.ptr[0] = i - 1;

  ar = array_map (String_Type, &substr, s.lins, 1, s._maxlen);

  if (length (ar) < length (s.rows) - 1)
    {
    variable t = String_Type[length (s.rows) - length (ar) - 1];
    t[*] = " ";
    ar = [ar, t];
    }
 
  ar = [ar, tail (s;;__qualifiers ())];

  _for i (0, length (ar) - 1)
    SMGIMG[s.rows[i]] = {[ar[i]], [s.clrs[i]], [s.rows[i]], [s.cols[i]]};

  smg->aratrcaddnstr (ar, s.clrs, s.rows, s.cols, COLUMNS);

  s.lexicalhl (ar[[:-2]], s.vlins);
 
  (@func[qualifier_exists ("dont_draw")]) (s.ptr[0], s.ptr[1]);
}

private define autoindent ();

private define lexicalhl ()
{
  loop (3)
    pop ();
}

private define _vedloopcallback_ (s)
{
  (@VED_PAGER[string (s._chr)]) (s);
}

private define _vedloop_ (s)
{
  forever
    {
    s = get_cur_buf ();
    VEDCOUNT = -1;
    s._chr = getch ();
 
    if ('0' <= s._chr <= '9')
      {
      VEDCOUNT = "";
 
      while ('0' <= s._chr <= '9')
        {
        VEDCOUNT += char (s._chr);
        s._chr = getch ();
        }

      VEDCOUNT = integer (VEDCOUNT);
      }

    s.vedloopcallback ();
 
    if (':' == s._chr && 0 == VED_ISONLYPAGER && VED_RLINE)
      {
      if (RECORD)
        RECORD = 0;

      topline (" -- command line --");
      rline->set (get_cur_rline ());
      rline->readline (get_cur_rline ();
        ved = s, draw = (@__get_reference ("SCRATCH")) == s._absfname ? 0 : 1);

      if ('!' == get_cur_rline ().argv[0][0] && (@__get_reference ("SCRATCH")) == s._absfname)
        {
        (@__get_reference ("draw")) (s);
        continue;
        }

      topline (" -- pager --");
      smg->setrcdr (s.ptr[0], s.ptr[1]);
      }

    if ('q' == s._chr && VED_ISONLYPAGER)
      break;
    }
}

define deftype ()
{
  variable type = struct
    {
    _indent = 0,
    _shiftwidth = 4,
    _maxlen = COLUMNS,
    _autochdir = 1,
    _autoindent = 0,
    autoindent = &autoindent,
    draw = &_draw_,
    lexicalhl = &lexicalhl,
    vedloop = &_vedloop_,
    vedloopcallback = &_vedloopcallback_,
    };

  return type;
}
