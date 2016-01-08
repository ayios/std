define initstream (fname)
{
  variable fd;
  variable err_func = qualifier ("err_func", &__err_handler__);

  if (-1 == access (fname, F_OK))
    fd = open (fname, File->Vget ("FLAGS")["<>"], File->Vget ("PERM")["_PRIVATE"]);
  else
    fd = open (fname, File->Vget ("FLAGS")["<>|"], File->Vget ("PERM")["_PRIVATE"]);

  if (NULL == fd)
    (@err_func) (1;msg = "Can't open file " + fname + " " + errno_string (errno));

  variable st = fstat (fd);
  if (-1 == checkperm (st.st_mode, File->Vget ("PERM")["_PRIVATE"]))
    if (-1 == setperm (fname, File->Vget ("PERM")["_PRIVATE"]))
      (@err_func) (1;msg = "wrong permissions for " + fname);

  return fd;
}
