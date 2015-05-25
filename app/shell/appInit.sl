sigprocmask (SIG_BLOCK, [SIGINT]);

loadfrom ("app/shell", "shellInit", NULL, &on_eval_err);

shell ();

exit (0);
