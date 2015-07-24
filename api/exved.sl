loadfrom ("api", "runapp", NULL, &on_eval_err);

define _ved_ (argv)
{
  _precom_ ();
 
  variable fname = 1 == length (argv) ? SCRATCH : argv[1];
 
  shell_pre_header ("ved " + fname);

  runapp (["ved", fname], proc->defenv ();;__qualifiers ());
 
  shell_post_header ();
 
  draw (VED_CB);
}
