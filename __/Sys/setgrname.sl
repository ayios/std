private define setgrname (gid, msg)
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

