private variable func = [&smg->setrcdr, &smg->setrc];

private define draw (s)
{
  if (-1 == s._len)
    {
    s.lins = [" "];
    s.lnrs = [0];
 
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

private define _vedloop_ (s)
{
  pop ();
}

private define _vedloopcallback_ (s)
{
  pop ();
}

define initvedloop ();

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
    draw = &draw,
    lexicalhl = &lexicalhl,
    vedloop = &_vedloop_,
    vedloopcallback = &_vedloopcallback_,
    };

  if (VED_RLINE)
    {
    loadfile ("vedloop", NULL, &on_eval_err);
    variable loopfuncs = initvedloop ();
    type.vedloop = loopfuncs.vedloop;
    type.vedloopcallback = loopfuncs.vedloopcallback;
    }

  return type;
}
