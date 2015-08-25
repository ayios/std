APP.func = @Appfunc_Type;

define _exit_ (argv)
{
  variable rl = get_cur_rline ();

  ifnot (NULL == rl)
    rline->writehistory (rl.history, rl.histfile);

  APP.func.at_exit ();
 
  exit_me (0);
}

define _at_exit_ (s)
{
}

APP.func.exit = &_exit_;
APP.func.at_exit = &_at_exit_;
