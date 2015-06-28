define setgrname (gid, exit_on_err)
{
  variable gr = getgrgid (gid);
  if (NULL == gr)
    {
    if (errno)
      tostderr (errno_string (errno));
    else
      tostderr ("cannot find the GID " + string (gid) + " in /etc/group, who are you?");

    if (exit_on_err)
      exit (1);

    return NULL;
    }

  return gr.gr_name;
}

define setpwname (uid, exit_on_err)
{
  variable pw =getpwuid (uid);
  if (NULL == pw)
    {
    if (errno)
      tostderr (errno_string (errno));
    else
      tostderr ("cannot find the UID " + string (uid) + " in /etc/passwd, who are you?");

    if (exit_on_err)
      exit (1);

    return NULL;
    }

  return pw.pw_name;
}

define setpwuidgid (user, exit_on_err)
{
  variable pw = getpwnam (user);
  if (NULL == pw)
    {
    if (errno)
      tostderr (errno_string (errno));
    else
      tostderr ("cannot find the user " + user + " in /etc/passwd, who are you?");

    if (exit_on_err)
      exit (1);

    return NULL;
    }

  return pw.pw_uid, pw.pw_gid;
} 
