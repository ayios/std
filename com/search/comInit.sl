COMDIR = path_dirname (__FILE__);
verboseon ();
loadfrom ("com/" + com, com, com, &on_eval_err);

eval (com +"->main ()");
