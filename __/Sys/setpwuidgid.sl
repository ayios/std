private define setpwuidgid (user, msg)
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

  pw.pw_uid, pw.pw_gid;
}
