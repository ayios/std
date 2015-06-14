typedef struct
  {
  _sockaddr,
  _fd,
  _state,
  _issudo,
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
  shell_.p_.atexit ();

  () = close (shell_._fd);
  __uninitialize (&shell_);
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
    env = [proc->getdefenv (), sprintf ("SHELL_SOCKADDR=%s", shell_._sockaddr),
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
    return;
    }
 
  shell_._state = shell_._state | CONNECTED;

  variable retval;

  forever
    {
    retval = sock->get_int (shell_._fd);
 
    ifnot (Integer_Type == typeof (retval))
      break;

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

private define _shell_ ()
{
  variable issudo = ();

  init_shell ();

  shell_._issudo = issudo;
 
  shell_._sockaddr = init_sockaddr ();

  shell_.p_ = doproc ();
 
  if (NULL == shell_.p_)
    return;

  connect_to_child ();

  shell_exit ();
}

define shell ()
{
  variable args = __pop_list (_NARGS);
  _shell_ (__push_list (args), 0;;__qualifiers ());
}
