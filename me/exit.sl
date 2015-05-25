private define at_exit ()
{
  smg->reset ();
  input->at_exit ();
}

public define on_eval_err (ar, exit_code)
{
  at_exit ();
 
  array_map (&tostdout, ar);

  exit (exit_code);
}

public define exit_me ()
{
  at_exit ();
  exit (0);
}
