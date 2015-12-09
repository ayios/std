load.from ("api", "runapp", NULL;err_handler = &__err_handler__);

define __ved (argv)
{
  precom ();

  variable fname = 1 == length (argv) ? SCRATCH : argv[1];

  if ("-" == fname)
    fname = STDOUT;

  shell_pre_header ("ved " + fname);

  runapp (["ved", fname], proc->defenv ();;__qualifiers ());

  shell_post_header ();

  draw (get_cur_buf ());
}
