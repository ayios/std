sigprocmask (SIG_BLOCK, [SIGINT]);

load.module ("std", "socket",  NULL;err_handler = &__err_handler__);

load.from ("api", "atexit", NULL;err_handler = &__err_handler__);
load.from ("api", "err_handler", NULL;err_handler = &__err_handler__);
load.from ("sys", "getpw", NULL;err_handler = &__err_handler__);
load.from ("sys", "checkpermissions", NULL;err_handler = &__err_handler__);
load.from ("sys", "setpermissions", NULL;err_handler = &__err_handler__);
load.from ("api", "initstream", NULL;err_handler = &__err_handler__);
load.from ("api", "vars", NULL;err_handler = &__err_handler__);
load.from ("input", "inputInit", NULL;err_handler = &__err_handler__);
load.from ("smg", "smginit", 1;err_handler = &__err_handler__);
load.from ("os", "getpasswd", NULL;err_handler = &__err_handler__);
load.from ("os", "passwd", 1;err_handler = &__err_handler__);
load.from ("parse", "is_arg", NULL;err_handler = &__err_handler__);
load.from ("rline", "rlineInit", NULL;err_handler = &__err_handler__);
load.from ("proc", "procInit", NULL;err_handler = &__err_handler__);
load.from ("sock", "sock", NULL);
load.from ("api", "vedlib", NULL;err_handler = &__err_handler__);
load.from ("wind", APP.appname + "topline", NULL;err_handler = &__err_handler__);

if (APP.vedlib || NULL != APP.excom)
  load.from ("api", "clientfuncs", NULL;err_handler = &__err_handler__);

if (APP.vedrline)
  load.from ("api", "vedreal", NULL;err_handler = &__err_handler__);
else
  {
  VED_RLINE = 0;
  VED_ISONLYPAGER = 1;
  }

if (APP.os)
  {
  load.from ("proc", "getdefenv", 1;err_handler = &__err_handler__);
  load.from ("api", "setenv", NULL;err_handler = &__err_handler__);
  load.from ("api", "connect", NULL;err_handler = &__err_handler__);
  load.from ("api", "osstdfuncs", NULL;err_handler = &__err_handler__);
  load.from ("api", "osapprl", NULL;err_handler = &__err_handler__);
  }
else
  load.from ("api", "stdfuncs", NULL;err_handler = &__err_handler__);

load.from ("api", "wind_mang", NULL;err_handler = &__err_handler__);
load.from ("api", "openstderr", NULL;err_handler = &__err_handler__);
load.from ("api", "openscratch", NULL;err_handler = &__err_handler__);

if (APP.stdout || NULL != APP.excom)
  load.from ("api", "openstdout", NULL;err_handler = &__err_handler__);

load.from ("api", "idle", NULL;err_handler = &__err_handler__);

ifnot (NULL == APP.excom)
  {
  variable GREPFILE = Dir->Vget ("TEMPDIR") + "/" + string (Env->Vget ("PID")) + "grep.list";
  load.from ("file", "fileis",  NULL;err_handler = &__err_handler__);
  load.from ("proc", "envs", 1;err_handler = &__err_handler__);
  load.from ("api", "openbg", NULL;err_handler = &__err_handler__);
  load.from ("api", "cominit", NULL;err_handler = &__err_handler__);
  load.from ("api", "filterexcom", NULL;err_handler = &__err_handler__);
  }

ifnot (APP.vedrline)
  load.from ("api", "framefuncs", NULL;err_handler = &__err_handler__);

load.from ("api", "appfunc", NULL;err_handler = &__err_handler__);

load.from ("app/" + APP.appname + "/functions", "Init", NULL;err_handler = &__err_handler__);

define __initrline ()
{
  variable w;

  if (_NARGS)
    {
    w = ();
    w = VED_WIND[w];
    }
  else
    w = get_cur_wind ();

  ifnot (NULL == APP.excom)
    w.rline = rlineinit (;
      osappnew = __get_reference ("_osappnew_"),
      osapprec = __get_reference ("_osapprec_"),
      wind_mang = __get_reference ("wind_mang"),
      filterargs = __get_reference ("filterexargs"),
      filtercommands = __get_reference ("filterexcom"));
  else
    w.rline = rlineinit (;
      wind_mang = __get_reference ("wind_mang"),
      oscompl = __get_reference ("_osappnew_"),
      osapprec = __get_reference ("_osapprec_"),
      );
}

define __rehash ()
{
  __initrline ();
}

__initrline ();

UNDELETABLE = [UNDELETABLE, SPECIAL];
