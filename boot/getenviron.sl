loadfrom ("getvar", "getterm", NULL, &on_eval_err);
loadfrom ("getvar", "getlang", NULL, &on_eval_err);
loadfrom ("getvar", "isutf8", NULL, &on_eval_err);
loadfrom ("getvar", "gethome", NULL, &on_eval_err);
loadfrom ("getvar", "getpath", NULL, &on_eval_err);
loadfrom ("getvar", "getos", NULL, &on_eval_err);
loadfrom ("getvar", "getX", NULL, &on_eval_err);
loadfrom ("getvar", "getxauth", NULL, &on_eval_err);
loadfrom ("getvar", "getscreensizefromenv", NULL, &on_eval_err);

static define getenviron ()
{
  TERM = v_getterm ();
  if (NULL == TERM)
    exit (1);
 
  LANG = v_getlang ();
  if (NULL == LANG)
    exit (1);

  ifnot (v_islangutf8 (LANG))
    exit (1);

  HOME = v_gethome ("HOME");
  if (NULL == HOME)
    exit (1);
 
  PATH = v_getpath ();
  if (NULL == PATH)
    exit (1);

  DISPLAY = getenv ("DISPLAY");
  XAUTHORITY = getenv ("XAUTHORITY");
  PID = getpid ();
  UID = getuid ();
  GID = getgid ();
  PWD = getcwd ();
  (OS, MACHINE) = getos ();
  ISSUPROC = UID ? 0 : 1;
  SLSH_BIN = which ("slsh");
}
