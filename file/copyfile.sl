define copyfile (source, dest)
{
  variable
    buf,
    dest_fp,
    source_fp = fopen (source, "rb");

  if (NULL == source_fp)
    {
    tostderr (sprintf ("Unable to open: `%s': %s", source, errno_string (errno)));
    return -1;
    }

  dest_fp = fopen (dest, "wb");

  if (NULL == dest_fp)
    {
    tostderr (sprintf ("Unable to open: `%s': %s", dest, errno_string (errno)));
    return -1;
    }

  while (-1 != fread (&buf, String_Type, 1024, source_fp))
    if (-1 == fwrite (buf, dest_fp))
      {
      tostderr (errno_string (errno));
      return -1;
      }

  if (-1 == fclose (source_fp) || -1 == fclose (dest_fp))
      {
      tostderr (errno_string (errno));
      return -1;
      }

  return 0;
}
