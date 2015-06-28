private define init_commands ()
{
  variable i;
  variable a = Assoc_Type[Argvlist_Type, @Argvlist_Type];
  variable keys = assoc_get_keys (clinef);

  _for i (0, length (keys) - 1)
    {
    a[keys[i]] = @Argvlist_Type;
    a[keys[i]].func = clinef[keys[i]];
    }

  return a;
}

private define tabhook (s)
{
  ifnot (any (s.argv[0] == ["b", "bd"]))
    return -1;
 
  variable v = qualifier ("ved");
  variable bufnames = VED_BUFNAMES[wherenot (v._absfname == VED_BUFNAMES)];
  variable args = array_map (String_Type, &sprintf, "%s void ", bufnames);
  return rline->argroutine (s;args = args, accept_ws);
}

define rlineinit ()
{
  variable rl;

  if (VED_EDITOTHER)
    rl = rline->init (&init_commands;
      histfile = HISTDIR + "/" + string (getuid ()) + "vedhistory",
      historyaddforce = 1,
      tabhook = &tabhook,
      totype = "Func_Type");
  else
    rl = rline->init (&init_commands;
      histfile = HISTDIR + "/" + string (getuid ()) + "vedhistory",
      historyaddforce = 1,
      totype = "Func_Type");

  return rl;
}
