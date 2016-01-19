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
private variable pj;
private variable ft = is_arg ("--ft=", __argv);

ifnot (NULL == ft)
  {
  ft = strchop (__argv[ft], '=', 0);
  if (2 == length (ft))
    {
    ft = ft[1];

    ifnot (any (ft == assoc_get_keys (FTYPES)))
      ft = NULL;
    }
  else
    ft = NULL;
  }

if (__stdin)
  {
  if (ft == NULL)
    ft = "txt";

  fn = VED_DIR + "/__stdin." + ft;

  __stdin = IO.readfd (fileno (stdin));

  ifnot (NULL == __stdin)
    () = String.write(fn, __stdin);

  init_ftype (ft).ved (fn);

  APP.func.exit ();
  }

if (1 == __argc)
  {
  SCRATCH_VED.ved (SCRATCH);
  APP.func.exit ();
  }

pj = is_arg ("--pj=", __argv);

ifnot (NULL == pj)
  {
  pj = strchop (__argv[pj], '=', 0);

  if (1 == length (pj))
    {
    IO.tostderr ("Error loading project");
    APP.func.exit ();
    }

  pj = strchopr (pj[1], ',', 0);
  _for fn (0, length (pj) - 1)
    ifnot (path_is_absolute (pj[fn]))
      pj[fn] = path_concat (getcwd, pj[fn]);

  PROJECT_VED ([NULL, pj];ftype = ft);

  del_wind ("a");
  get_cur_buf ().ved (pj[-1]);
  APP.func.exit ();
  }

fn = __argv[-1];
if (NULL == ft)
  ft = get_ftype (fn);

init_ftype (ft).ved (fn);
