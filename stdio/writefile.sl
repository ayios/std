define writefile (buf, fname)
{
  variable
    mode = qualifier ("mode", "w"),
    fmt = qualifier ("fmt", "%s\n"),
    fp = fopen (fname, mode);

  if (NULL == fp)
    throw OpenError, "Error while opening $fname"$;

  if (any (-1 == array_map (Integer_Type, &fprintf, fp, fmt, buf)))
    throw WriteError, "Error while writting $fname"$;

  if (-1 == fclose (fp))
    throw IOError, errno_string (errno);
}
