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
  } Rline_Type;

typedef struct
  {
  args,
  func,
  dir,
  type,
  } Argvlist_Type;

importfrom ("std", "pcre", NULL, &on_eval_err);

loadfrom ("dir", "evaldir", NULL, &on_eval_err);
loadfrom ("dir", "isdirectory", NULL, &on_eval_err);
loadfrom ("stdio", "readfile", NULL, &on_eval_err);
loadfrom ("keys", "keysInit", 1, &on_eval_err);
loadfrom ("input", "inputInit", 1, &on_eval_err);
loadfrom ("smg", "widg", "widg", &on_eval_err);
loadfrom ("rline", "exec", "exec", &on_eval_err);
loadfrom ("rline", "rlineinit", 1, &on_eval_err);
