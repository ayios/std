$1 = getpwuid (getuid ());

if (NULL == $1)
  exit (1);

__.vput ("Env", "UID", $1.pw_uid);
__.vput ("Env", "GID", $1.pw_gid);
__.vput ("Env", "USER", $1.pw_name);
__.vput ("Env", "GROUP", setgrname (Env.vget ("GID"), &$1));

if (NULL == Env.vget ("GROUP"))
  {
  IO.tostderr (__tmp ($1));
  exit (1);
  }

__uninitialize (&$1);

putenv ("USER=" + Env.vget ("USER"));
putenv ("LOGNAME=" + Env.vget ("USER"));
putenv ("USERNAME=" +  Env.vget ("USER"));
putenv ("HOME=/home/" + Env.vget ("USER"));
putenv ("GROUP=" + Env.vget ("GROUP"));
