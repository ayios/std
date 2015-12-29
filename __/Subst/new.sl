private define new (s, pat, sub)
{
  try
    {
    struct
      {
      patstr = pat,
      numchanges = 0,
      fname = qualifier ("fname", " "),
      lnronfile = qualifier ("lnronfile", 0),
      global = qualifier ("global"),
      askwhensubst = qualifier ("askwhensubst", 1),
      askonsubst = qualifier ("askonsubst", s.askonsubst),
      pat = pcre_compile (pat, qualifier ("pcreopts", 0)),
      substlist = s.assign (sub),
      new_lines = s.new_lines,
      };
    }
  catch ParseError:
    return __get_exception_info ().message, NULL;
}
