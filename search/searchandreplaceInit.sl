load.module ("std", "pcre", NULL;err_handler = &__err_handler__);

typedef struct
  {
  global,
  fname,
  ar,
  pat,
  patstr,
  substlist,
  numchanges,
  newlines,
  askwhensubst,
  ask,
  lnronfile,
  } Search_Type;

load.from ("search", "searchandreplace", "search";err_handler = &__err_handler__);
