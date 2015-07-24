loadfrom ("api", "apiInit", 1, &on_eval_err);

APP = api->init (__FILE__;os = 1, excom = 1, realshell = 1);

loadfrom ("api", "clientapi", NULL, &on_eval_err);

init_shell ();
