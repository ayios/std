load.from ("api", "apiInit", 1;err_handler = &__err_handler__);

APP = api->init (__FILE__;os = 0, excom = 1, realshell = 1);

load.from ("api", "clientapi", NULL;err_handler = &__err_handler__);

init_shell ();
