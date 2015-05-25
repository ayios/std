loadfrom ("getvar", "getterm", NULL, &on_eval_err);
loadfrom ("getvar", "getlang", NULL, &on_eval_err);
loadfrom ("getvar", "isutf8", NULL, &on_eval_err);
loadfrom ("getvar", "gethome", NULL, &on_eval_err);

private define _get_rootdir_ ()
{
  variable rootdir = path_concat (getcwd (), path_dirname (__FILE__));
 
  if (rootdir[[-2:]] == "/.")
    rootdir = substr (rootdir, 1, strlen (rootdir) - 2);
 
  return rootdir + "/..";
}

static define setenviron (session, os)
{
  os["R_DIR"] = _get_rootdir_ ();

  os["R_DIR_BIN"] = os["R_DIR"] + "/bin";
  os["R_BIN"]     = os["R_DIR_BIN"] + "/" + __argv[0];

  os["R_DIR_DIST"] = os["R_DIR"] + "/ayios";
  os["R_DIR_ROOT"] = os["R_DIR"] + "/root";
 
  os["R_DIR_PROC"] = os["R_DIR_ROOT"] + "/proc";
  os["R_DIR_TEMP"] = os["R_DIR_ROOT"] + "/tmp";
  os["R_DIR_USER"] = os["R_DIR_ROOT"] + "/usr";
  os["R_DIR_SLIB"] = os["R_DIR_ROOT"] + "/lib";
  os["R_DIR_CONF"] = os["R_DIR_ROOT"] + "/etc";
  os["R_DIR_HOME"] = os["R_DIR_ROOT"] + "/root";
  os["R_USERS_DB"] = os["R_DIR_CONF"] + "/users";

  os["U_DIR_HOME"] = os["R_DIR_ROOT"] + "/home";
  os["U_DIR_CLIB"] = os["R_DIR_USER"] + "/lib";
  os["U_DIR_SLIB"] = os["R_DIR_USER"] + "/lib/slsh";
  os["U_DIR_CONF"] = os["R_DIR_USER"] + "/etc";
 
  os["SLSH_BIN"] = which ("slsh");
}
