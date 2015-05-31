define read_fd (fd)
{
  variable pos = qualifier ("pos", 0);
  
  () = lseek (fd, pos, SEEK_SET);

  variable
    buf,
    str = "";

  while (read (fd, &buf, 1024) > 0)
    str = sprintf ("%s%s", str, buf);

  return strlen (str) ? str : NULL;
}
