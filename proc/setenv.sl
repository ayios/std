loadfrom ("getvar", "getterm", NULL, &on_eval_err);
loadfrom ("getvar", "getlang", NULL, &on_eval_err);
loadfrom ("getvar", "gethome", NULL, &on_eval_err);
loadfrom ("getvar", "getpath", NULL, &on_eval_err);
loadfrom ("getvar", "getos", NULL, &on_eval_err);
loadfrom ("getvar", "getX", NULL, &on_eval_err);
loadfrom ("getvar", "getxauth", NULL, &on_eval_err);
loadfrom ("getvar", "getscreensizefromenv", NULL, &on_eval_err);
loadfrom ("sys", "which", NULL, &on_eval_err);

public variable
  OS,
  MACHINE,
  TERM,
  PATH,
  LANG,
  HOME,
  LINES,
  COLUMNS,
  SLSH_LIB_DIR,
  SLANG_MODULE_PATH,
  DISPLAY,
  XAUTHORITY,
  SLSH_BIN,
  PWD,
  GROUP,
  UID,
  GID,
  PID,
  ISSUPROC,
  USER;

static define setdefenv ()
{
  (OS, MACHINE) = getos ();
  TERM = getterm ();
  PATH = getpath ();
  LANG = getlang ();
  HOME = gethome ();
  DISPLAY = getX ();
  XAUTHORITY = getxauth ();
  PID = getpid ();
  UID = getuid ();
  GID = getgid ();
  ISSUPROC = UID;
  SLANG_MODULE_PATH = get_import_module_path ();
  SLSH_LIB_DIR = get_slang_load_path ();
  SLSH_BIN = which ("slsh");
  PWD = getcwd ();
 
  variable getsceendim = qualifier ("dimfunc", &getscreensizefromenv);

  (LINES, COLUMNS) = (@getsceendim);;
}
