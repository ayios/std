define validate_user ()
{
  variable name = __argv[1];
  variable stdoutr, stdoutw, stderrw, stderrr;
  variable pid = proc->fork ();

  stdoutw = open ("/dev/null", O_WRONLY|O_NOCTTY|O_APPEND);
  stderrw = open ("/dev/null", O_WRONLY|O_NOCTTY|O_APPEND);

  () = dup2_fd (stdoutw, 1);
  () = dup2_fd (stderrw, 2);

  if (-1 == setgid (2011))
    {
    () = fprintf (stderr, "setgid error " + errno_string (errno));
    exit (1);
    }
 
  if (-1 == setuid (1967))
    {
    () = fprintf (stderr, "setuid error " + errno_string (errno));
    exit (1);
    }
 
  if ((0 == pid) && -1 == proc->execv ("/bin/su", ["/bin/su", "-", name, "-c", "ls"]))
    exit (1);

  variable status = proc->waitpid (pid, 0);

  exit (status.exit_status);
}

