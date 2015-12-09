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

if (NULL == Env.vget ("HOME"))
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

__.vput ("Env", "USER", setpwname (Env.vget ("UID"), &$1));

if (NULL == Env.vget ("USER"))
  {
  IO.tostderr (__tmp ($1));
  exit (1);
  }

__.vput ("Env", "GROUP", setgrname (Env.vget ("GID"), &$1));

if (NULL == Env.vget ("GROUP"))
  {
  IO.tostderr (__tmp ($1));
  exit (1);
  }
