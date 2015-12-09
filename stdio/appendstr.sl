define appendstr (file, str)
{
  if (-1 == access (file, F_OK|W_OK))
    {
    IO.tostderr (file + ": " + errno_string (errno));
    return -1;
    }

  variable fd = open (file, O_WRONLY|O_APPEND);

  if (NULL == fd)
    {
    IO.tostderr (file + ": " + errno_string (errno));
    return -1;
    }

  if (-1 == lseek (fd, 0, SEEK_END))
    {
    IO.tostderr (file + ": " + errno_string (errno));
    return -1;
    }

  if (-1 == write (fd, str))
    {
    IO.tostderr (file + ": " + errno_string (errno));
    return -1;
    }

  if (-1 == close (fd))
    {
    IO.tostderr (file + ": " + errno_string (errno));
    return -1;
    }

  return 0;
}

define writestring (file, str)
{
  variable fd = open (file, O_WRONLY|O_CREAT|O_TRUNC, qualifier ("flags", File.vget ("PERM")["__PUBLIC"]));

  if (NULL == fd)
    {
    IO.tostderr (file + ": " + errno_string (errno));
    return -1;
    }

  if (-1 == write (fd, str))
    {
    IO.tostderr (file + ": " + errno_string (errno));
    return -1;
    }

  if (-1 == close (fd))
    {
    IO.tostderr (file + ": " + errno_string (errno));
    return -1;
    }

  return 0;
}
