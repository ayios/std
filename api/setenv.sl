$1 = getpwuid (getuid ());

if (NULL == $1)
  exit (1);

Env->Var ("uid", $1.pw_uid);
Env->Var ("gid", $1.pw_gid);
Env->Var ("user", $1.pw_name);
Env->Var ("group", setgrname (Env->Vget ("gid"), &$1));

if (NULL == Env->Vget ("group"))
  {
  IO.tostderr (__tmp ($1));
  exit (1);
  }

__uninitialize (&$1);

putenv ("USER=" + Env->Vget ("user"));
putenv ("LOGNAME=" + Env->Vget ("user"));
putenv ("USERNAME=" +  Env->Vget ("user"));
putenv ("HOME=/home/" + Env->Vget ("user"));
putenv ("GROUP=" + Env->Vget ("group"));
