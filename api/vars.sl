public variable HASHEDDATA = NULL;
public variable RLINE = NULL;
public variable SCRATCH = Dir->Vget ("TEMPDIR") + "/" + string (Env->Vget ("PID")) + "_" + APP.appname +  "_scratch.txt";
public variable SCRATCHFD =  initstream (SCRATCH);
public variable SCRATCH_VED;
public variable OSPPID = APP.os ? getppid () : NULL;
public variable SOCKET;
public variable SOCKADDR   = getenv ("SOCKADDR");
public variable GO_ATEXIT  = 0x0C8;
public variable GO_IDLED   = 0x012c;
public variable APP_CON_NEW = 0x1f4;
public variable APP_RECON_OTH = 0x258;
public variable RECONNECT  = 0x0190;
public variable APP_GET_ALL = 0x2bc;
public variable APP_GET_CONNECTED = 0x320;

define toscratch ();

