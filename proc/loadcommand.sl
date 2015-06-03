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

define tostdout ()
{
  pop ();
};

define on_eval_err (ar, err)
{
  array_map (&tostderr, ar);
  exit (err);
}

variable COMDIR;
variable PPID = getenv ("PPID");

variable WRFIFO =  TEMPDIR + "/" + string (PPID) + "SRV_FIFO.fifo";
variable RDFIFO =  TEMPDIR + "/" + string (PPID) + "CLNT_FIFO.fifo";

variable RDFD = open (RDFIFO, O_RDONLY);
variable WRFD = open (WRFIFO, O_WRONLY);

loadfrom ("proc", "setenv", 1, &on_eval_err);

proc->setdefenv ();

loadfrom ("sock", "sockInit", NULL, &on_eval_err);

define exit_me (x)
{
  sock->send_str (WRFD, "exit");
  () = sock->get_bit (RDFD);
  exit (x);
}

define on_eval_err (ar, err)
{
  array_map (&tostderr, ar);
  exit_me (err);
}

loadfrom ("input", "inputInit", NULL, &on_eval_err);
loadfrom ("stdio", "readfile", NULL, &on_eval_err);
loadfrom ("parse", "cmdopt", NULL, &on_eval_err);
loadfrom ("sys", "which", NULL, &on_eval_err);

sigprocmask (SIG_UNBLOCK, [SIGINT]);

define sigint_handler (sig)
{
  tostderr ("process interrupted by the user");
  exit_me (130);
}

signal (SIGINT, &sigint_handler);

define sigint_handler_null ();
define sigint_handler_null (sig)
{
  signal (sig, &sigint_handler_null);
}

define verboseon ()
{
  loadfrom ("print", "tostdout", NULL, &on_eval_err);
}

define verboseoff ()
{
  loadfrom ("print", "null_tostdout", NULL, &on_eval_err);
}

define send_msg_dr (msg)
{
  sock->send_str (WRFD, "msgdr");

  () = sock->get_bit (RDFD);
  
  sock->send_str (WRFD, msg);
  
  () = sock->get_bit (RDFD);
}

define ask (questar, charar)
{
  signal (SIGINT, &sigint_handler_null);
  sigprocmask (SIG_BLOCK, [SIGINT]);

  sock->send_str (WRFD, "ask");

  () = sock->get_bit (RDFD);
  
  sock->send_str (WRFD, strjoin (questar, "\n"));
  
  () = sock->get_bit (RDFD);
  
  variable chr;

  while (chr = getch (), 0 == any (chr == charar));
  
  input->reset_tty ();
  
  sock->send_bit (WRFD, 1);

  () = sock->get_bit (RDFD);
  
  sigprocmask (SIG_UNBLOCK, [SIGINT]);
  signal (SIGINT, &sigint_handler);

  return chr;
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
      exit_me (1);
    }

  ifnot (access (helpfile, F_OK))
    ar = [ar, readfile (helpfile)];

  ifnot (length (ar))
    {
    tostdout ("No Help file available for " + com);
    exit_me (1);
    }

  array_map (&tostdout, ar);

  exit_me (_NARGS);
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
 
    exit_me (0);
    }

  ar = readfile (infofile);
  array_map (&tostdout, ar);
 
  exit_me (0);
}

loadfrom ("com/" + com, "comInit", NULL, &on_eval_err);
