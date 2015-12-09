static define defenv ()
{
  variable lenv = [
    "TERM=" + Env.vget ("TERM"),
    "PATH=" + Env.vget ("PATH"),
    "LANG=" + Env.vget ("LANG"),
    "HOME=" + Env.vget ("HOME"),
    "SLANG_MODULE_PATH=" + Env.vget ("SLANG_MODULE_PATH"),
    "SLSH_LIB_DIR=" + Env.vget ("SLSH_LIB_DIR"),
    "COLUMNS=" + string (COLUMNS),
    "LINES=" + string (LINES),
    ];

  ifnot (NULL == Env.vget ("DISPLAY"))
    lenv = [lenv, "DISPLAY=" + Env.vget ("DISPLAY")];

  ifnot (NULL == Env.vget ("XAUTHORITY"))
    lenv = [lenv, "XAUTHORITY=" + Env.vget ("XAUTHORITY")];

  lenv;
}
