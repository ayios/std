sigprocmask (SIG_BLOCK, [SIGINT]);

set_slang_load_path (loaddir + char (path_get_delimiter) +
  get_slang_load_path ());

variable GO_ATEXIT  = 0x0C8;
variable GO_IDLED   = 0x012c;
variable RECONNECT  = 0x0190;
variable SOCKADDR   = getenv ("SOCKADDR");
variable HASHEDDATA = NULL;
variable STDOUT     = TEMPDIR + "/" + string (PID) + app + "stdout." + stdouttype;
variable STDERR     = TEMPDIR + "/" + string (PID) + app + "stderr.txt";
variable SCRATCH;
variable SCRATCHFD;
variable STDOUTFD;
variable STDERRFD;
variable ERR_VED;
variable SOCKET;
variable RLINE = NULL;

ifnot (NULL == SCRATCHBUF)
  SCRATCHBUF = TEMPDIR + "/" + string (PID) + app +  "scratch.txt";

define on_eval_err (err, code)
{
  $1 = open (TEMPDIR + "/_" + app + "_.initerr", O_WRONLY|O_CREAT, S_IRWXU);
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

loadfrom ("sys", "getpw", NULL, &on_eval_err);

private variable err;

GROUP = setgrname (GID, &err);

if (NULL == GROUP)
  {
  tostderr (err);
  exit (1);
  }

putenv ("USER=" + USER);
putenv ("LOGNAME=" + USER);
putenv ("USERNAME=" + USER);
putenv ("HOME=/home/" + USER); 
putenv ("GROUP=" + GROUP);

importfrom ("std", "socket",  NULL, &on_eval_err);

$1 = open (TEMPDIR + "/_" + app + "_.init", O_WRONLY|O_CREAT, S_IRWXU);

$1 = socket (PF_UNIX, SOCK_STREAM, 0);
bind ($1, SOCKADDR);
listen ($1, 1);
SOCKET = accept (__tmp ($1));

() = remove (TEMPDIR + "/_" + app + "_.init");

loadfrom ("sock", "sockInit", 1, &on_eval_err);

define send_int (fd, i)
{
  sock->send_int (fd, i);
}

define get_int (fd)
{
  return sock->get_int (fd);
}

define go_idled ()
{
  send_int (SOCKET, GO_IDLED);

  variable retval = get_int (SOCKET);
  
  if (RECONNECT == retval)
    return 0;

  return 1;
}

define at_exit ()
{
  variable f;

  if (any ("input" == _get_namespaces ()))
    {
    f = __get_reference ("input->at_exit");
    (@f);
    }

  if (any ("smg" == _get_namespaces ()))
    {
    f = __get_reference ("smg->reset");
    (@f);
    }
}

define send_exit ()
{
  send_int (SOCKET, GO_ATEXIT);
}

define exit_me (exit_code)
{
  at_exit ();
  send_exit ();
  exit (exit_code);
}

define on_eval_err (err, code)
{
  at_exit ();
  () = array_map (Integer_Type, &fprintf, stderr, "%s\n", err);
  send_exit ();
  exit (code);
}

loadfrom ("input", "inputInit", NULL, &on_eval_err);
loadfrom ("keys", "keysInit", 1, &on_eval_err);
loadfrom ("smg", "smgInit", NULL, &on_eval_err);
loadfrom ("stdio", "readfile", NULL, &on_eval_err);
loadfrom ("ved", "vedtypes", NULL, &on_eval_err);
loadfrom ("ved", "vedvars", NULL, &on_eval_err);
loadfrom ("os", "passwd", 1, &on_eval_err);
loadfrom ("parse", "is_arg", NULL, &on_eval_err);
loadfrom ("rline", "rlineInit", NULL, &on_eval_err);
loadfrom ("proc", "procInit", NULL, &on_eval_err);
loadfrom ("smg", "smgInit", NULL, &on_eval_err);
loadfrom ("sys", "checkpermissions", NULL, &on_eval_err);
loadfrom ("sys", "setpermissions", NULL, &on_eval_err);
loadfrom ("string", "repeat", NULL, &on_eval_err);
loadfrom ("stdio", "getlines", NULL, &on_eval_err);
loadfrom ("smg", "widg", "widg", &on_eval_err);
loadfrom ("wind", app + "topline", NULL, &on_eval_err);

if (VED_LIB)
  {
  loadfrom ("os", "appclientfuncs", NULL, &on_eval_err);
  loadfrom ("ved", "vedlib", NULL, &on_eval_err);
  }

define init_stream (fname)
{
  variable fd;

  if (-1 == access (fname, F_OK))
    fd = open (fname, FILE_FLAGS["<>"], PERM["_PRIVATE"]);
  else
    fd = open (fname, FILE_FLAGS["<>|"], PERM["_PRIVATE"]);

  if (NULL == fd)
    {
    tostderr ("Can't open file " + fname + " " + errno_string (errno));
    exit_me ();
    }
 
  variable st = fstat (fd);
  if (-1 == checkperm (st.st_mode, PERM["_PRIVATE"]))
    if (-1 == setperm (fname, PERM["_PRIVATE"]))
      exit_me ();

  return fd;
}

define tostdout (str)
{
  () = lseek (STDOUTFD, 0, SEEK_END);
  () = write (STDOUTFD, str);
}

define tostderr (str)
{
  () = lseek (STDERRFD, 0, SEEK_END);
  () = write (STDERRFD, str);
}

STDOUTFD = init_stream (STDOUT);
STDERRFD = init_stream (STDERR);

loadfile ("Init", NULL, &on_eval_err);

ERR_VED = init_ftype ("txt");

ifnot (NULL == SCRATCHBUF)
  {
  SCRATCH = init_ftype ("txt");
  txt_settype (SCRATCH, SCRATCHBUF, VED_ROWS, NULL);
  SCRATCH._fd = init_stream (SCRATCHBUF);
  }
  
txt_settype (ERR_VED, STDERR, VED_ROWS, NULL);
ERR_VED._fd = STDERRFD;

RLINE = rlineinit ();
