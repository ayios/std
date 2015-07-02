static define runapp ()
{
  variable argv = __pop_list (_NARGS);

  argv = list_to_array (argv, String_Type);

  variable app = qualifier ("argv0");

  ifnot (any (app == _APPS_))
    {
    tostderr (app + ": No such application");
    return;
    }
  
  variable setid = struct 
    {
    setid = 1,
    uid = UID,
    gid = GID,
    user = USER
    };

  variable issu = is_arg ("--su", argv);
  ifnot (NULL == issu)
    {
    setid.uid = 0;
    setid.gid = 0;
    setid.user = "root";
    argv[issu] = NULL;
    argv = argv[wherenot (_isnull (argv))];
    }

  variable args = {};
  variable i;

  _for i (0, length (argv) - 1)
    list_append (args, argv[i]);

  smg->reset ();
  
  loadfrom ("app/" + app, APPSINFO[app].init, app, &on_eval_err);
  
  variable ref = __get_reference (app + "->" + app);
  variable exit_code = (@ref) (__push_list (args);;setid);

  smg->init ();
  
  osdraw (ERR);
}
