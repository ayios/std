static define getdefenv ()
{
  TERM = getenv ("TERM");
  PATH = getenv ("PATH");
  LANG = getenv ("LANG");
  HOME = getenv ("HOME");
  LINES = atoi (getenv ("LINES"));
  COLUMNS = atoi (getenv ("COLUMNS"));
  SLANG_MODULE_PATH = getenv ("SLANG_MODULE_PATH");
  SLSH_LIB_DIR = getenv ("SLSH_LIB_DIR");
  DISPLAY = getenv ("DISPLAY");
  XAUTHORITY = getenv ("XAUTHORITY");
  SLSH_BIN = which ("slsh");
  SUDO_BIN = which ("sudo");
}
