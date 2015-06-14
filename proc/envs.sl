static define getdefenv ()
{
  variable env = [
    "TERM=" + TERM,
    "PATH=" + PATH,
    "LANG=" + LANG,
    "HOME=" + HOME,
    "LINES=" + string (LINES),
    "COLUMNS=" + string (COLUMNS),
    "MACHINE=" + MACHINE,
    "OS=" + OS,
    "SLANG_MODULE_PATH=" + get_import_module_path (),
    "SLSH_LIB_DIR=" + get_slang_load_path (),
    ];

  ifnot (NULL == DISPLAY)
    env = [env, "DISPLAY=" + DISPLAY];
  
  ifnot (NULL == XAUTHORITY)
    env = [env, "XAUTHORITY=" + XAUTHORITY];

  return env;
}
