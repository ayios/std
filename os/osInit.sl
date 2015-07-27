public variable RLINE;
public variable APP_CON_OTH;
public variable APP_NEW;
public variable OSAPPSFILE = TEMPDIR + "/" + string (PID) + "_apps.txt";
public variable COAPPSFILE = TEMPDIR + "/" + string (PID) + "_conn_apps.txt";

loadfrom ("os", "AppInit", NULL, &on_eval_err);
loadfrom ("wind", "ostopline", NULL, &on_eval_err);
loadfrom ("stdio", "appendstr", NULL, &on_eval_err);
loadfrom ("os", "initved", NULL, &on_eval_err);
loadfrom ("os", "runapp", 1, &on_eval_err);
loadfrom ("api", "eval", NULL, &on_eval_err);
loadfrom ("os", "initrline", NULL, &on_eval_err);
loadfrom ("os", "osloop", NULL, &on_eval_err);

os->apptable ();

_APPS_ = assoc_get_keys (APPS);

if (-1 == writestring (OSAPPSFILE, strjoin (_APPS_, "\n")))
  exit_me (1);

RLINE = initrline ();

