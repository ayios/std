static define getloginname ()
{
  variable name = rline->getline (;pchar = "login:");

  return strtrim_end (name);
}

static define login ()
{
  variable msg = "";

  USER = getloginname ();

  (UID, GID) = setpwuidgid (USER, &msg);

  if (NULL == UID || NULL == GID)
    on_eval_err (msg, 1);

  GROUP = setgrname (GID, &msg);

  if (NULL == GROUP)
    on_eval_err (msg, 1);

  variable passwd = getpasswd ();

  if (-1 == authenticate (USER, passwd))
    on_eval_err ("authentication error", 1);

  variable home = "/home/" + USER;

  ifnot (access (home, F_OK))
    if (_isdirectory (home))
      HOME = home;

  return encryptpasswd (passwd);
}
