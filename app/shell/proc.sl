sigprocmask (SIG_BLOCK, [SIGINT]);

public variable
  SHELLPROC = struct
    {
    _inited = 0,
    _fd,
    _state = 0,
    },
  CONNECTED = 0x1,
  IDLED = 0x2;

private variable
  MYPATH = path_dirname (__FILE__),
  GOTO_EXIT = 0x0C8,
  SHELL_SOCKET,
  SHELL_SOCKADDR = getenv ("SHELL_SOCKADDR");

set_slang_load_path (sprintf ("%s/functions%c%s", MYPATH,
  path_get_delimiter (), get_slang_load_path ()));

define on_eval_err (err, code)
{
  () = array_map (Integer_Type, &fprintf, stderr, "%s\n", err);
  exit (code);
}

define tostderr (str)
{
  () = fprintf (stderr, "%s\n", str);
}

define exit_me ();

loadfrom ("proc", "setenv", 1, &on_eval_err);

proc->setdefenv ();

importfrom ("std", "socket",  NULL, &on_eval_err);

ifnot (SHELLPROC._inited)
  {
  $1 = socket (PF_UNIX, SOCK_STREAM, 0);
  bind ($1, SHELL_SOCKADDR);
  listen ($1, 1);
  SHELL_SOCKET = accept (__tmp ($1));
  SHELLPROC._fd = SHELL_SOCKET;
  SHELLPROC._state = SHELLPROC._state | CONNECTED;
  }

loadfrom ("sys", "which", NULL, &on_eval_err);
loadfrom ("sock", "sockInit", 1, &on_eval_err);
loadfrom ("proc", "procInit", NULL, &on_eval_err);
loadfrom ("smg", "smgInit", NULL, &on_eval_err);
loadfrom ("input", "inputInit", NULL, &on_eval_err);
loadfrom ("wind", "shelltopline", NULL, &on_eval_err);
loadfrom ("rline", "rlineInit", NULL, &on_eval_err);

loadfile ("Init", NULL, &on_eval_err);

define send_int (fd, i)
{
  sock->send_int (fd, i);
}

define get_int (fd)
{
  return sock->get_int (fd);
}

define get_int_ar (fd)
{
  return sock->get_int_ar (fd);
}

define get_str_ar (fd)
{
  return sock->get_str_ar (fd);
}

define get_str (fd)
{
  return sock->get_str (fd);
}

define exit_me (exit_code)
{
  if (any ("input" == _get_namespaces ()))
    {
    variable f = __get_reference ("input->at_exit");
    (@f);
    }

  smg->reset ();

  send_int (SHELLPROC._fd, GOTO_EXIT);
  exit (exit_code);
}

define on_eval_err (err, code)
{
  () = array_map (Integer_Type, &fprintf, stderr, "%s\n", err);
  exit_me (code);
}

VED_ROWS = [1:LINES - 3];

smg->init ();

init_shell ();

exit_me (0);
