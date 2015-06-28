typedef struct
  {
  _fname,
  _sockaddr,
  _fd,
  _state,
  _func,
  _count,
  _drawonly,
  _slshbin,
  p_,
  } Ved_Type;

private variable VEDFD = NULL;
private variable VEDSTATE = 0;

private variable funcs = Assoc_Type[Ref_Type];

private variable
  CONNECTED = 0x1,
  IDLED = 0x2,
  JUST_DRAW = 0x064,
  GOTO_EXIT = 0x0C8,
  GO_IDLED =  0x12c,
  SEND_FILE = 0x0190,
  SEND_FUNC = 0x01f4;

private define ved_exit (v)
{
  ifnot (v._state & IDLED)
    {
    variable status = waitpid (v.p_.pid, 0);
    v.p_.atexit ();

    () = close (v._fd);
    return 0;
    }
  
  VEDSTATE = VEDSTATE | IDLED;

  return 1;
}

private define send_func (sock, v)
{
  sock->send_int (sock, NULL == v._func ? 0 : v._func);

  ifnot (NULL == v._func)
    {
    () = sock->get_int (sock);
    sock->send_int (sock, NULL == v._count ? 0 : 1);

    ifnot (NULL == v._count)
      {
      () = sock->get_int (sock);
      sock->send_int (sock, v._count);
      }
    }
}

private define just_draw (sock, v)
{
  sock->send_int (sock, v._drawonly);
}

private define send_file (sock, v)
{
  sock->send_str (sock, v._fname);
}

private define addflags (p)
{
  p.stderr.file = TEMPDIR + "/" + string (getpid) + "SRVvederr.txt";
  p.stderr.wr_flags = ">|";
}

private define getargvenv (p, v)
{
  variable
    argv = [SLSH_BIN, p.loadfile, path_dirname (__FILE__) + "/proc", v._fname],
    env = [proc->defenv (), sprintf ("VED_SOCKADDR=%s", v._sockaddr)];

  ifnot (NULL == DISPLAY)
    env = [env, "DISPLAY=" + DISPLAY];

  ifnot (NULL == XAUTHORITY)
    env = [env, "XAUTHORITY=" + XAUTHORITY];
 
  return argv, env;
}

private define doproc (v)
{
  variable p, argv, env;

  if (p = proc->init (0, 0, 1), p == NULL)
    return NULL;

  addflags (p);

  (argv, env) = getargvenv (p, v);

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

private define is_file_readable (fn)
{
  if (-1 == access (fn, R_OK))
    {
    () = fprintf (stderr, "%s: is not readable", fn);
    return -1;
    }

  return 0;
}

private define check_file (fn)
{
  ifnot (access (fn, F_OK))
    {
    if (-1 == is_file (fn))
      return -1;
 
    if (-1 == is_file_readable (fn))
      return -1;

    return 1;
    }

  return 0;
}

private define parse_args ()
{
  variable fname;

  if (1 == _NARGS)
    {
    fname = ();
    @fname = TEMPDIR + "/" + string (getpid ()) + "scratch.txt";
    }
  else
    {
    fname = ();
    @fname = ();
    }
 
  variable exists = check_file (@fname);

  if (-1 == exists)
    return -1;

  return exists;
}

private define vedloop (v)
{
  variable retval;

  forever
    {
    retval = sock->get_int (v._fd);
 
    ifnot (Integer_Type == typeof (retval))
      return;

    if (retval == GOTO_EXIT)
      {
      v._state = v._state & ~CONNECTED;
      return;
      }

    if (retval == GO_IDLED)
      {
      v._state = v._state | IDLED;
      return;
      }
 
    (@funcs[string (retval)]) (v._fd, v);
    }
}

private define connect_to_child (v)
{
  ifnot (VEDSTATE & CONNECTED)
    {
    v._fd = v.p_.connect (v._sockaddr);
 
    if (NULL == v._fd)
      {
      () = kill (v.p_.pid, SIGALRM);
      variable status = waitpid (v.p_.pid, 0);
      v.p_.atexit ();
      return -1;
      }
    }
  
  if (NULL == VEDFD) 
    VEDFD = v._fd;

  v._state = v._state | CONNECTED;
 
  ifnot (VEDSTATE)
    VEDSTATE = VEDSTATE | CONNECTED;

  return 0;
}

private define init_ved (fn)
{
  variable v;
  v = @Ved_Type;
  v._fname = fn;
  v._state = 0;
  v._count = qualifier ("count");
  v._func = qualifier ("func");
  v._drawonly = qualifier_exists ("drawonly");
  return v;
}

private define init_sockaddr (fn)
{
  return sprintf (TEMPDIR + "/" + string (getpid ()) + "ved_%s.sock",
    path_basename_sans_extname (fn));
}

define ved ()
{
  variable file;
  variable args = __pop_list (_NARGS);
  variable exists = parse_args (__push_list (args), &file;;__qualifiers ());

  if (-1 == exists)
    return -1;

  variable v = init_ved (file;;__qualifiers ());

  v._sockaddr = init_sockaddr (file);

  v.p_ = doproc (v);
 
  if (NULL == v.p_)
    return -1;
 
  if (-1 == connect_to_child (v))
    return -1;

  vedloop (v);

  return ved_exit (v);
}

funcs[string (JUST_DRAW)] = &just_draw;
funcs[string (SEND_FILE)] = &send_file;
funcs[string (SEND_FUNC)] = &send_func;
