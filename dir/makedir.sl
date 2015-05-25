loadfrom ("dir", "istype", NULL, &on_eval_err);
loadfrom ("dir", "isdirectory", NULL, &on_eval_err);
loadfrom ("sys", "checkpermissions", NULL, &on_eval_err);
loadfrom ("sys", "setpermissions", NULL, &on_eval_err);

define makedir (dir, perm)
{
  variable
    st,
    retval = isdirectory (dir, &st);

  if (-1 == retval)
    {
    tostderr (dir + " is not a directory");
    return -1;
    }
 
  ifnot (retval)
    {
    if (-1 == mkdir (dir))
      {
      tostderr (dir + " cannot create directory, " + errno_string (errno));
      return -1;
      }
    else
      tostdout ("created directory `" + dir + "'");
 
    st = lstat_file (dir);
 
    ifnot (NULL == perm)
      if (-1 == checkperm (st.st_mode, perm))
        return setperm (dir, perm);

    return 0;
    }

  ifnot (NULL == perm)
    if (-1 == checkperm (st.st_mode, perm))
      return setperm (dir, perm);

  return 0;
}

define _makedir (dir, perm)
{
  variable
    st,
    retval = isdirectory (dir, &st);

  if (-1 == retval)
    {
    tostderr (dir + " is not a directory");
    return -1;
    }
 
  if (-1 == mkdir (dir))
    {
    tostderr (dir + " cannot create directory, " + errno_string (errno));
    return -1;
    }
  else
    tostdout ("created directory `" + dir + "'");
 
  st = lstat_file (dir);
 
  ifnot (NULL == perm)
    if (-1 == checkperm (st.st_mode, perm))
      return setperm (dir, perm);

  ifnot (NULL == perm)
    if (-1 == checkperm (st.st_mode, perm))
      return setperm (dir, perm);

  return 0;
}
