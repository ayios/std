private define my_commands ()
{
  variable i;
  variable a = (@__get_reference ("init_commands")) (;ex);
  variable keys = assoc_get_keys (VED_CLINE);

  _for i (0, length (keys) - 1)
    {
    a[keys[i]] = @Argvlist_Type;
    a[keys[i]].func = VED_CLINE[keys[i]];
    a[keys[i]].type = "Func_Type";
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

   rl = rline->init (&my_commands;;struct {
      histfile = HISTDIR + "/" + string (getuid ()) + "vedhistory",
      historyaddforce = 1,
      tabhook = &tabhook,
      %totype = "Func_Type",
      @__qualifiers
      }
      );

  (@__get_reference ("iarg")) = length (rl.history);

  return rl;
}
