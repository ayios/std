static define apptable ()
{
  variable i;
  variable ii;
  variable app;
  variable dir;
  variable apps;
  variable dirs = [USRDIR, STDDIR, LCLDIR];

  _for i (0, length (dirs) - 1)
    {
    dir = dirs[i];
    apps = listdir (dir + "/app");
    if (NULL == apps || (NULL != apps && 0 == length (apps)))
      continue;

    apps = apps[where (array_map (Integer_Type, &_isdirectory,
      array_map (String_Type, &path_concat, dir + "/app/", apps)))];

    _for ii (0, length (apps) - 1)
      {
      app = apps[ii];
      if (-1 == access (dir + "/app/" + app + "/" + app + "Init.sl", F_OK)
        &&-1 == access (dir + "/" + app + "/" + app + "Init.slc", F_OK))
        continue;

      APPSINFO[app] = @AppInfo_Type;
      
      APPSINFO[app].init = app + "Init";
      
      ifnot (access (dir + "/app/" + app + "help.txt", F_OK))
        APPSINFO[app].help = dir + "/app/" + app + "/help.txt";

      ifnot (access (dir + "/app/" + app + "info.txt", F_OK))
        APPSINFO[app].info = dir + "/app/" + app + "/info.txt";

      APPS[app] = Assoc_Type[App_Type];
      }
    }
}
