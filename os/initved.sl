VED_RLINE = 0;
VED_MAXFRAMES = 1;
VED_ISONLYPAGER = 1;

ERR = init_ftype ("txt");
txt_settype (ERR, STDERR, VED_ROWS, NULL);
setbuf (ERR._absfname);
ERR._fd = STDERRFD;

loadfrom ("api", "clientfuncs", NULL, &on_eval_err);

define _messages_ (argv)
{
  viewfile (ERR, "OS", NULL, NULL);
}
