loadfrom ("app/ved", "vedInit", NULL, &on_eval_err);

variable exit_code;

if (1 < __argc)
  exit_code = ved (__argv[1]);
else
  exit_code = ved (TEMPDIR + "/" + string (getpid ()) + "scratch.txt");

variable return_code = getenv ("return_code");

if (NULL == return_code)
  exit (0);

exit (exit_code);
