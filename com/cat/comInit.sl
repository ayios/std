COMDIR = path_dirname (__FILE__);

loadfrom ("com/" + com, com, com, &on_eval_err);

eval (com + "->main ()");
