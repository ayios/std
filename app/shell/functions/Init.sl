variable SHELLLASTEXITSTATUS = 0;
variable iarg;
variable MSG;
variable SCRATCH;
variable MYPID = getpid ();
variable SCRATCHFILE = TEMPDIR + "/" + string (MYPID) + "scratch.ashell";
variable GREPILE =     TEMPDIR + "/" + string (MYPID) + "grep.list";
variable STDOUT =      TEMPDIR + "/" + string (MYPID) + "stdout.ashell";
variable STDERR =      TEMPDIR + "/" + string (MYPID) + "stderr.ashell";
variable RDFIFO =      TEMPDIR + "/" + string (MYPID) + "SRV_FIFO.fifo";
variable WRFIFO =      TEMPDIR + "/" + string (MYPID) + "CLNT_FIFO.fifo";
variable ERRFD;
variable OUTFD;
variable RDFD;
variable WRFD;

loadfrom ("sys", "checkpermissions", NULL, &on_eval_err);
loadfrom ("sys", "setpermissions", NULL, &on_eval_err);
loadfrom ("proc", "envs", 1, &on_eval_err);
loadfrom ("smg", "widg", "widg", &on_eval_err);

loadfrom ("app/ved/functions", "vedlib", NULL, &on_eval_err);

loadfrom ("parse", "is_arg", NULL, &on_eval_err);
loadfrom ("dir", "are_same_files", NULL, &on_eval_err);
loadfile ("funcs", NULL, &on_eval_err);
loadfile ("initrline", NULL, &on_eval_err);

VED_INFOCLRFG = 4;
VED_INFOCLRBG = 5;
VED_PROMPTCLR = 3;

private define init_stream (fname)
{
  variable fd;

  if (-1 == access (fname, F_OK))
    fd = open (fname, FILE_FLAGS["<>"], PERM["_PRIVATE"]);
  else
    fd = open (fname, FILE_FLAGS["<>|"], PERM["_PRIVATE"]);

  if (NULL == fd)
    {
    tostderr ("Can't open file " + fname + " " + errno_string (errno));
    exit_me ();
    }
 
  variable st = stat_file (fname);
  if (-1 == checkperm (st.st_mode, PERM["_PRIVATE"]))
    if (-1 == setperm (fname, PERM["_PRIVATE"]))
      exit_me ();

  return fd;
}

define shell ();

define init_shell ()
{
  MSG = init_ftype ("ashell");

  SCRATCH = init_ftype ("ashell");

  variable vd = init_ftype ("ashell");

  variable rl = rlineinit ();

  OUTFD = init_stream (STDOUT);
  ERRFD = init_stream (STDERR);
 
  ifnot (access (RDFIFO, F_OK))
    () = remove (RDFIFO);

  ifnot (access (WRFIFO, F_OK))
    () = remove (WRFIFO);

  () = mkfifo (RDFIFO, 0644);
  () = mkfifo (WRFIFO, 0644);

  SHELLPROC._inited = 1;

  loadfile (path_dirname (__FILE__) + "/shell", NULL, &on_eval_err);

  shell (vd, rl);
}
