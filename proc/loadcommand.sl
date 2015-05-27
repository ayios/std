public variable com = __argv[1];

__set_argc_argv (__argv[[1:]]);

() = evalfile (path_dirname (__FILE__) + "/../load");

define on_eval_err ()
{
  exit (1);
}

define tostderr (str)
{
  () = fprintf (stderr, "%s\n", str);
}

define tostdout () {pop ();};

define on_eval_err (ar, err)
{
  array_map (&tostderr, ar);
  exit (err);
}

loadfrom ("input", "inputInit", NULL, &on_eval_err);
loadfrom ("stdio", "readfile", NULL, &on_eval_err);
loadfrom ("parse", "cmdopt", NULL, &on_eval_err);
loadfrom ("sys", "which", NULL, &on_eval_err);
loadfrom ("sock", "sockInit", NULL, &on_eval_err);

variable
  LINES = atoi (getenv ("LINES")),
  COLUMNS = atoi (getenv ("COLUMNS"));

variable COMDIR;

define verboseon ()
{
  loadfrom ("print", "tostdout", NULL, &on_eval_err);
}

define ask (questar, charar)
{
%  variable pid = atoi (getenv ("PID"));
%  variable fifofile = "/tmp/shellfifo";
%  ifnot (access (fifofile, F_OK))
%    () = remove (fifofile);
%  () = mkfifo (fifofile, S_IWUSR|S_IRUSR|S_IXUSR|S_IWGRP|S_IRGRP|S_IXGRP|S_IWOTH|S_IXOTH|S_IROTH);
%  variable fd = open (fifofile, O_RDWR);
%  () = kill (pid, SIGALRM);
% sleep (1);
%  %sock->send_str (fd, "ask");
%  () = write (fd, "ask");
%  () = sock->get_bit (fd);
%  sock->send_str_ar (fd, questar);
%  () = sock->get_bit (fd);
%  sock->send_int_ar (fd, charar);
%  variable chr = sock->get_int (fd);
%variable b;
%variable s = read (fd, &b, 2);
%  () = remove (fifofile);
%return 'y';
  
variable chr;

while (chr = getch (), 0 == any (chr == charar));
input->reset_tty ();
return chr;
  %return chr;
}

define _usage ()
{
  verboseon ();

  variable
    if_opt_err = _NARGS ? () : " ",
    helpfile = qualifier ("helpfile", sprintf ("%s/help.txt", COMDIR)),
    ar = _NARGS ? [if_opt_err] : String_Type[0];

  if (NULL == helpfile)
    {
    tostderr ("No Help file available for " + com);

    ifnot (length (ar))
      exit (1);
    }

  ifnot (access (helpfile, F_OK))
    ar = [ar, readfile (helpfile)];

  ifnot (length (ar))
    {
    tostdout ("No Help file available for " + com);
    exit (1);
    }

  array_map (&tostdout, ar);

  exit (_NARGS);
}

define info ()
{
  verboseon ();

  variable
    info_ref = NULL,
    infofile = qualifier ("infofile", sprintf ("%s/desc.txt", COMDIR)),
    ar;

  if (NULL == infofile || -1 == access (infofile, F_OK))
    {
    tostdout ("No Info file available for " + com);
 
    exit (0);
    }

  ar = readfile (infofile);
  array_map (&tostdout, ar);
 
  exit (0);
}

loadfrom ("com/" + com, "comInit", NULL, &on_eval_err);
