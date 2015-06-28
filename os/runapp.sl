static define runapp ()
{
  variable app = qualifier ("argv0");

  ifnot (any (app == _APPS_))
    {
    tostderr (app + ": No such application");
    return;
    }
  
  sigprocmask (SIG_BLOCK, [SIGINT]);
  smg->reset ();
  
  loadfrom ("app/" + app, APPSINFO[app].init, app, &on_eval_err);
  
  variable ref = __get_reference (app + "->" + app);
  variable exit_code = (@ref);

  smg->init ();
  sigprocmask (SIG_UNBLOCK, [SIGINT]);
  
   osdraw (ERR);
}
