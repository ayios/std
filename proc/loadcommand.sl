variable com = __argv[1];

__set_argc_argv (__argv[[1:]]);

() = evalfile (path_dirname (__FILE__) + "/../load");

variable openstdout = 1;
variable COMDIR;
variable PPID = getenv ("PPID");
variable BG = getenv ("BG");
variable BGPIDFILE;
variable BGX = 0;
variable WRFIFO = TEMPDIR + "/" + string (PPID) + "_SRV_FIFO.fifo";
variable RDFIFO = TEMPDIR + "/" + string (PPID) + "_CLNT_FIFO.fifo";
variable RDFD = NULL;
variable WRFD = NULL;
variable stdoutfile = getenv ("stdoutfile");
variable stdoutflags = getenv ("stdoutflags");
variable stdoutfd;

define sigalrm_handler (sig)
{
  if (NULL == WRFD)
    WRFD = open (WRFIFO, O_WRONLY);

  () = write (WRFD, "exit");

  variable ref = __get_reference ("input->at_exit");
  ifnot (NULL == ref)
    (@ref);

  exit (BGX);
}

if (NULL == BG)
  {
  RDFD = open (RDFIFO, O_RDONLY);
  WRFD = open (WRFIFO, O_WRONLY);
  }

ifnot (NULL == BG)
  {
  BGPIDFILE = BG + "/" + string (PID) + ".RUNNING";
  () = open (BGPIDFILE, O_CREAT|O_TRUNC, S_IRUSR|S_IWUSR);

  signal (SIGALRM, &sigalrm_handler);
  }

define exit_me_bg (x)
{
  () = rename (BGPIDFILE, substr (
    BGPIDFILE, 1, strlen (BGPIDFILE) - strlen (".RUNNING")) + ".WAIT");

  BGX = x;

  forever
    sleep (86400);
}

define exit_me (x)
{
  variable ref = __get_reference ("input->at_exit");
  (@ref);

  ifnot (NULL == BG)
    exit_me_bg (x);
  
  variable buf;

  () = write (WRFD, "exit");
  () = read (RDFD, &buf, 1024);

  exit (x);
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
  exit_me (err);
}

ifnot (access (stdoutfile, F_OK))
  stdoutfd = open (stdoutfile, FILE_FLAGS[stdoutflags]);
else
  stdoutfd = open (stdoutfile, FILE_FLAGS[stdoutflags], PERM["__PUBLIC"]);

if (NULL == stdoutfd)
  on_eval_err (errno_string (errno), 1);

loadfrom ("proc", "getdefenv", 1, &on_eval_err);

proc->getdefenv ();

loadfrom ("sock", "sockInit", NULL, &on_eval_err);
loadfrom ("input", "inputInit", NULL, &on_eval_err);
loadfrom ("parse", "cmdopt", NULL, &on_eval_err);

define verboseon ()
{
  loadfrom ("print", "comtostdout", NULL, &on_eval_err);
}

define verboseoff ()
{
  loadfrom ("print", "null_tostdout", NULL, &on_eval_err);
}

define initproc (p)
{
  p.stdout.file = stdoutfile;
  p.stdout.wr_flags = stdoutflags;
}

if (NULL == BG)
  sigprocmask (SIG_UNBLOCK, [SIGINT]);

define sigint_handler (sig)
{
  tostderr ("process interrupted by the user");
  exit_me (130);
}

if (NULL == BG)
  signal (SIGINT, &sigint_handler);

define sigint_handler_null ();
define sigint_handler_null (sig)
{
  signal (sig, &sigint_handler_null);
}

define close_smg ()
{
  sock->send_str (WRFD, "close_smg");

  () = sock->get_bit (RDFD);
}

define restore_smg ()
{
  sock->send_str (WRFD, "restore_smg");

  () = sock->get_bit (RDFD);
}

define send_msg_dr (msg)
{
  sock->send_str (WRFD, "send_msg_dr");

  () = sock->get_bit (RDFD);
 
  sock->send_str (WRFD, msg);
 
  () = sock->get_bit (RDFD);
}

define ask (questar, charar)
{
  if (NULL == BG)
    {
    signal (SIGINT, &sigint_handler_null);

    sigprocmask (SIG_BLOCK, [SIGINT]);
    }

  sock->send_str (WRFD, "ask");

  () = sock->get_bit (RDFD);
 
  sock->send_str (WRFD, strjoin (questar, "\n"));
 
  () = sock->get_bit (RDFD);
 
  variable chr;
 
  if (qualifier_exists ("get_int"))
    {
    variable
      len,
      retval = "";
 
    send_msg_dr ("integer: ");

    chr = getch ();

    while ('\r' != chr)
      {
      if  ('0' <= chr <= '9')
        retval+= char (chr);

      if (any ([0x110, 0x8, 0x07F] == chr))
        retval = retval[[:-2]];
 
      send_msg_dr ("integer: " + retval);

      chr = getch ();
      }

    chr = retval;
    }
  else
    {
    send_msg_dr (strjoin (array_map (String_Type, &char, charar), "/") + " ");
    while (chr = getch (), 0 == any (chr == charar));
    }
 
  sock->send_str (WRFD, "restorestate");

  () = sock->get_bit (RDFD);
 
  if (NULL == BG)
    {
    sigprocmask (SIG_UNBLOCK, [SIGINT]);

    signal (SIGINT, &sigint_handler);
    }

  send_msg_dr (" ");

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
