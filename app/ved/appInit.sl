loadfrom ("app/ved", "vedInit", NULL, &on_eval_err);

if (1 < __argc)
  ved (__argv[1]);
else
  ved (TEMPDIR + "/" + string (getpid ()) + "scratch.txt");

exit (0);
