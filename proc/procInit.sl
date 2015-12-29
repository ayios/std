load.module ("std", "fork", NULL;err_handler = &__err_handler__);
load.module ("std", "socket", NULL;err_handler = &__err_handler__);

load.from ("parse", "is_arg", NULL;err_handler = &__err_handler__);
load.from ("proc", "procinit", 1;err_handler = &__err_handler__);
