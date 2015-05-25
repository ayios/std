loadfrom ("dir", "fileexists", NULL, &on_eval_err);
loadfrom ("dir", "istype", NULL, &on_eval_err);

define isdirectory (dir, st)
{
  ifnot (fileexists (dir))
    return 0;

  @st = lstat_file (dir);
 
  ifnot (istype (@st, "dir"))
    return -1;

  return 1;
}

define __isdirectory (dir)
{
  ifnot (fileexists (dir))
    return 0;

  variable st = stat_file (dir);
 
  return istype (st, "dir");
    return 0;
}

define _isdirectory (dir)
{
  ifnot (fileexists (dir))
    return 0;

  variable st = lstat_file (dir);
 
  return istype (st, "dir");
}
