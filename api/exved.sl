loadfrom ("api", "runapp", NULL, &on_eval_err);

define __ved (argv)
{
  precom ();

  variable fname = 1 == length (argv) ? SCRATCH : argv[1];

  shell_pre_header ("ved " + fname);

  runapp (["ved", fname], proc->defenv ();;__qualifiers ());

  shell_post_header ();

  draw (get_cur_buf ());
}
