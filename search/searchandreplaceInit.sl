importfrom ("std", "pcre", NULL, &on_eval_err);

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

loadfrom ("search", "searchandreplace", "search", &on_eval_err);
