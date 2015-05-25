typedef struct
  {
  _fname,
  _sockaddr,
  _fd,
  _state,
  _exists,
  _func,
  _count,
  _drawonly,
  _issudo,
  _tmpdir,
  _slshbin,
  p_,
  } Ved_Type;

private variable ved_;
private variable funcs = Assoc_Type[Ref_Type];

private variable
  CONNECTED = 0x1,
  IDLED = 0x2,
  JUST_DRAW = 0x064,
  GOTO_EXIT = 0x0C8,
  SEND_TMPDIR = 0x01F4,
  SEND_FILE = 0x0258,
  SEND_ROWS = 0x02BC,
  SEND_VED_INFOCLRFG = 0x0384,
  SEND_VED_INFOCLRBG = 0x0385,
  SEND_PROMPTCOLOR = 0x03E8,
  SEND_FUNC = 0x04b0;

private define ved_exit ()
{
  variable status = waitpid (ved_.p_.pid, 0);
  ved_.p_.atexit ();

  () = close (ved_._fd);
  __uninitialize (&ved_);
}

private define send_tmpdir (sock)
{
  sock->send_str (sock, ved_._tmpdir);
}

private define send_func (sock)
{
  sock->send_int (sock, NULL == ved_._func ? 0 : ved_._func);

  ifnot (NULL == ved_._func)
    {
    () = sock->get_int (sock);
    sock->send_int (sock, NULL == ved_._count ? 0 : 1);

    ifnot (NULL == ved_._count)
      {
      () = sock->get_int (sock);
      sock->send_int (sock, ved_._count);
      }
    }
}

private define just_draw (sock)
{
  sock->send_int (sock, ved_._drawonly);
}

private define send_rows (sock)
{
  sock->send_int_ar (sock, [[1:LINES-3]]);
}

private define send_file (sock)
{
  sock->send_str (sock, ved_._fname);
}

private define send_infoclrfg (sock)
{
  sock->send_int (sock, 4);
}

private define send_infoclrbg (sock)
{
  sock->send_int (sock, 5);
}

private define send_promptcolor (sock)
{
  sock->send_int (sock, 3);
}

private define addflags (p)
{
  p.stderr.file = "/tmp/err";
  p.stderr.wr_flags = ">|";
}

private define broken_sudoproc_broken ()
{
%  variable passwd = root.lib.getpasswd ();
%
%  ifnot (strlen (passwd))
%    {
%    srv->send_msg ("Password is an empty string. Aborting ...", -1);
%    return NULL;
%    }
%
%  variable retval = root.lib.validate_passwd (passwd);
%
%  if (NULL == retval)
%    {
%    srv->send_msg ("This is not a valid password", -1);
%    return NULL;
%    }
%
%  variable p = proc->init (1, 1, 1);
%
%  p.stdin.in = passwd;
%  return p;
}

private define getargvenv (p)
{
  variable
    argv = [SLSH_BIN, p.loadfile, path_dirname (__FILE__) + "/proc", ved_._fname],
    env = [proc->getdefenv (), sprintf ("VED_SOCKADDR=%s", ved_._sockaddr)];

  ifnot (NULL == DISPLAY)
    env = [env, "DISPLAY=" + DISPLAY];

  ifnot (NULL == XAUTHORITY)
    env = [env, "XAUTHORITY=" + XAUTHORITY];

  return argv, env;
}

private define doproc ()
{
  variable p, argv, env;

  ifnot (ved_._issudo)
    {
    if (p = proc->init (0, 0, 1), p == NULL)
      return NULL;
    }
  else
    if (p = broken_sudoproc_broken (), p == NULL)
      return NULL;

  addflags (p);

  (argv, env) = getargvenv (p);

  if (NULL == p.execve (argv, env, 1))
    return NULL;

  return p;
}

private define is_file (fn)
{
  ifnot (stat_is ("reg", stat_file (fn).st_mode))
    {
    () = fprintf (stderr, "%s: is not a regular file", fn);
    return -1;
    }

  return 0;
}

private define is_file_readable (fn, issudo)
{
  if (-1 == access (fn, R_OK) && 0 == issudo)
    {
    () = fprintf (stderr, "%s: is not readable", fn);
    return -1;
    }

  return 0;
}

private define check_file (fn, issudo)
{
  ifnot (access (fn, F_OK))
    {
    if (-1 == is_file (fn))
      return -1;
 
    if (-1 == is_file_readable (fn, issudo))
      return -1;

    return 1;
    }

  return 0;
}

private define parse_args ()
{
  variable issudo = ();
  variable fname = ();

 % ifnot (_NARGS - 2)
 %   @fname = CW.buffers[CW.cur.frame].fname;
 % else
    @fname = ();
 
  variable exists = check_file (@fname, issudo);

  if (-1 == exists)
    return -1;

  return exists;
}

private define connect_to_child ()
{
  ved_._fd = ved_.p_.connect (ved_._sockaddr);

  if (NULL == ved_._fd)
    {
    ved_.p_.atexit ();
    () = kill (ved_.p_.pid, SIGKILL);
    return;
    }
 
  ved_._state = ved_._state | CONNECTED;

  variable retval;

  forever
    {
    retval = sock->get_int (ved_._fd);
 
    ifnot (Integer_Type == typeof (retval))
      break;

    if (retval == GOTO_EXIT)
      {
      ved_._state = ved_._state & ~CONNECTED;
      break;
      }
 
    (@funcs[string (retval)]) (ved_._fd);
    }
}

private define init_ved (fn, exists)
{
  ved_ = @Ved_Type;
  ved_._fname = fn;
  ved_._state = 0;
  ved_._exists = exists;
  ved_._count = qualifier ("count");
  ved_._func = qualifier ("func");
  ved_._tmpdir = qualifier ("tmpdir", "/tmp");
  ved_._drawonly = qualifier_exists ("drawonly");
}

private define init_sockaddr (fn)
{
  return sprintf ("/tmp/ved_%s_%d.sock",
    path_basename_sans_extname (fn), _time);
}

private define _ved_ ()
{
  variable issudo = ();
  variable file;
  variable args = __pop_list (_NARGS - 1);
  variable exists = parse_args (__push_list (args), &file, issudo;;__qualifiers ());

  if (-1 == exists)
    return;

  init_ved (file, exists;;__qualifiers ());

  ved_._issudo = issudo;
 
  ved_._sockaddr = init_sockaddr (file);

  ved_.p_ = doproc ();
 
  if (NULL == ved_.p_)
    return;

  connect_to_child ();

  ved_exit ();
}

define ved ()
{
  variable args = __pop_list (_NARGS);
  _ved_ (__push_list (args), 0;;__qualifiers ());

%  if (qualifier_exists ("drawwind"))
%    CW.drawwind ();
}

define vedsudo ()
{
  variable args = __pop_list (_NARGS);
  _ved_ (__push_list (args), 1;;__qualifiers ());
}

funcs[string (JUST_DRAW)] = &just_draw;
funcs[string (SEND_FILE)] = &send_file;
funcs[string (SEND_ROWS)] = &send_rows;
funcs[string (SEND_VED_INFOCLRBG)] = &send_infoclrbg;
funcs[string (SEND_VED_INFOCLRFG)] = &send_infoclrfg;
funcs[string (SEND_PROMPTCOLOR)] = &send_promptcolor;
funcs[string (SEND_FUNC)] = &send_func;
funcs[string (SEND_TMPDIR)] = &send_tmpdir;
