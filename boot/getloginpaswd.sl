define getloginpaswd ();
define getloginpaswd (name, uid, gid, slsh)
{
  variable itter = qualifier ("itter", 1);
  variable p = proc->init (0, 0, 0);

  variable status = p.execv ([slsh, p.loadfile,
    path_dirname (__FILE__) + "/getloginpaswd_proc",
    name, string (uid), string (gid)], NULL);

  itter++;

  ifnot (status.exit_status)
    return;

  if (itter > 3)
    on_eval_err ("", status.exit_status);

  getloginpaswd (name, uid, gid, slsh;itter = itter);
}
