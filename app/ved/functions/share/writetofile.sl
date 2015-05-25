private define write_line (fp, line, indent)
{
  line = substr (line, indent + 1, -1);
  return fwrite (line, fp);
}

define writetofile (file, lines, indent)
{
  variable
    i,
    fp = fopen (file, "w");
 
  if (NULL == fp)
    return errno;

  _for i (0, length (lines) - 1)
    if (-1 == write_line (fp, lines[i] + "\n", indent))
      return errno;

  if (-1 == fclose (fp))
    return errno;
 
  return 0;
}
