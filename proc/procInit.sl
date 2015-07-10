importfrom ("std", "fork", NULL, &on_eval_err);
importfrom ("std", "socket", NULL, &on_eval_err);

loadfrom ("posix", "read_fd", NULL, &on_eval_err);
loadfrom ("parse", "is_arg", NULL, &on_eval_err);
loadfrom ("proc", "procinit", 1, &on_eval_err);
