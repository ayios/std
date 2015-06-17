define appendstr (file, str, err)
{
  if (-1 == access (file, F_OK|W_OK))
    {
    @err = file + ": " + errno_string (errno);
    return;
    }

  variable fd = open (file, O_WRONLY|O_APPEND);
 
  if (NULL == fd)
    {
    @err = file + ": " + errno_string (errno);
    return;
    }
 
  if (-1 == lseek (fd, 0, SEEK_END))
    {
    @err = file + ": " + errno_string (errno);
    return;
    }

  if (-1 == write (fd, str))
    {
    @err = file + ": " + errno_string (errno);
    return;
    }

  if (-1 == close (fd))
    @err = file + ": " + errno_string (errno);
}

define writestring (file, str)
{
  variable fd = open (file, O_WRONLY|O_CREAT|O_TRUNC, qualifier ("flags", PERM["__PUBLIC"]));
 
  if (NULL == fd)
    {
    tostderr (file + ": " + errno_string (errno));
    return;
    }
 
  if (-1 == write (fd, str))
    {
    tostderr (file + ": " + errno_string (errno));
    return;
    }

  if (-1 == close (fd))
    tostderr (file + ": " + errno_string (errno));
}
