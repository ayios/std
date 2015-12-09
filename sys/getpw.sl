define setgrname (gid, msg)
{
  variable gr = getgrgid (gid);

  if (NULL == gr)
    {
    if (errno)
      @msg = errno_string (errno);
    else
      @msg = "cannot find the GID " + string (gid) + " in /etc/group, who are you?";

    return NULL;
    }

  gr.gr_name;
}

define setpwname (uid, msg)
{
  variable pw =getpwuid (uid);

  if (NULL == pw)
    {
    if (errno)
      @msg = errno_string (errno);
    else
      @msg = "cannot find the UID " + string (uid) + " in /etc/passwd, who are you?";

    return NULL;
    }

  pw.pw_name;
}

define setpwuidgid (user, msg)
{
  variable pw = getpwnam (user);
  if (NULL == pw)
    {
    if (errno)
      @msg = errno_string (errno);
    else
      @msg = "cannot find the user " + user + " in /etc/passwd, who are you?";

    return NULL, NULL;
    }

  return pw.pw_uid, pw.pw_gid;
}
