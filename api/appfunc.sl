APP.func = @Appfunc_Type;

define _exit_ ()
{
  variable rl = get_cur_rline ();

  ifnot (NULL == rl)
    rline->writehistory (rl.history, rl.histfile);

  variable searchhist = (@__get_reference ("s_history"));

  if (length (searchhist))
    rline->writehistory (list_to_array (searchhist), (@__get_reference ("s_histfile")));

  APP.func.at_exit ();

  exit_me (0);
}

define _at_exit_ (s)
{
}

APP.func.exit = &_exit_;
APP.func.at_exit = &_at_exit_;
