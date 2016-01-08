static define defenv ()
{
  variable lenv = [
    "TERM=" + Env->Vget ("TERM"),
    "PATH=" + Env->Vget ("PATH"),
    "LANG=" + Env->Vget ("LANG"),
    "HOME=" + Env->Vget ("HOME"),
    "SLANG_MODULE_PATH=" + Env->Vget ("SLANG_MODULE_PATH"),
    "SLSH_LIB_DIR=" + Env->Vget ("SLSH_LIB_DIR"),
    "COLUMNS=" + string (COLUMNS),
    "LINES=" + string (LINES),
    ];

  ifnot (NULL == Env->Vget ("display"))
    lenv = [lenv, "DISPLAY=" + Env->Vget ("display")];

  ifnot (NULL == Env->Vget ("xauthority"))
    lenv = [lenv, "XAUTHORITY=" + Env->Vget ("xauthority")];

  lenv;
}
