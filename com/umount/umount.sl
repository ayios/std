loadfrom ("proc", "procInit", NULL, &on_eval_err);

variable VERBOSE = 0;

private define verbose ()
{
  VERBOSE = 1;
  verboseon ();
}

define main ()
{
  variable
    i,
    p,
    argv,
    status,
    mountpoint = NULL,
    umount = which ("umount"),
    c = cmdopt_new (&_usage);

  if (NULL == umount)
    {
    tostderr ("umount couldn't be found in path");
    exit (1);
    }
  
  c.add ("mountpoint", &mountpoint;type = "string");
  c.add ("v|verbose", &verbose);
  c.add ("help", &_usage);
  c.add ("info", &info);

  i = c.process (__argv, 1);
  
  if (mountpoint == NULL)
    {
    tostderr ("--mountpoint= arg is required");
    exit (1);
    }
    
  if (-1 == access (mountpoint, F_OK))
    {
    tostderr (sprintf ("%s mountpoint doesn't exists", mountpoint));
    exit (1);
    }

  if (VERBOSE)
    argv = [umount, "-v", mountpoint];
  else
    argv = [umount, mountpoint];

  p = proc->init (0, 0, 0);

  status = p.execv (argv, NULL);
  
  exit (status.exit_status);
}
