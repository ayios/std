define con_to_oth (app, what)
{
  smg->suspend ();
  input->at_exit ();
  sock->send_int (SOCKET, what);
  () = sock->get_int (SOCKET);
  sock->send_str (SOCKET, app);

  variable retval = sock->get_int (SOCKET);
  if (RECONNECT == retval)
    smg->resume ();
  else
    (@__get_reference ("_exit_")) (;;__qualifiers  ());
}

define go_idled ()
{
  sock->send_int (SOCKET, GO_IDLED);

  variable retval = sock->get_int (SOCKET);

  if (RECONNECT == retval)
    return 0;

  return 1;
}

$1 = open (TEMPDIR + "/_" + APP.appname + "_.init", O_WRONLY|O_CREAT, S_IRWXU);

$1 = socket (PF_UNIX, SOCK_STREAM, 0);
bind ($1, SOCKADDR);
listen ($1, 1);
SOCKET = accept (__tmp ($1));

() = remove (TEMPDIR + "/_" + APP.appname + "_.init");
