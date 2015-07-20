loadfrom ("os", "AppInit", NULL, &on_eval_err);

public variable RLINE;

loadfrom ("wind", "ostopline", NULL, &on_eval_err);
loadfrom ("stdio", "appendstr", NULL, &on_eval_err);
loadfrom ("stdio", "readfile", NULL, &on_eval_err);
loadfrom ("os", "initved", NULL, &on_eval_err);

loadfrom ("os", "runapp", 1, &on_eval_err);
loadfrom ("shell", "eval", NULL, &on_eval_err);
loadfrom ("os", "initrline", NULL, &on_eval_err);
loadfrom ("os", "osloop", NULL, &on_eval_err);

os->apptable ();

_APPS_ = assoc_get_keys (APPS);
RLINE = initrline ();

