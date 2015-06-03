loadfrom ("sock", "sockInit", 1, &on_eval_err);
loadfrom ("proc", "envs", 1, &on_eval_err);
loadfrom ("app/shell", "shellinit", NULL, &on_eval_err);
