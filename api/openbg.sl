variable STDOUTBG   = Dir.vget ("TEMPDIR") + "/" + string (Env.vget ("PID")) + "_stdoutbg.ashell";
variable BGDIR      = Dir.vget ("TEMPDIR") + "/" + string (Env.vget ("PID")) + "_procs";
variable BGPIDS     = Assoc_Type[Struct_Type];
variable STDOUTFDBG = initstream (STDOUTBG);
variable OUTBG;

ifnot (access (BGDIR, F_OK))
  {
  ifnot (_isdirectory (BGDIR))
    __err_handler__ (1;msg = BGDIR + ": is not a directory");
  }
else
  if (-1 == mkdir (BGDIR, File.vget ("PERM")["PRIVATE"]))
    __err_handler__ (1;msg = BGDIR + ": " + errno_string (errno));

OUTBG = init_ftype ("ashell");
ashell_settype (OUTBG, STDOUTBG, VED_ROWS, NULL);
OUTBG._fd = STDOUTFDBG;

SPECIAL = [SPECIAL, STDOUTBG];
