define _idle_ (argv)
{
  smg->suspend ();
  input->at_exit ();

  variable retval = go_idled ();
 
  ifnot (retval)
    {
    smg->resume ();
    return;
    }

 (@__get_reference ("_exit_")) (;;__qualifiers  ());
}

