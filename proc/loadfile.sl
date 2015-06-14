private variable file = __argv[1];

__set_argc_argv (__argv[[1:]]);

() = evalfile (path_dirname (__FILE__) + "/../load");

define on_eval_err ()
{
  exit (1);
}

try
  loadfrom ("stdio", "ar_to_fp", NULL, NULL);
catch ParseError:
  on_eval_err ();

define on_eval_err (msg, err)
{
  () = ar_to_fp (msg, "%s\n", stderr);
  exit (err);
}
 
% for now NULL
loadfile (file, NULL, &on_eval_err);
