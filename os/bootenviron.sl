if (NULL == TERM)
  {
  tostderr ("TERM environment variable isn't set");
  exit (1);
  }

if (NULL == LANG)
  {
  tostderr ("LANG environment variable isn't set");
  exit (1);
  }

if (5 > strlen (LANG) || "UTF-8" != substr (LANG, strlen (LANG) - 4, -1))
  {
  tostderr ("locale: " + LANG + " isn't UTF-8 (Unicode), or misconfigured");
  exit (1);
  }

if (NULL == HOME)
  {
  tostderr ("HOME environment variable isn't set");
  exit (1);
  }

if (NULL == PATH)
  {
  tostderr ("PATH environment variable isn't set");
  exit (1);
  }

SLSH_BIN = which ("slsh");
SUDO_BIN = which ("sudo");

USER = setpwname (UID, &$1);
if (NULL == USER)
  {
  tostderr (__tmp ($1));
  exit (1);
  }

GROUP = setgrname (GID, &$1);
if (NULL == GROUP)
  {
  tostderr (__tmp ($1));
  exit (1);
  }

__uninitialize (&$1);
