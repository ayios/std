static define getloginname ()
{
  strtrim_end (rline->getline (;pchar = "login:"));
}

static define login ()
{
  variable msg, uid, gid, group, user;

  user = getloginname ();

  (uid, gid) = Sys.setpwuidgid (user, &msg);

  if (NULL == uid || NULL == gid)
    exit_me (1;msg = msg);

  group = Sys.setgrname (gid, &msg);

  if (NULL == group)
    exit_me (1;msg = msg);

  variable passwd = getpasswd ();

  if (-1 == authenticate (user, passwd))
    exit_me (1;msg = "authentication error");

  ifnot (access (Env->Vget ("HOME"), F_OK))
    {
    ifnot (_isdirectory (Env->Vget ("HOME")))
      exit_me (1;msg = Env->Vget ("HOME") + " is not a directory");
    }
  else
    exit_me (1;msg = Env->Vget ("HOME") + " is not a directory");

  Env->Var ("user", user);
  Env->Var ("uid", uid);
  Env->Var ("gid", gid);
  Env->Var ("group", group);

  encryptpasswd (passwd);
}
