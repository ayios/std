load.from ("file", "ln", NULL;err_handler = &__err_handler__);

Dir->Fun ("eval_", NULL;FuncRefName = "evaldir");

define main ()
{
  variable
    i,
    source,
    dest,
    opts = struct
      {
      backup = NULL,
      suffix = "~",
      interactive = NULL,
      force = NULL,
      symbolic = NULL,
      nodereference = NULL,
      },
    c = cmdopt_new (&_usage);

  c.add ("backup", &opts.backup);
  c.add ("suffix", &opts.suffix;type="string");
  c.add ("i|interactive", &opts.interactive);
  c.add ("s|symbolic", &opts.symbolic);
  c.add ("no-dereference", &opts.nodereference);
  c.add ("f|force", &opts.force);
  c.add ("v|verbose", &verboseon);
  c.add ("help", &_usage);
  c.add ("info", &info);

  i = c.process (__argv, 1);

  if (i + 2 > __argc)
    {
    IO.tostderr (sprintf ("%s: argument is required", __argv[0]));
    exit_me (1);
    }

  source = Dir.eval (__argv[i];dont_change);
  dest = Dir.eval (__argv[i+1];dont_change);

  exit_me (ln (source, dest, opts));
}
