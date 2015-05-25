loadfrom ("proc", "procInit", NULL, &on_eval_err);
loadfrom ("dir", "istype", NULL, &on_eval_err);

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
    file,
    argv,
    index,
    retval,
    status,
    passwd,
    mountpoint = NULL,
    device = NULL,
    mount = which ("mount"),
    c = cmdopt_new (&_usage);

  if (NULL == mount)
    {
    tostderr ("mount couldn't be found in PATH");
    exit (1);
    }
 
  c.add ("mountpoint", &mountpoint;type = "string");
  c.add ("device", &device;type = "string");
  c.add ("v|verbose", &verbose);
  c.add ("help", &_usage);
  c.add ("info", &info);

  i = c.process (__argv, 1);
 
  if (mountpoint == NULL == device)
    {
    p = proc->init (0, 0, 0);
 
    status = p.execv ([mount], NULL);
 
    exit (status.exit_status);
    }

  if (NULL == mountpoint || NULL == device)
    {
    tostderr ("--mountpoint= && --device= args are required");
    exit (1);
    }

  if (-1 == access (mountpoint, F_OK))
    {
    tostderr (sprintf ("%s mountpoint doesn't exists", mountpoint));
    exit (1);
    }

  ifnot (istype (stat_file (device), "blk"))
    {
    tostderr (sprintf ("%s is not a block device", device));
    exit (1);
    }
 
  if (VERBOSE)
    argv = [mount, "-v", device, mountpoint];
  else
    argv = [mount, device, mountpoint];

  p = proc->init (0, 0, 0);

  status = p.execv (argv, NULL);
 
  exit (status.exit_status);
}
