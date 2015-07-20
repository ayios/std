variable app = "shell";
variable stdouttype = "ashell";
variable loaddir = path_dirname (__FILE__) + "/functions";
variable VED_LIB = 1;
variable SCRATCHBUF = 1;
variable SHELL_VED = 1;

define on_eval_err (err, code)
{
  () = array_map (Integer_Type, &fprintf, stderr, "%s\n", err);
  exit (code);
}

loadfrom ("os", "appclient", NULL, &on_eval_err);

init_shell ();
