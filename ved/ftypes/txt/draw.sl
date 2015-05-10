private variable func = [&smg->setrcdr, &smg->setrc];

define draw (s)
{
  if (-1 == cf_._len)
    {
    cf_.lins = [" "];
    cf_.lnrs = [0];
 
    waddlinear_dr ([repeat (" ", COLUMNS), tail ()], [0, INFOCLRFG],
      [cf_.rows[0], cf_.rows[-1]], [0, 0], [cf_.rows[0], 0], COLUMNS);

    return;
    }

  cf_.lnrs = Integer_Type[0];
  cf_.lins = String_Type[0];

  variable
    i = cf_.rows[0],
    ar = String_Type[0];

  cf_._ii = cf_._i;

  while (cf_._i <= cf_._len && i <= cf_.rows[-2])
    {
    cf_.lnrs = [cf_.lnrs, cf_._i];
    cf_.lins = [cf_.lins, cf_.lines[cf_._i]];
    cf_._i++;
    i++;
    }
  cf_.vlins = [cf_.rows[0]:cf_.rows[0] + length (cf_.lins) - 1];

  cf_._i = cf_._i - (i) + cf_.rows[0];

  if (-1 == cf_._i)
    cf_._i = 0;

  if (cf_.ptr[0] >= i)
    cf_.ptr[0] = i - 1;

  ar = array_map (String_Type, &substr, cf_.lins, 1, cf_._maxlen);

  if (length (ar) < length (cf_.rows) - 1)
    {
    variable t = String_Type[length (cf_.rows) - length (ar) - 1];
    t[*] = " ";
    ar = [ar, t];
    }
 
  ar = [ar, tail (;;__qualifiers ())];

  _for i (0, length (ar) - 1)
    IMG[cf_.rows[i]] = {[ar[i]], [cf_.clrs[i]], [cf_.rows[i]], [cf_.cols[i]]};

  waddlinear (ar, cf_.clrs, cf_.rows, cf_.cols, COLUMNS);
  cf_.lexicalhl (ar[[:-2]], cf_.vlins);
  
  (@func[qualifier_exists ("dont_draw")]) (cf_.ptr[0], cf_.ptr[1]);
}
