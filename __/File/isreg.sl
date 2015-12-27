private define isreg (file)
{
  variable st = qualifier ("st", lstat_file (file));
  return NULL != st && stat_is ("reg", st.st_mode);
}
