loadfrom ("os", "apptypes", NULL, &on_eval_err);

public variable RLINE;
public variable CONNECTED_APPS = String_Type[0];
public variable CONNECTED_PIDS = Integer_Type[0];
public variable CUR_IND = -1;
public variable CONNECTED = 0x1;
public variable IDLED = 0x2;
public variable GO_ATEXIT = 0x0C8;
public variable GO_IDLED =  0x012c;
public variable RECONNECT = 0x0190;
public variable APP_CON_NEW = 0x1f4;
public variable APP_RECON_OTH = 0x258;
public variable APP_GET_ALL = 0x2bc;
public variable APP_GET_CONNECTED = 0x320;
public variable APPS = Assoc_Type[Assoc_Type];
public variable APPSINFO = Assoc_Type[AppInfo_Type];
public variable _APPS_;

loadfrom ("proc", "envs", 1, &on_eval_err);
loadfrom ("sock", "sockInit", NULL, &on_eval_err);
loadfrom ("wind", "ostopline", NULL, &on_eval_err);
loadfrom ("os", "initved", NULL, &on_eval_err);
loadfrom ("os", "appfuncs", NULL, &on_eval_err);
loadfrom ("os", "appinit", 1, &on_eval_err);
loadfrom ("stdio", "appendstr", NULL, &on_eval_err);
loadfrom ("api", "eval", NULL, &on_eval_err);
loadfrom ("os", "initrline", NULL, &on_eval_err);
loadfrom ("os", "osloop", NULL, &on_eval_err);

os->apptable ();

_APPS_ = assoc_get_keys (APPS);

RLINE = initrline ();

