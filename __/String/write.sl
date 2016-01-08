private define write (file, str)
{
  variable fd = open (file, O_WRONLY|O_CREAT|O_TRUNC,
    qualifier ("flags", File->Vget ("PERM")["__PUBLIC"]));

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

  0;
}
