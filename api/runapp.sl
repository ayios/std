define runapp (argv, env)
{
  smg->suspend ();
 
  argv[0] = Dir.vget ("ROOTDIR") + "/bin/" + argv[0];

  variable issudo = qualifier ("issudo");
 
  variable p = proc->init (issudo, 0, 0);
  if (issudo)
    {
    p.stdin.in = qualifier ("passwd");
    argv = [SUDO_BIN, "-S", "-E", "-p", "", argv];
    }
 
  variable status;
 
  ifnot (NULL == env)
    status = p.execve (argv, env, NULL);
  else
    status = p.execv (argv, NULL);

  smg->resume ();
}

