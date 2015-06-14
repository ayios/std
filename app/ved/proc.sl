sigprocmask (SIG_BLOCK, [SIGINT]);

private variable
  VEDPROC = struct
    {
    _inited = 0,
    _fd,
    _state = 0,
    },
  CONNECTED = 0x1,
  IDLED = 0x2,
  MYPATH = path_dirname (__FILE__),
  JUST_DRAW = 0x064,
  GOTO_EXIT = 0x0C8,
  GET_TMPDIR = 0x01F4,
  GET_FILE = 0x0258,
  GET_VED_INFOCLRFG = 0x0384,
  GET_VED_INFOCLRBG = 0x0385,
  GET_PROMPTCOLOR = 0x03E8,
  GET_FUNC = 0x04b0,
  VED_SOCKET,
  VED_SOCKADDR = getenv ("VED_SOCKADDR");

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

loadfrom ("proc", "setenv", 1, &on_eval_err);

proc->setdefenv ();

loadfrom ("sock", "sockInit", 1, &on_eval_err);

importfrom ("std", "socket",  NULL, &on_eval_err);

ifnot (VEDPROC._inited)
  {
  $1 = socket (PF_UNIX, SOCK_STREAM, 0);
  bind ($1, VED_SOCKADDR);
  listen ($1, 1);
  VED_SOCKET = accept (__tmp ($1));
  VEDPROC._fd = VED_SOCKET;
  VEDPROC._state = VEDPROC._state | CONNECTED;
  }

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
  send_int (GOTO_EXIT);
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

  exit_me (code);
}

loadfrom ("stdio", "readfile", NULL, &on_eval_err);
loadfrom ("sys", "which", NULL, &on_eval_err);

loadfile (MYPATH + "/functions/types", NULL, &on_eval_err);
loadfile (MYPATH + "/functions/vars", NULL, &on_eval_err);

loadfrom ("keys", "keysInit", 1, &on_eval_err);
loadfrom ("smg", "smgInit", NULL, &on_eval_err);

define exit_me (exit_code)
{
  if (any ("input" == _get_namespaces ()))
    {
    variable f = __get_reference ("input->at_exit");
    (@f);
    }

  smg->reset ();

  send_int (GOTO_EXIT);
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

define get_tmpdir ()
{
  send_int (GET_TMPDIR);
  return get_str ();
}

define get_file ()
{
  send_int (GET_FILE);
  return get_str ();
}

define get_infoclrfg ()
{
  send_int (GET_VED_INFOCLRFG);
  return get_int ();
}

define get_infoclrbg ()
{
  send_int (GET_VED_INFOCLRBG);
  return get_int ();
}

define get_promptcolor ()
{
  send_int (GET_PROMPTCOLOR);
  return get_int ();
}

define just_draw ()
{
  send_int (JUST_DRAW);
  return get_int ();
}

define get_func ()
{
  send_int (GET_FUNC);
  return get_int ();
}

define get_count ()
{
  send_int (0);
  ifnot (get_int ())
    return -1;

  send_int (0);
  return get_int ();
}

define tostderr (str)
{
  () = lseek (VED_STDERRFD, 0, SEEK_END);
  () = write (VED_STDERRFD, str);
}

define exit_me (exit_code)
{
  if (any ("input" == _get_namespaces ()))
    {
    variable f = __get_reference ("input->at_exit");
    (@f);
    }

  smg->reset ();

  send_int (GOTO_EXIT);
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

VED_ROWS = [1:LINES - 3];
MSGROW = LINES - 1;
PROMPTROW = MSGROW - 1;
VED_DRAWONLY = just_draw ();
VED_INFOCLRFG = get_infoclrfg ();
VED_INFOCLRBG = get_infoclrbg ();
VED_PROMPTCLR = get_promptcolor ();

MSG = init_ftype ("txt");
txt_settype (MSG, VED_STDERR, VED_ROWS, NULL);

private variable s_ = init_ftype (get_ftype (__argv[-1]));

VEDPROC._inited = 1;

s_.ved (__argv[-1]);

exit_me (0);
