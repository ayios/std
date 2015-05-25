static define getdefenv ()
{
  return [
    "TERM=" + TERM,
    "PATH=" + PATH,
    "LANG=" + LANG,
    "HOME=" + HOME,
    "LINES=" + string (LINES),
    "COLUMNS=" + string (COLUMNS),
    "MACHINE=" + MACHINE,
    "OS=" + OS,
    "DISPLAY=" + DISPLAY,
    "XAUTHORITY=" + XAUTHORITY,
    "SLANG_MODULE_PATH=" + get_import_module_path (),
    "SLSH_LIB_DIR=" + get_slang_load_path (),
    ];
}
