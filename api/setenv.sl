$1 = getpwuid (getuid ());

if (NULL == $1)
  exit (1);

__.vput ("Env", "uid", $1.pw_uid);
__.vput ("Env", "gid", $1.pw_gid);
__.vput ("Env", "user", $1.pw_name);
__.vput ("Env", "group", setgrname (Env.vget ("gid"), &$1));

if (NULL == Env.vget ("group"))
  {
  IO.tostderr (__tmp ($1));
  exit (1);
  }

__uninitialize (&$1);

putenv ("USER=" + Env.vget ("user"));
putenv ("LOGNAME=" + Env.vget ("user"));
putenv ("USERNAME=" +  Env.vget ("user"));
putenv ("HOME=/home/" + Env.vget ("user"));
putenv ("GROUP=" + Env.vget ("group"));
