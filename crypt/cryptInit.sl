load.module ("std", "crypto", "crypt";err_handler = &__err_handler__);

load.from ("rand", "randInit", "rand";err_handler = &__err_handler__);
load.from ("crypt", "cryptinit", 1;err_handler = &__err_handler__);
