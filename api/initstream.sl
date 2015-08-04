define initstream (fname)
{
  variable fd;
  variable err_func = qualifier ("err_func", &on_eval_err);

  if (-1 == access (fname, F_OK))
    fd = open (fname, FILE_FLAGS["<>"], PERM["_PRIVATE"]);
  else
    fd = open (fname, FILE_FLAGS["<>|"], PERM["_PRIVATE"]);

  if (NULL == fd)
    (@err_func) ("Can't open file " + fname + " " + errno_string (errno), 1);
 
  variable st = fstat (fd);
  if (-1 == checkperm (st.st_mode, PERM["_PRIVATE"]))
    if (-1 == setperm (fname, PERM["_PRIVATE"]))
      (@err_func) ("wrong permissions for " + fname, 1);

  return fd;
}
