load.from ("api", "apiInit", 1;err_handler = &__err_handler__);

APP = api->init (__FILE__;
  vedrline = 1,
  stdout = 0,
  vedlib = 0,
  excom = 1,
  os = 0,
  );

load.from ("api", "clientapi", NULL;err_handler = &__err_handler__);

private variable __stdin = any (__argv == "-");
private variable fn;
private variable ft;

if (1 == __argc)
  SCRATCH_VED.ved (SCRATCH);
else
  {
  ft = is_arg ("--ft=", __argv);
  ifnot (NULL == ft)
    {
    ft = strchop (__argv[ft], '=', 0);
    if (2 == length (ft))
      {
      ft = ft[1];

      ifnot (any (ft == assoc_get_keys (FTYPES)))
        ft = NULL;
      }
    }

  if (__stdin)
    {
    if (ft == NULL)
      ft = "txt";

    fn = VED_DIR + "/__stdin." + ft;
    __stdin = read_fd (fileno (stdin));
    ifnot (NULL == __stdin)
      () = writestring (fn, __stdin);
    }
  else
    {
    fn = __argv[-1];
    if (NULL == ft)
      ft = get_ftype (fn);
    }

  init_ftype (ft).ved (fn);
  }
