variable com = __argv[1];

__set_argc_argv (__argv[[1:]]);

() = evalfile (path_dirname (__FILE__) + "/../load");

variable openstdout = 1;
variable COMDIR;
variable _exit_me_;
variable PPID = getenv ("PPID");
variable BG = getenv ("BG");
variable BGPIDFILE;
variable BGX = 0;
variable WRFIFO = Dir.vget ("TEMPDIR") + "/" + string (PPID) + "_SRV_FIFO.fifo";
variable RDFIFO = Dir.vget ("TEMPDIR") + "/" + string (PPID) + "_CLNT_FIFO.fifo";
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
  BGPIDFILE = BG + "/" + string (Env.vget ("PID")) + ".RUNNING";
  () = open (BGPIDFILE, O_CREAT|O_TRUNC, S_IRUSR|S_IWUSR);

  signal (SIGALRM, &sigalrm_handler);
  }

define at_exit ()
{
  variable msg = qualifier ("msg");

  ifnot (NULL == msg)
    if (String_Type == typeof (msg) ||
       (Array_Type == typeof (msg) && _typeof (msg) == String_Type))
      IO.tostderr (msg);
}

define exit_me_bg (x)
{
  at_exit (;;__qualifiers);

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

  at_exit (;;__qualifiers);

  ifnot (NULL == BG)
    exit_me_bg (x);

  variable buf;

  () = write (WRFD, "exit");
  () = read (RDFD, &buf, 1024);

  exit (x);
}

_exit_me_ = NULL == BG ? &exit_me : &exit_me_bg;

private define tostdout ()
{
  loop (_NARGS) pop ();
}

__.fput ("IO", "tostdout?", &tostdout;ReInitFunc = 1);

public define __err_handler__ (__r__)
{
  variable code = 1;
  if (Integer_Type == typeof (__r__))
    code = __r__;

  (@_exit_me_) (code;;__qualifiers);
}

ifnot (access (stdoutfile, F_OK))
  stdoutfd = open (stdoutfile, File.vget ("FLAGS")[stdoutflags]);
else
  stdoutfd = open (stdoutfile, File.vget ("FLAGS")[stdoutflags], File.vget ("PERM")["__PUBLIC"]);

if (NULL == stdoutfd)
  (@_exit_me_) (1;msg = errno_string (errno));

load.from ("proc", "getdefenv", 1;err_handler = &__err_handler__);
load.from ("sock", "sockInit", NULL;err_handler = &__err_handler__);
load.from ("input", "inputInit", NULL;err_handler = &__err_handler__);
load.from ("parse", "cmdopt", NULL;err_handler = &__err_handler__);

define verboseon ()
{
  __.fput ("IO", "tostdout?", NULL;ReInitFunc = 1, FuncFname = "comtostdout",
    FuncRefName = "tostdout", __DIRNS__ = __.vget ("__", "__DIRNS__") + "/../print");
}

define verboseoff ()
{
  __.fput ("IO", "tostdout?", NULL;ReInitFunc = 1, FuncFname = "null_tostdout",
    FuncRefName = "tostdout", __DIRNS__ = __.vget ("__", "__DIRNS__") + "/../print");
}

load.from ("api", "comapi", NULL;err_handler = &__err_handler__);

define initproc (p)
{
  p.stdout.file = stdoutfile;
  p.stdout.wr_flags = stdoutflags;
}

if (NULL == BG)
  sigprocmask (SIG_UNBLOCK, [SIGINT]);

define sigint_handler (sig)
{
  IO.tostderr ("process interrupted by the user");
  (@_exit_me_) (130);
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

  variable i = 0;
  variable hl_reg = qualifier ("hl_region");

  ifnot (NULL == hl_reg)
    if (Array_Type == typeof (hl_reg))
      if (Integer_Type == _typeof (hl_reg))
        {
        variable tmp = @hl_reg;
        hl_reg = Array_Type[1];
        hl_reg[0] = tmp;
        i = 1;
        }
      else
        if (Array_Type == _typeof (hl_reg))
          if (length (hl_reg))
            if (Integer_Type == _typeof (hl_reg[0]))
              i = length (hl_reg);

  sock->send_str (WRFD, "ask");

  () = sock->get_bit (RDFD);

  sock->send_str (WRFD, strjoin (questar, "\n"));

  () = sock->get_bit (RDFD);

  sock->send_int (WRFD, i);

  if (i)
    {
    () = sock->get_bit (RDFD);

    _for i (0, i - 1)
      {
      sock->send_int_ar (RDFD, WRFD, hl_reg[i]);
      () = sock->get_bit (RDFD);
      }
    }
  else
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

  chr;
}

try
  load.from ("com/" + com, "comInit", NULL;err_handler = &__err_handler__);
catch AnyError:
  (@_exit_me_) (1;msg = __.efmt (NULL));

