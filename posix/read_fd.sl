define read_fd (fd)
{
  variable
    buf,
    str = "";

  while (read (fd, &buf, 1024) > 0)
    str = sprintf ("%s%s", str, buf);

  return strlen (str) ? str : NULL;
}
