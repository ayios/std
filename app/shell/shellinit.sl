typedef struct
  {
  _sockaddr,
  _fd,
  _state,
  p_,
  } Shell_Type;

private variable shell_;

private variable
  CONNECTED = 0x1,
  IDLED = 0x2,
  GOTO_EXIT = 0x0C8;

private define shell_exit ()
{
  variable status = waitpid (shell_.p_.pid, 0);
  _log_ ("shell exit_status: " + string (status.exit_status), LOGNORM);

  shell_.p_.atexit ();

  () = close (shell_._fd);
  __uninitialize (&shell_);
  return status.exit_status;
}

private define addflags (p)
{
  p.stderr.file = TEMPDIR + "/" + string (PID) + "ServerShellErr";
  p.stderr.wr_flags = ">|";
}

private define getargvenv (p)
{
  variable
    argv = [SLSH_BIN, p.loadfile, path_dirname (__FILE__) + "/proc"],
    env = [proc->defenv (), sprintf ("SHELL_SOCKADDR=%s", shell_._sockaddr),
      ];

  return argv, env;
}

private define doproc ()
{
  variable p, argv, env;

  if (p = proc->init (0, 0, 1), p == NULL)
    return NULL;

  addflags (p);

  (argv, env) = getargvenv (p);

  if (NULL == p.execve (argv, env, 1))
    return NULL;

  return p;
}

private define connect_to_child ()
{
  shell_._fd = shell_.p_.connect (shell_._sockaddr);

  if (NULL == shell_._fd)
    {
    shell_.p_.atexit ();
    () = kill (shell_.p_.pid, SIGKILL);
    _log_ ("shell: failed to connect to socket", LOGERR);
    return;
    }
 
  shell_._state = shell_._state | CONNECTED;
  
  _log_ ("shell: connected to socket", LOGNORM);

  variable retval;

  forever
    {
    retval = sock->get_int (shell_._fd);
 
    ifnot (Integer_Type == typeof (retval))
      {
      _log_ ("shell loop: expected Integer_Type, received " + string (typeof (retval)), LOGERR);
      break;
      }

    if (retval == GOTO_EXIT)
      {
      shell_._state = shell_._state & ~CONNECTED;
      break;
      }
    }
}

private define init_shell ()
{
  shell_ = @Shell_Type;
  shell_._state = 0;
}

private define init_sockaddr ()
{
  return sprintf (TEMPDIR + "/" + string (PID) + "shell.sock");
}

define shell ()
{
  _log_ ("running shell", LOGALL);

  init_shell ();

  shell_._sockaddr = init_sockaddr ();
  
  _log_ ("sockaddress: " + shell_._sockaddr, LOGALL);

  shell_.p_ = doproc ();
 
  if (NULL == shell_.p_)
    {
    _log_ ("shell: fork failed", LOGERR);
    return;
    }
  
  _log_ ("shell pid: " + string (shell_.p_.pid), LOGNORM);

  connect_to_child ();

  return shell_exit ();
}
