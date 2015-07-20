loadfile ("vars", NULL, &on_eval_err);

loadfrom ("crypt", "cryptInit", NULL, &on_eval_err);
loadfrom ("proc", "envs", 1, &on_eval_err);
loadfrom ("dir", "are_same_files", NULL, &on_eval_err);
loadfrom ("file", "fileis",  NULL, &on_eval_err);
loadfrom ("stdio", "appendstr", NULL, &on_eval_err);

define intro ();

loadfile ("initrline", NULL, &on_eval_err);

loadfrom ("com/intro", "intro", NULL, &on_eval_err);

define shell ();

define init_shell ()
{
  ifnot (access (BGDIR, F_OK))
    ifnot (_isdirectory (BGDIR))
      on_eval_err (BGDIR + ": is not a directory", 1);
    else
      {}
  else
    if (-1 == mkdir (BGDIR, PERM["PRIVATE"]))
      on_eval_err (BGDIR + ": " + errno_string (errno), 1);

  SHELL_VED = init_ftype ("ashell");
  OUTBG = init_ftype ("ashell");
  STDOUTFDBG = init_stream (STDOUTBG);

  if (-1 == access (STACKFILE, F_OK))
    writestring (STACKFILE, "STACK = {}");

  loadfile ("shell", NULL, &on_eval_err);

  shell ();
}
