typedef struct
  {
  pid,
  argv,
  uid,
  gid,
  user,
  setid,
  issu,
  stdin,
  stdout,
  stderr,
  execv,
  execve,
  atexit,
  connect,
  loadproc,
  loadcommand,
  } Proc_Type;

typedef struct
  {
  in,
  out,
  file,
  mode,
  keep,
  read,
  write,
  wr_flags,
  append_flags,
  } Descr_Type;

private define parse_flags (fd)
{
  ifnot (NULL == fd.wr_flags)
    {
    ifnot (assoc_key_exists (FILE_FLAGS, fd.wr_flags))
      fd.wr_flags = FILE_FLAGS[">"];
    else
      fd.wr_flags = FILE_FLAGS[fd.wr_flags];
    }
  else
    if (-1 == access (fd.file, F_OK))
      fd.wr_flags = FILE_FLAGS[">"];
    else
      fd.wr_flags = FILE_FLAGS[">|"];
 
  ifnot (NULL == fd.append_flags)
    fd.wr_flags |= fd.append_flags;

  if (fd.wr_flags & O_CREAT)
    if (NULL == fd.mode)
      fd.mode = PERM["_PRIVATE"];
}

private define open_file (fd, fp)
{
  fd.keep = dup_fd (fileno (fp));
 
  parse_flags (fd);
 
  ifnot (NULL == fd.mode)
    fd.write = open (fd.file, fd.wr_flags, fd.mode);
  else
    fd.write = open (fd.file, fd.wr_flags);

  () = dup2_fd (fd.write, _fileno (fp));
}

private define close_fd (fd, fp)
{
  () = _close (_fileno (fd.write));
  () = dup2_fd (fd.keep, _fileno (fp));
}

private define open_fd (fd, fp)
{
  fd.keep = dup_fd (fileno (fp));

  (fd.read, fd.write) = pipe ();

  () = dup2_fd (fd.write, _fileno (fp));
}

private define _openforread (fd, fp)
{
  fd.keep = dup_fd (fileno (fp));
 
  ifnot (NULL == fd.file)
    {
    fd.read = open (fd.file, O_RDONLY);
    () = dup2_fd (fd.read, _fileno (fp));
    return;
    }

  (fd.read, fd.write) = pipe ();

  () = write (fd.write, fd.in);

  () = close (fd.write);
 
  () = dup2_fd (fd.read, _fileno (fp));
}

private define _open (fd, fp)
{
  ifnot (NULL == fd.file)
    open_file (fd, fp);
  else
    open_fd (fd, fp);
}

private define atexit (s)
{
  ifnot (NULL == s.stdout)
    {
    close_fd (s.stdout, stdout);

    if (NULL == s.stdout.file)
      s.stdout.out = read_fd (s.stdout.read);
    }

  ifnot (NULL == s.stderr)
    {
    close_fd (s.stderr, stderr);

    if (NULL == s.stderr.file)
      s.stderr.out = read_fd (s.stderr.read);
    }
 
  ifnot (NULL == s.stdin)
    if (NULL == s.stdin.file)
      close_fd (s.stdin, stdin);
    else
      () = dup2_fd (s.stdin.keep, 0);
}

private define connect_to_socket (s, sockaddr)
{
  variable
    i = -1,
    sock = socket (PF_UNIX, SOCK_STREAM, 0);
 
  forever
    {
    i++;
    if (5000 < i)
      return NULL;

    try
      connect (sock, sockaddr);
    catch AnyError:
      continue;

    break;
    }
 
  return sock;
}

private define dopid (s)
{
  ifnot (NULL == s.stdin)
    _openforread (s.stdin, stdin);

  ifnot (NULL == s.stdout)
    _open (s.stdout, stdout);

  ifnot (NULL == s.stderr)
    _open (s.stderr, stderr);

  return fork ();
}

private define _execv (s, argv, bg)
{
  variable status = 0;

  s.pid = dopid (s);

  ifnot (s.pid)
    {
    if (NULL != s.setid)
      if (NULL != s.uid && NULL != s.gid && NULL != s.user)
        {
        if (-1 == initgroups (s.user, s.gid))
          {
          tostderr ("initgroups: " + errno_string (errno));
          return NULL;
          }

        if (-1 == setgid (s.gid))
          {
          tostderr ("setgid: " + errno_string (errno));
          return NULL;
          }

        if (-1 == setuid (s.uid))
          {
          tostderr ("setuid: " + errno_string (errno));
          return NULL;
          }
        }
    
    if (-1 == execv (argv[0], argv))
      return NULL;
    }
 
  if (NULL == bg)
    {
    status = waitpid (s.pid, 0);
    s.atexit ();
    return status;
    }

  return s.pid;
}

private define _execve (s, argv, env, bg)
{
  variable status = 0;

  s.pid = dopid (s);

  ifnot (s.pid)
    {
    if (NULL != s.setid)
      if (NULL != s.uid && NULL != s.gid && NULL != s.user)
        {
        if (-1 == initgroups (s.user, s.gid))
          {
          tostderr ("initgroups: " + errno_string (errno));
          return NULL;
          }

        if (-1 == setgid (s.gid))
          {
          tostderr ("setgid: " + errno_string (errno));
          return NULL;
          }

        if (-1 == setuid (s.uid))
          {
          tostderr ("setuid: " + errno_string (errno));
          return NULL;
          }
        }

    if (-1 == execve (argv[0], argv, env))
      return NULL;
    }

  if (NULL == bg)
    {
    status = waitpid (s.pid, 0);
    s.atexit ();
    return status;
    }

  return s.pid;
}

private define loadproc ()
{
  return path_dirname (__FILE__) + "/loadproc.sl";
}

private define loadcommand ()
{
  return path_dirname (__FILE__) + "/loadcommand.sl";
}

define init (in, out, err)
{
  variable
    p = @Proc_Type;

  if (in)
    p.stdin = @Descr_Type;

  if (out)
    p.stdout = @Descr_Type;

  if (err)
    p.stderr = @Descr_Type;

  p.atexit = &atexit;
  p.connect = &connect_to_socket;
  p.loadproc = loadproc ();
  p.loadcommand = loadcommand ();
  p.execve = &_execve;
  p.execv = &_execv;
  p.setid = qualifier ("setid");
  p.uid = qualifier ("uid");
  p.gid = qualifier ("gid");
  p.user = qualifier ("user");

  return p;
}
