public variable APP;

load.from ("api", "apptype", NULL;err_handler = &__err_handler__);

static define init (dir)
{
  variable s = @Api_Type;

  dir = path_dirname (dir);

  s.appname    = path_basename (dir);
  s.stdout     = qualifier ("stdout", 1);
  s.stdouttype = qualifier ("stdouttype", "ashell");
  s.vedlib     = qualifier ("vedlib", 1);
  s.vedrline   = qualifier ("vedrline", 0);
  s.realshell  = qualifier ("realshell", 0);
  s.excom      = qualifier ("excom", NULL);
  s.loaddir    = "app/" + s.appname + "/functions";
  s.os         = qualifier ("os", 0);
  s.tmpdir     = qualifier ("tmpdir", Dir.vget ("TEMPDIR") + "/" + s.appname + "_" +
    string (Env.vget ("PID")) + "_" + string (_time)[[5:]]);

  if (NULL != s.excom && 1 == s.excom)
    {
    s.excom = @Excom_Type;
    s.excom.scratch  = qualifier ("exscratch", 1);
    s.excom.messages = qualifier ("exmessages", 1);
    s.excom.edit     = qualifier ("exedit", 1);
    s.excom.ved      = qualifier ("exved", 1);
    s.excom.eval     = qualifier ("exeval", 1);
    }

  s;
}
