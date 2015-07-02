sigprocmask (SIG_BLOCK, [SIGINT]);

private variable MYPATH = path_dirname (__FILE__);
private variable GO_ATEXIT = 0x0C8;
private variable GO_IDLED =  0x012c;
private variable RECONNECT = 0x0190;
private variable SHELL_SOCKET;
private variable SOCKADDR = getenv ("SOCKADDR");

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

define exit_me (err, code)
{
  on_eval_err (err, code);
}

loadfrom ("proc", "getdefenv", 1, &on_eval_err);

proc->getdefenv ();

private variable pw = getpwuid (getuid ());

if (NULL == pw)
  exit (1);

UID = pw.pw_uid;
GID = pw.pw_gid;
USER = pw.pw_name;

putenv ("USER=" + USER);
putenv ("LOGNAME=" + USER);
putenv ("USERNAME=" + USER);
putenv ("HOME=/home/" + USER); 
putenv ("GROUP=sudo");

importfrom ("std", "socket",  NULL, &on_eval_err);

$1 = socket (PF_UNIX, SOCK_STREAM, 0);
bind ($1, SOCKADDR);
listen ($1, 1);
SHELL_SOCKET = accept (__tmp ($1));

loadfrom ("sock", "sockInit", 1, &on_eval_err);

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

define go_idled ()
{
  send_int (SHELL_SOCKET, GO_IDLED);

  variable retval = get_int (SHELL_SOCKET);
  
  if (RECONNECT == retval)
    return 0;

  return 1;
}

loadfile ("Init", NULL, &on_eval_err);

define exit_me (exit_code)
{
  if (any ("input" == _get_namespaces ()))
    {
    variable f = __get_reference ("input->at_exit");

    (@f);
    }

  smg->reset ();

  send_int (SHELL_SOCKET, GO_ATEXIT);

  exit (exit_code);
}

define on_eval_err (err, code)
{
  () = array_map (Integer_Type, &fprintf, stderr, "%s\n", err);
  exit_me (code);
}

VED_ROWS = [1:LINES - 3];

init_shell ();
