if (NULL == Env.vget ("TERM"))
  {
  IO.tostderr ("TERM environment variable isn't set");
  exit (1);
  }

if (NULL == Env.vget ("LANG"))
  {
  IO.tostderr ("LANG environment variable isn't set");
  exit (1);
  }

if (5 > strlen (Env.vget ("LANG")) || "UTF-8" != substr (Env.vget ("LANG"),
  strlen (Env.vget ("LANG")) - 4, -1))
  {
  IO.tostderr ("locale: " + Env.vget ("LANG") + " isn't UTF-8 (Unicode), or misconfigured");
  exit (1);
  }

if (NULL == Env.vget ("home"))
  {
  IO.tostderr ("HOME environment variable isn't set");
  exit (1);
  }

if (NULL == Env.vget ("PATH"))
  {
  IO.tostderr ("PATH environment variable isn't set");
  exit (1);
  }

SLSH_BIN = Sys.which ("slsh");
SUDO_BIN = Sys.which ("sudo");

__.vput ("Env", "user", setpwname (Env.vget ("uid"), &$1));

if (NULL == Env.vget ("user"))
  {
  IO.tostderr (__tmp ($1));
  exit (1);
  }

__.vput ("Env", "group", setgrname (Env.vget ("gid"), &$1));

if (NULL == Env.vget ("group"))
  {
  IO.tostderr (__tmp ($1));
  exit (1);
  }
