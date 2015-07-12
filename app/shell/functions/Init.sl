loadfile ("vars", NULL, &on_eval_err);

loadfrom ("crypt", "cryptInit", NULL, &on_eval_err);
loadfrom ("proc", "envs", 1, &on_eval_err);
loadfrom ("dir", "are_same_files", NULL, &on_eval_err);
loadfrom ("file", "fileis",  NULL, &on_eval_err);
loadfrom ("stdio", "appendstr", NULL, &on_eval_err);
loadfile ("funcs", NULL, &on_eval_err);
loadfile ("srv", NULL, &on_eval_err);
loadfrom ("com/intro", "intro", NULL, &on_eval_err);

loadfile ("initrline", NULL, &on_eval_err);

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

  OUTBG = init_ftype ("ashell");
  SCRATCH = init_ftype ("ashell");
  SHELL_VED = init_ftype ("ashell");

  OUTFDBG = init_stream (STDOUTBG);
 
  ifnot (access (RDFIFO, F_OK))
    () = remove (RDFIFO);

  ifnot (access (WRFIFO, F_OK))
    () = remove (WRFIFO);

  () = mkfifo (RDFIFO, 0644);
  () = mkfifo (WRFIFO, 0644);

  loadfile (path_dirname (__FILE__) + "/shell", NULL, &on_eval_err);

  shell ();
}
