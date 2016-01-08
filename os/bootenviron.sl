if (NULL == Env->Vget ("TERM"))
  {
  IO.tostderr ("TERM environment variable isn't set");
  exit (1);
  }

if (NULL == Env->Vget ("LANG"))
  {
  IO.tostderr ("LANG environment variable isn't set");
  exit (1);
  }

if (5 > strlen (Env->Vget ("LANG")) || "UTF-8" != substr (Env->Vget ("LANG"),
  strlen (Env->Vget ("LANG")) - 4, -1))
  {
  IO.tostderr ("locale: " + Env->Vget ("LANG") + " isn't UTF-8 (Unicode), or misconfigured");
  exit (1);
  }

if (NULL == getenv ("HOME"))
  {
  IO.tostderr ("HOME environment variable isn't set");
  exit (1);
  }

if (NULL == Env->Vget ("PATH"))
  {
  IO.tostderr ("PATH environment variable isn't set");
  exit (1);
  }

SLSH_BIN = Sys.which ("slsh");
SUDO_BIN = Sys.which ("sudo");

Env->Var ("user", setpwname (Env->Vget ("uid"), &$1));

if (NULL == Env->Vget ("user"))
  {
  IO.tostderr (__tmp ($1));
  exit (1);
  }

Env->Var ("group", setgrname (Env->Vget ("gid"), &$1));

if (NULL == Env->Vget ("group"))
  {
  IO.tostderr (__tmp ($1));
  exit (1);
  }
