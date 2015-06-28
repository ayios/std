loadfrom ("sock", "sockInit", 1, &on_eval_err);
loadfrom ("proc", "envs", 1, &on_eval_err);
loadfrom ("app/ved", "vedinit", current_namespace (), &on_eval_err);
