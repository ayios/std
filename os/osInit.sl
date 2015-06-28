loadfrom ("os", "apptypes", NULL, &on_eval_err);

public variable CONNECTED = 0x1;
public variable IDLED = 0x2;
public variable GO_ATEXIT = 0x0C8;
public variable GO_IDLED =  0x12c;
public variable APPS = Assoc_Type[Assoc_Type];
public variable APPSINFO = Assoc_Type[AppInfo_Type];
public variable _APPS_;
public variable OSRL;

loadfrom ("wind", "osTopline", NULL, &on_eval_err);
loadfrom ("stdio", "appendstr", NULL, &on_eval_err);
loadfrom ("stdio", "readfile", NULL, &on_eval_err);

loadfrom ("rline", "rlineInit", NULL, &on_eval_err);
loadfrom ("os", "initved", NULL, &on_eval_err);

loadfrom ("os", "appinit", 1, &on_eval_err);
loadfrom ("os", "runapp", 1, &on_eval_err);
loadfrom ("os", "evalfunc", NULL, &on_eval_err);
loadfrom ("os", "initrline", NULL, &on_eval_err);
loadfrom ("os", "osloop", NULL, &on_eval_err);

os->apptable ();

_APPS_ = assoc_get_keys (APPS);
OSRL = initrline ();

