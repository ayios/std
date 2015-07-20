variable SOCKET;
variable SOCKADDR   = getenv ("SOCKADDR");
variable GO_ATEXIT  = 0x0C8;
variable GO_IDLED   = 0x012c;
variable RECONNECT  = 0x0190;

define go_idled ()
{
  send_int (SOCKET, GO_IDLED);

  variable retval = get_int (SOCKET);
  
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
