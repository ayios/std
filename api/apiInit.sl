public variable APP;

loadfrom ("api", "apptype", NULL, &on_eval_err);

static define init (dir)
{
  variable s = @Api_Type;
  
  dir = path_dirname (dir);

  s.appname    = path_basename (dir);
  s.stdout     = qualifier ("stdout", 1);
  s.scratch    = qualifier ("scratch", 1);
  s.stderr     = qualifier ("stderr", 1);
  s.stdouttype = qualifier ("stdouttype", "ashell");
  s.ved        = qualifier ("ved", 1);,
  s.shell      = qualifier ("shell", 1);
  s.loaddir    = dir + "/functions";
  s.os         = qualifier ("os", 0);

  return s;
}
