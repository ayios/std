sigprocmask (SIG_BLOCK, [SIGINT]);

public variable
  VEDPROC = struct
    {
    _inited = 0,
    _fd,
    _state = 0,
    },
  FTYPES = Assoc_Type[Integer_Type],
  CONNECTED = 0x1,
  IDLED = 0x2,
  MODIFIED = 0x01,
  ONDISKMODIFIED = 0x02,
  RDONLY = 0x04,
  GET_TMPDIR = 0x01F4,
%  GET_EL_CHAR = 0x012C,
%  GETCH_LANG,
  DISPLAY = getenv ("DISPLAY"),
  LINES,
  COLUMNS,
  DRAWONLY,
  MSGROW,
  PROMPTROW,
  PROMPTCLR,
  INFOCLRBG,
  INFOCLRFG,
  VED_SOCKET;

if ("NULL" == DISPLAY)
  DISPLAY = NULL;

private variable
  MYPATH = path_dirname (__FILE__),
  JUST_DRAW = 0x064,
  GOTO_EXIT = 0x0C8,
  GET_COLS = 0x0190,
  GET_FILE = 0x0258,
  GET_ROWS = 0x02BC,
  %0x0320,
  GET_INFOCLRFG = 0x0384,
  GET_INFOCLRBG = 0x0385,
  GET_PROMPTCOLOR = 0x03E8,
  GET_MSGROW = 0x044C,
  GET_FUNC = 0x04b0,
  GET_LINES = 0x0514,
  VED_SOCKADDR = getenv ("VED_SOCKADDR");

variable COLOR = struct
  {
  normal, error, success, warn, prompt,
  border, focus, infoline, activeframe, hlchar,
  hlregion, topline
  };

FTYPES["txt"] = 0;
FTYPES["sl"] = 0;
FTYPES["list"] = 0;

set_slang_load_path (sprintf (
  "%s/ftypes/share%c%s", MYPATH,
  path_get_delimiter (),
  get_slang_load_path ()));

define on_eval_err (err, code)
{
  () = array_map (Integer_Type, &fprintf, stderr, "%s\n", err);
  exit (code);
}

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

loadfrom ("stdio", "readfile", NULL, &on_eval_err);
loadfrom ("dir", "isdirectory", NULL, &on_eval_err);
loadfrom ("sys", "which", NULL, &on_eval_err);
loadfrom ("string", "repeat", NULL, &on_eval_err);

loadfrom ("sock", "sockInit", 1, &on_eval_err);
loadfrom ("keys", "keysInit", 1, &on_eval_err);
loadfrom ("smg", "smgInit", 1, &on_eval_err);

loadfile (MYPATH + "/ftypes/Init", NULL, &on_eval_err);

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

define get_cols ()
{
  send_int (GET_COLS);
  return get_int ();
}

define get_lines ()
{
  send_int (GET_LINES);
  return get_int ();
}

define get_tmpdir ()
{
  send_int (GET_TMPDIR);
  return get_str ();
}

define get_msgrow ()
{
  send_int (GET_MSGROW);
  return get_int ();
}

define get_rows ()
{
  send_int (GET_ROWS);
  return get_int_ar ();
}

define get_file ()
{
  send_int (GET_FILE);
  return get_str ();
}

define get_ftype (fn)
{
  variable ftype = substr (path_extname (fn), 2, -1);
  ifnot (any (assoc_get_keys (FTYPES) == ftype))
    ftype = "txt";

  return ftype;
}

define get_infoclrfg ()
{
  send_int (GET_INFOCLRFG);
  return get_int ();
}

define get_infoclrbg ()
{
  send_int (GET_INFOCLRBG);
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

define exit_me (exit_code)
{
  variable
    tty_inited = __get_reference ("TTY_Inited"),
    reset = NULL != tty_inited ? __get_reference ("reset_tty") : NULL;

  if (@tty_inited)
    (@reset) ();

  smg->reset ();

  send_int (GOTO_EXIT);
  exit (exit_code);
}

define on_eval_err (err, code)
{
  () = array_map (Integer_Type, &fprintf, stderr, "%s\n", err);
  exit_me (code);
}

%CHANGE those calls to one
LINES = get_lines ();
COLUMNS = get_cols ();
MSGROW = get_msgrow ();
PROMPTROW = MSGROW - 1;
DRAWONLY = just_draw ();
INFOCLRFG = get_infoclrfg ();
INFOCLRBG = get_infoclrbg ();
PROMPTCLR = get_promptcolor ();

smg->init ();

array_map (Void_Type, &set_struct_field, COLOR, get_struct_field_names (COLOR),
    array_map (Integer_Type, &smg->get_color, get_struct_field_names (COLOR)));

variable TEMPDIR = get_tmpdir ();

private variable s_ = init_ftype (get_ftype (__argv[-1]));

VEDPROC._inited = 1;

s_.ved (__argv[-1], get_rows ());

exit_me (0);
