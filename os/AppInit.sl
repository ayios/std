loadfrom ("os", "apptypes", NULL, &on_eval_err);
loadfrom ("proc", "envs", 1, &on_eval_err);
loadfrom ("sock", "sockInit", NULL, &on_eval_err);

public variable CONNECTED = 0x1;
public variable IDLED = 0x2;
public variable GO_ATEXIT = 0x0C8;
public variable GO_IDLED =  0x012c;
public variable RECONNECT = 0x0190;
public variable APP_CON_NEW = 0x1f4;
public variable APP_RECON_OTH = 0x258;
public variable APPS = Assoc_Type[Assoc_Type];
public variable APPSINFO = Assoc_Type[AppInfo_Type];
public variable _APPS_;

loadfrom ("os", "appinit", 1, &on_eval_err);
