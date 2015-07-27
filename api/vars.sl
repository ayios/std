public variable HASHEDDATA = NULL;
public variable RLINE = NULL;
public variable SCRATCH = TEMPDIR + "/" + string (PID) + "_" + APP.appname +  "_scratch.txt";
public variable SCRATCHFD =  initstream (SCRATCH);
public variable SCRATCH_VED;
public variable OSPPID = APP.os ? getppid () : NULL;

define toscratch ();

