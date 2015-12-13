static define defenv ()
{
  variable lenv = [
    "TERM=" + Env.vget ("TERM"),
    "PATH=" + Env.vget ("PATH"),
    "LANG=" + Env.vget ("LANG"),
    "HOME=" + Env.vget ("home"),
    "SLANG_MODULE_PATH=" + Env.vget ("SLANG_MODULE_PATH"),
    "SLSH_LIB_DIR=" + Env.vget ("SLSH_LIB_DIR"),
    "COLUMNS=" + string (COLUMNS),
    "LINES=" + string (LINES),
    ];

  ifnot (NULL == Env.vget ("display"))
    lenv = [lenv, "DISPLAY=" + Env.vget ("display")];

  ifnot (NULL == Env.vget ("xauthority"))
    lenv = [lenv, "XAUTHORITY=" + Env.vget ("xauthority")];

  lenv;
}
