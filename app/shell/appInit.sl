sigprocmask (SIG_BLOCK, [SIGINT]);

loadfrom ("app/shell", "shellInit", NULL, &on_eval_err);

variable status = shell ();

exit (status);
