private define _get_rootdir_ ()
{
  variable rootdir = path_concat (getcwd (), path_dirname (__FILE__));
  
  if (rootdir[[-2:]] == "/.")
    rootdir = substr (rootdir, 1, strlen (rootdir) - 2);
  
  return rootdir + "/..";
}

private define _get_term_ ()
{
  variable term = getenv ("TERM");  

  if (NULL == term)
    on_eval_err ("TERM environment variable isn't set", 1);

  return term;
}

private define _get_lang_ ()
{
  variable lang = getenv ("LANG");

  if (NULL == lang)
    on_eval_err ("LANG environment variable isn't set", 1);

  ifnot ("UTF-8" == substr (lang, strlen (lang) - 4, -1))
    on_eval_err ("locale: " + lang + " isn't UTF-8 (Unicode), or misconfigured", 1);
  
  return lang;
}

define setenviron ()
{
  ENV["TERM"] = _get_term_ ();
  
  ENV["HOST_LANG"] = _get_lang_ ();
  ENV["HOST_HOME"] = getenv ("HOME");

  ENV["R_PID"] = getpid ();
  
  ENV["U_UID"] = getuid ();
  
  ENV["AREYOUSU"] = ENV["U_UID"] ? 1 : 0;

  ENV["R_DIR"] = _get_rootdir_ ();

  ENV["R_DIR_BIN"] = ENV["R_DIR"] + "/bin";
  ENV["R_BIN"]     = ENV["R_DIR_BIN"] + "/" + __argv[0];

  ENV["R_DIR_DIST"] = ENV["R_DIR"] + "/ayios";
  ENV["R_DIR_ROOT"] = ENV["R_DIR"] + "/root";
  
  ENV["R_DIR_PROC"] = ENV["R_DIR_ROOT"] + "/proc";
  ENV["R_DIR_TEMP"] = ENV["R_DIR_ROOT"] + "/tmp";
  ENV["R_DIR_USER"] = ENV["R_DIR_ROOT"] + "/usr";
  ENV["R_DIR_SLIB"] = ENV["R_DIR_ROOT"] + "/lib";
  ENV["R_DIR_CONF"] = ENV["R_DIR_ROOT"] + "/etc";
  ENV["R_DIR_HOME"] = ENV["R_DIR_ROOT"] + "/root";
  ENV["R_USERS_DB"] = ENV["R_DIR_CONF"] + "/users";

  ENV["U_DIR_HOME"] = ENV["R_DIR_ROOT"] + "/home";
  ENV["U_DIR_CLIB"] = ENV["R_DIR_USER"] + "/lib";
  ENV["U_DIR_SLIB"] = ENV["R_DIR_USER"] + "/lib/slsh";
  ENV["U_DIR_CONF"] = ENV["R_DIR_USER"] + "/etc";

  PERM["PRIVATE"]  = S_IRWXU;
  PERM["_PRIVATE"] = S_IRUSR|S_IWUSR;

  PERM["STATIC"]   = PERM["PRIVATE"]|S_IRWXG;
  PERM["_STATIC"]  = PERM["PRIVATE"]|S_IRGRP|S_IXGRP;
  PERM["__STATIC"] = PERM["PRIVATE"]|S_IRGRP;

  PERM["PUBLIC"]  = PERM["_STATIC"]|S_IROTH|S_IXOTH;
}
