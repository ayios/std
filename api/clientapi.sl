sigprocmask (SIG_BLOCK, [SIGINT]);

set_slang_load_path (APP.loaddir + char (path_get_delimiter) +
  get_slang_load_path ());

loadfrom ("api", "atexit", NULL, &on_eval_err);
loadfrom ("api", "evalerr", NULL, &on_eval_err);
importfrom ("std", "socket",  NULL, &on_eval_err);
loadfrom ("sys", "getpw", NULL, &on_eval_err);
loadfrom ("api", "vars", NULL, &on_eval_err);
loadfrom ("sys", "checkpermissions", NULL, &on_eval_err);
loadfrom ("sys", "setpermissions", NULL, &on_eval_err);
loadfrom ("api", "initstream", NULL, &on_eval_err);
loadfrom ("input", "inputInit", NULL, &on_eval_err);
loadfrom ("keys", "keysInit", 1, &on_eval_err);
loadfrom ("smg", "smgInit", NULL, &on_eval_err);
loadfrom ("stdio", "readfile", NULL, &on_eval_err);
loadfrom ("os", "passwd", 1, &on_eval_err);
loadfrom ("parse", "is_arg", NULL, &on_eval_err);
loadfrom ("rline", "rlineInit", NULL, &on_eval_err);
loadfrom ("proc", "procInit", NULL, &on_eval_err);
loadfrom ("smg", "smgInit", NULL, &on_eval_err);
loadfrom ("string", "repeat", NULL, &on_eval_err);
loadfrom ("stdio", "getlines", NULL, &on_eval_err);
loadfrom ("smg", "widg", "widg", &on_eval_err);
loadfrom ("sock", "sockInit", 1, &on_eval_err);
loadfrom ("api", "sockfuncs", NULL, &on_eval_err);
loadfrom ("wind", APP.appname + "topline", NULL, &on_eval_err);

if (APP.os)
  {
  loadfrom ("proc", "getdefenv", 1, &on_eval_err);
  loadfrom ("api", "setenv", NULL, &on_eval_err);
  }

loadfrom ("ved", "vedtypes", NULL, &on_eval_err);
loadfrom ("ved", "vedvars", NULL, &on_eval_err);
loadfrom ("ved", "vedlib", NULL, &on_eval_err);

if (APP.ved)
  loadfrom ("api", "appclientfuncs", NULL, &on_eval_err);
else
  {
  variable clinef = Assoc_Type[Ref_Type];
  VED_RLINE = 1;
  VED_ISONLYPAGER = 0;
  VED_DRAWONLY = 0;
  }

if (APP.os)
  {
  loadfrom ("api", "connect", NULL, &on_eval_err);
  loadfrom ("api", "osstdfuncs", NULL, &on_eval_err);
  }
else
  loadfrom ("api", "stdfuncs", NULL, &on_eval_err);

if (APP.stderr)
  loadfrom ("api", "openstderr", NULL, &on_eval_err);

if (APP.stdout)
  loadfrom ("api", "openstdout", NULL, &on_eval_err);

if (APP.scratch || APP.shell)
  loadfrom ("api", "openscratch", NULL, &on_eval_err);

loadfile ("Init", NULL, &on_eval_err);

RLINE = rlineinit ();
