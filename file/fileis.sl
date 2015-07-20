define iself (file)
{
  variable fd = open (file, O_RDONLY);
  if (NULL == fd)
    return -1;

  variable b;
  variable bts = read (fd, &b, 4);
  if (bts < 4)
    return 0;

  if ("ELF" == b[[1:]])
    return 1;

  return 0;
}

define isreg (file)
{
  variable st = qualifier ("st", lstat_file (file));
  return NULL != st && stat_is ("reg", st.st_mode);
}

define isblock (file)
{
  variable st = qualifier ("st", stat_file (file));
  return NULL != st && stat_is ("blk", st.st_mode);
}

define isfifo (file)
{
  variable st = qualifier ("st", stat_file (file));
  return NULL != st && stat_is ("fifo", st.st_mode);
}

define issock (file)
{
  variable st = qualifier ("st", stat_file (file));
  return NULL != st && stat_is ("sock", st.st_mode);
}

define islnk (file)
{
  variable st = qualifier ("st", lstat_file (file));
  return NULL != st && stat_is ("lnk", st.st_mode);
}

define ischr (file)
{
  variable st = qualifier ("st", stat_file (file));
  return NULL != st && stat_is ("chr", st.st_mode);
}
