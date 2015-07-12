variable iarg;
variable icom = 0;
variable SHELLLASTEXITSTATUS = 0;
variable SCRATCHFILE = TEMPDIR + "/" + string (PID) + "scratch.ashell";
variable GREPFILE    = TEMPDIR + "/" + string (PID) + "grep.list";
variable STDOUTBG    = TEMPDIR + "/" + string (PID) + "stdoutbg.ashell";
variable RDFIFO      = TEMPDIR + "/" + string (PID) + "SRV_FIFO.fifo";
variable WRFIFO      = TEMPDIR + "/" + string (PID) + "CLNT_FIFO.fifo";
variable BGDIR       = TEMPDIR + "/" + string (PID) + "procs";
variable BGPIDS      = Assoc_Type[Struct_Type];
variable SHELL_VED;
variable SCRATCH;
variable OUTBG;
variable STACK;
variable STACKFILE = HISTDIR + "/" + string (UID) + "stack";
variable OUTFDBG;

define runcom ();
