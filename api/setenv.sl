proc->getdefenv ();

private variable pw = getpwuid (getuid ());

if (NULL == pw)
  exit (1);

UID = pw.pw_uid;
GID = pw.pw_gid;
USER = pw.pw_name;

GROUP = setgrname (GID, &$1);

if (NULL == GROUP)
  {
  tostderr ($1);
  exit (1);
  }

putenv ("USER=" + USER);
putenv ("LOGNAME=" + USER);
putenv ("USERNAME=" + USER);
putenv ("HOME=/home/" + USER); 
putenv ("GROUP=" + GROUP);
