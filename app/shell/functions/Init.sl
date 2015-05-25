variable STDOUT = "/tmp/stdout.ashell";
variable STDERR = "/tmp/stderr.ashell";
variable ERRFD;
variable OUTFD;
variable SHELLLASTEXITSTATUS = 0;
variable iarg;

loadfrom ("sys", "checkpermissions", NULL, &on_eval_err);
loadfrom ("sys", "setpermissions", NULL, &on_eval_err);
loadfrom ("proc", "envs", 1, &on_eval_err);
loadfrom ("smg", "widg", "widg", &on_eval_err);

loadfrom ("app/ved/functions", "vedlib", NULL, &on_eval_err);

loadfile ("funcs", NULL, &on_eval_err);
loadfile ("builtin", NULL, &on_eval_err);

VED_INFOCLRFG = 4;
VED_INFOCLRBG = 5;
VED_PROMPTCLR = 3;

private define init_stream (fname)
{
  variable fd;

  if (-1 == access (fname, F_OK))
    fd = open (fname, FILE_FLAGS[">"], PERM["_PRIVATE"]);
  else
    fd = open (fname, FILE_FLAGS[">|"], PERM["_PRIVATE"]);

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
  variable v = init_ftype ("ashell");

  OUTFD = init_stream (STDOUT);
  ERRFD = init_stream (STDERR);
 
  SHELLPROC._inited = 1;

  loadfile (path_dirname (__FILE__) + "/shell", NULL, &on_eval_err);

  shell (v);
}
