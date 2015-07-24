private variable file = __argv[1];

__set_argc_argv (__argv[[1:]]);

() = evalfile (path_dirname (__FILE__) + "/../load");

define exit_me (code)
{
  exit (code);
}

define tostderr (str)
{
  () = fprintf (stderr, "%s\n", str);
}

define on_eval_err (err, code)
{
  () = array_map (Integer_Type, &fprintf, stderr, "%s\n", err);
  exit (code);
}

% for now NULL
loadfile (file, NULL, &on_eval_err);
