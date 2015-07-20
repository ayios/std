loadfrom ("api", "apiInit", 1, &on_eval_err);

APP = api->init (__FILE__;
  stderr = 1,
  stdout = 1,
  stdouttype = "ashell",
  ved = 1,
  scratch = 1,
  shell = 1,
  os = 1,
  );

loadfrom ("api", "clientapi", NULL, &on_eval_err);

init_shell ();
