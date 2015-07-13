variable app = "shell";
variable stdouttype = "ashell";
variable loaddir = path_dirname (__FILE__) + "/functions";
variable VED_LIB = 1;

loadfrom ("ayios", "appproc", NULL, &on_eval_err);

init_shell ();
