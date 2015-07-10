sigprocmask (SIG_BLOCK, [SIGINT]);

private variable MYPATH = path_dirname (__FILE__);
private variable GO_ATEXIT = 0x0C8;
private variable GO_IDLED =  0x012c;
private variable RECONNECT = 0x0190;
private variable VED_SOCKET;
private variable VED_SOCKADDR = getenv ("SOCKADDR");

set_slang_load_path (sprintf ("%s/functions/share%c%s", MYPATH,
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

loadfrom ("proc", "getdefenv", 1, &on_eval_err);
 
proc->getdefenv ();

private variable pw = getpwuid (getuid ());

if (NULL == pw)
  exit (1);

UID = pw.pw_uid;
GID = pw.pw_gid;
USER = pw.pw_name;

loadfrom ("sock", "sockInit", 1, &on_eval_err);
importfrom ("std", "socket",  NULL, &on_eval_err);

$1 = socket (PF_UNIX, SOCK_STREAM, 0);
bind ($1, VED_SOCKADDR);
listen ($1, 1);
VED_SOCKET = accept (__tmp ($1));

define send_int (i)
{
  sock->send_int (VED_SOCKET, i);
}

define get_int ()
{
  return sock->get_int (VED_SOCKET);
}

define get_int_ar ()
{
  return sock->get_int_ar (VED_SOCKET);
}

define get_str ()
{
  return sock->get_str (VED_SOCKET);
}

define exit_me (exit_code)
{
  send_int (GO_ATEXIT);
  exit (exit_code);
}

define go_idled ()
{
  send_int (GO_IDLED);
  variable retval = get_int ();

  if (RECONNECT == retval)
    return 0;

  return 1;
}

define on_eval_err (err, code)
{
  variable msg;

  if (Array_Type == typeof (err))
    {
    msg = substr (err[0], 1, COLUMNS);
    err = strjoin (err, "\n");
    }
  else
    msg = substr (err, 1, COLUMNS);

  tostderr (err);

  exit_me (code);
}

variable HASHEDDATA = NULL;

define getch ();

loadfrom ("keys", "keysInit", 1, &on_eval_err);
loadfrom ("smg", "smgInit", NULL, &on_eval_err);
loadfrom ("stdio", "readfile", NULL, &on_eval_err);
loadfrom ("ved", "vedtypes", NULL, &on_eval_err);
loadfrom ("ved", "vedvars", NULL, &on_eval_err);
loadfrom ("os", "passwd", 1, &on_eval_err);

define exit_me (exit_code)
{
  if (any ("input" == _get_namespaces ()))
    {
    variable f = __get_reference ("input->at_exit");
    (@f);
    }

  smg->reset ();

  send_int (GO_ATEXIT);
  exit (exit_code);
}

define on_eval_err (err, code)
{
  variable msg;

  if (Array_Type == typeof (err))
    {
    msg = substr (err[0], 1, COLUMNS);
    err = strjoin (err, "\n");
    }
  else
    msg = substr (err, 1, COLUMNS);

  tostderr (err);

  if (__is_initialized (&VED_CB))
    {
    send_msg_dr (msg, 1, NULL, NULL);
    VED_CB.vedloop ();
    }
  else
    exit_me (code);
}

loadfile (MYPATH + "/functions/Init", NULL, &on_eval_err);

define tostderr (str)
{
  () = lseek (VED_STDERRFD, 0, SEEK_END);
  () = write (VED_STDERRFD, str);
}

MSG = init_ftype ("txt");
txt_settype (MSG, VED_STDERR, VED_ROWS, NULL);

variable fname;

if (1 == __argc)
  fname = VED_SCRATCH_BUF;
else
  fname = __argv[-1];

private variable s_ = init_ftype (get_ftype (fname));

s_.ved (fname);
