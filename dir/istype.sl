define istype (st, type)
{
  return NULL != st && stat_is (type, st.st_mode);
}

