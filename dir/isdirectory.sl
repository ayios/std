define isdirectory (file)
{
  variable st = qualifier ("st", stat_file (file));
  return NULL != st && stat_is ("dir", st.st_mode);
}
