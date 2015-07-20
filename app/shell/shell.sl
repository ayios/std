variable stdouttype = "ashell";
variable loaddir = path_dirname (__FILE__) + "/functions";
variable VED_LIB = 1;
variable SCRATCHBUF = 1;
variable SHELL_VED = 1;

loadfrom ("ayios", "appproc", NULL, &on_eval_err);

init_shell ();
