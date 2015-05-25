loadfrom ("dir", "isdirectory", NULL, &on_eval_err);
loadfrom ("sys", "checkpermissions", NULL, &on_eval_err);
loadfrom ("sys", "setpermissions", NULL, &on_eval_err);

define makedir (dir, perm)
{
  variable
    st,
    retval = isdirectory (dir, &st);

  if (-1 == retval)
    return -1;
 
  ifnot (retval)
    {
    if (-1 == mkdir (dir, perm))
      return -1;
 
    st = lstat_file (dir);
 
    if (-1 == checkperm (st.st_mode, perm))
      return setperm (dir, perm);

    return 0;
    }
 
  if (-1 == checkperm (st.st_mode, perm))
    return setperm (dir, perm);

  return 0;
}
