loadfrom ("proc", "procInit", 1, &on_eval_err);

variable name = __argv[1];
variable uid = atoi (__argv[2]);
variable gid = atoi (__argv[3]);

if (-1 == setgid (gid))
  {
  () = fprintf (stderr, "setgid error " + errno_string (errno));
  exit (1);
  }
 
if (-1 == setuid (uid))
  {
  () = fprintf (stderr, "setuid error " + errno_string (errno));
  exit (1);
  }

variable p = proc->init (0, 0, 0);
variable status = p.execv (["/bin/su", "-", name, "-c", "exit"], NULL);

exit (status.exit_status);
