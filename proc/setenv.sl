loadfrom ("getvar", "defvars", NULL, &on_eval_err);
loadfrom ("getvar", "getterm", NULL, &on_eval_err);
loadfrom ("getvar", "getlang", NULL, &on_eval_err);
loadfrom ("getvar", "gethome", NULL, &on_eval_err);
loadfrom ("getvar", "getpath", NULL, &on_eval_err);
loadfrom ("getvar", "getos", NULL, &on_eval_err);
loadfrom ("getvar", "getX", NULL, &on_eval_err);
loadfrom ("getvar", "getxauth", NULL, &on_eval_err);
loadfrom ("getvar", "getscreensizefromenv", NULL, &on_eval_err);
loadfrom ("sys", "which", NULL, &on_eval_err);
loadfrom ("sys", "getpw", NULL, &on_eval_err);

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
  SUDO_BIN = which ("sudo");
  PWD = getcwd ();
  USER = getpwname (UID, 0);
  GROUP = getgrname (GID, 0);
 
  variable getscreendim = qualifier ("dimfunc", &getscreensizefromenv);

  (LINES, COLUMNS) = (@getscreendim);;
}
