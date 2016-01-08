private define setpwname (uid, msg)
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
