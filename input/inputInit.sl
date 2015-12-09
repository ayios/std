load.module ("std", "getkey", "input";err_handler = &__err_handler__);
load.from ("conf", "keysinit", "keys";err_handler = &__err_handler__);
load.from ("input", "inputinit", 1;err_handler = &__err_handler__);
