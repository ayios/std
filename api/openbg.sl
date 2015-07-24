variable STDOUTBG   = TEMPDIR + "/" + string (PID) + "_stdoutbg.ashell";
variable BGDIR      = TEMPDIR + "/" + string (PID) + "_procs";
variable BGPIDS     = Assoc_Type[Struct_Type];
variable STDOUTFDBG = initstream (STDOUTBG);
variable OUTBG;

ifnot (access (BGDIR, F_OK))
  {
  ifnot (_isdirectory (BGDIR))
    on_eval_err (BGDIR + ": is not a directory", 1);
  }
else
  if (-1 == mkdir (BGDIR, PERM["PRIVATE"]))
    on_eval_err (BGDIR + ": " + errno_string (errno), 1);

OUTBG = init_ftype ("ashell");
ashell_settype (OUTBG, STDOUTBG, VED_ROWS, NULL);
OUTBG._fd = STDOUTFDBG;
