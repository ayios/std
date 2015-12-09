typedef struct
  {
  _state,
  _prow,
  _pchar,
  _pclr,
  _row,
  _col,
  _chr,
  _lin,
  _ind,
  _lines,
  _columns,
  lcmp,
  history,
  histfile,
  historyaddforce,
  ptr,
  lnrs,
  argv,
  args,
  starthook,
  tabhook,
  filtercommands,
  filterargs,
  on_lang,
  on_lang_args,
  argvlist,
  totype,
  cmp_lnrs,
  execline,
  onnolength,
  onnolengthargs,
  osappnew,
  osapprec,
  wind_mang,
  } Rline_Type;

typedef struct
  {
  args,
  func,
  dir,
  type,
  } Argvlist_Type;

load.module ("std", "pcre", NULL;err_handler = &__err_handler__);

__.sadd ("Dir", "eval", "eval_", NULL;__DIRNS__ = Dir.vget ("STDDIR") + "/dir");

load.from ("input", "inputInit", 1;err_handler = &__err_handler__);
load.from ("smg", "widg", "widg";err_handler = &__err_handler__);
load.from ("rline", "exec", "exec";err_handler = &__err_handler__);
load.from ("rline", "rlineinit", 1;err_handler = &__err_handler__);
