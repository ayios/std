define appendstr (file, str)
{
  if (-1 == access (file, F_OK|W_OK))
    {
    tostderr (file + ": " + errno_string (errno));
    return -1;
    }

  variable fd = open (file, O_WRONLY|O_APPEND);
 
  if (NULL == fd)
    {
    tostderr (file + ": " + errno_string (errno));
    return -1;
    }
 
  if (-1 == lseek (fd, 0, SEEK_END))
    {
    tostderr (file + ": " + errno_string (errno));
    return -1;
    }

  if (-1 == write (fd, str))
    {
    tostderr (file + ": " + errno_string (errno));
    return -1;
    }

  if (-1 == close (fd))
    {
    tostderr (file + ": " + errno_string (errno));
    return -1;
    }

  return 0;
}

define writestring (file, str)
{
  variable fd = open (file, O_WRONLY|O_CREAT|O_TRUNC, qualifier ("flags", PERM["__PUBLIC"]));
 
  if (NULL == fd)
    {
    tostderr (file + ": " + errno_string (errno));
    return -1;
    }
 
  if (-1 == write (fd, str))
    {
    tostderr (file + ": " + errno_string (errno));
    return -1;
    }

  if (-1 == close (fd))
    {
    tostderr (file + ": " + errno_string (errno));
    return -1;
    }

  return 0;
}
