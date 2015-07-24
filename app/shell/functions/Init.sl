loadfile ("vars", NULL, &on_eval_err);

loadfrom ("crypt", "cryptInit", NULL, &on_eval_err);
loadfrom ("dir", "are_same_files", NULL, &on_eval_err);

define intro ();

loadfile ("initrline", NULL, &on_eval_err);

loadfrom ("com/intro", "intro", NULL, &on_eval_err);

define shell ();

define init_shell ()
{
  if (-1 == access (STACKFILE, F_OK))
    writestring (STACKFILE, "STACK = {}");

  loadfile ("shell", NULL, &on_eval_err);

  shell ();
}
