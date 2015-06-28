variable iarg;
variable icom = 0;
variable MYPID = getpid ();
variable SHELLLASTEXITSTATUS = 0;
variable SCRATCHFILE = TEMPDIR + "/" + string (MYPID) + "scratch.ashell";
variable GREPILE     = TEMPDIR + "/" + string (MYPID) + "grep.list";
variable STDOUT      = TEMPDIR + "/" + string (MYPID) + "stdout.ashell";
variable STDOUTBG    = TEMPDIR + "/" + string (MYPID) + "stdoutbg.ashell";
variable STDERR      = TEMPDIR + "/" + string (MYPID) + "stderr.ashell";
variable RDFIFO      = TEMPDIR + "/" + string (MYPID) + "SRV_FIFO.fifo";
variable WRFIFO      = TEMPDIR + "/" + string (MYPID) + "CLNT_FIFO.fifo";
variable BGDIR       = TEMPDIR + "/" + string (MYPID) + "procs";
variable BGPIDS      = Assoc_Type[Struct_Type];
variable VED;
variable MSG;
variable SCRATCH;
variable OUTBG;
variable STACK;
variable STACKFILE = HISTDIR + "/" + string (getuid ()) + "stack";
variable OUTFD;
variable OUTFDBG;
variable ERRFD;
variable HASHEDDATA = NULL;

define runcom ();

