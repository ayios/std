sigprocmask (SIG_BLOCK, [SIGINT]);

set_slang_load_path (APP.loaddir + char (path_get_delimiter) +
  get_slang_load_path ());

importfrom ("std", "socket",  NULL, &on_eval_err);

loadfrom ("api", "atexit", NULL, &on_eval_err);
loadfrom ("api", "evalerr", NULL, &on_eval_err);
loadfrom ("sys", "getpw", NULL, &on_eval_err);
loadfrom ("sys", "checkpermissions", NULL, &on_eval_err);
loadfrom ("sys", "setpermissions", NULL, &on_eval_err);
loadfrom ("api", "initstream", NULL, &on_eval_err);
loadfrom ("api", "vars", NULL, &on_eval_err);
loadfrom ("input", "inputInit", NULL, &on_eval_err);
loadfrom ("keys", "keysInit", 1, &on_eval_err);
loadfrom ("smg", "smgInit", NULL, &on_eval_err);
loadfrom ("os", "passwd", 1, &on_eval_err);
loadfrom ("parse", "is_arg", NULL, &on_eval_err);
loadfrom ("rline", "rlineInit", NULL, &on_eval_err);
loadfrom ("proc", "procInit", NULL, &on_eval_err);
loadfrom ("smg", "smgInit", NULL, &on_eval_err);
loadfrom ("smg", "widg", "widg", &on_eval_err);
loadfrom ("sock", "sockInit", 1, &on_eval_err);
loadfrom ("api", "vedlib", NULL, &on_eval_err);
loadfrom ("wind", APP.appname + "topline", NULL, &on_eval_err);

if (APP.vedlib || NULL != APP.excom)
  loadfrom ("api", "clientfuncs", NULL, &on_eval_err);

if (APP.vedrline)
  loadfrom ("api", "vedreal", NULL, &on_eval_err);
else
  {
  VED_RLINE = 0;
  VED_ISONLYPAGER = 1;
  }

if (APP.os)
  {
  loadfrom ("proc", "getdefenv", 1, &on_eval_err);
  loadfrom ("api", "setenv", NULL, &on_eval_err);
  loadfrom ("api", "connect", NULL, &on_eval_err);
  loadfrom ("api", "osstdfuncs", NULL, &on_eval_err);
  loadfrom ("api", "osapprl", NULL, &on_eval_err);
  }
else
  loadfrom ("api", "stdfuncs", NULL, &on_eval_err);

loadfrom ("api", "openstderr", NULL, &on_eval_err);
loadfrom ("api", "openscratch", NULL, &on_eval_err);

if (APP.stdout)
  loadfrom ("api", "openstdout", NULL, &on_eval_err);

loadfrom ("api", "idle", NULL, &on_eval_err);

ifnot (NULL == APP.excom)
  {
  loadfrom ("file", "fileis",  NULL, &on_eval_err);
  loadfrom ("proc", "envs", 1, &on_eval_err);
  loadfrom ("stdio", "appendstr", NULL, &on_eval_err);
  loadfrom ("api", "openbg", NULL, &on_eval_err);
  loadfrom ("api", "cominit", NULL, &on_eval_err);
  loadfrom ("api", "filterexcom", NULL, &on_eval_err);
  }

ifnot (APP.vedrline)
  loadfrom ("api", "framefuncs", NULL, &on_eval_err);

loadfile ("Init", NULL, &on_eval_err);

ifnot (NULL == APP.excom)
  RLINE = rlineinit (;
    osappnew = __get_reference ("_osappnew_"),
    osapprec = __get_reference ("_osapprec_"),
    filterargs = __get_reference ("filterexargs"),
    filtercommands = __get_reference ("filterexcom"));
else
  RLINE = rlineinit (;
    oscompl = __get_reference ("_osappnew_"),
    osapprec = __get_reference ("_osapprec_"),
    );
 
