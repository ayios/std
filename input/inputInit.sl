importfrom ("std", "getkey", "input", &on_eval_err);

loadfrom ("conf", "keysinit", "keys", &on_eval_err);
loadfrom ("input", "inputinit", 1, &on_eval_err);
