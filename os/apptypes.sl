typedef struct
  {
  _sockaddr,
  _fd,
  _state,
  atexit,
  p_,
  uid,
  gid,
  _procfile,
  _appname,
  _appdir,
  argv,
  }App_Type;

typedef struct
  {
  init,
  help,
  info,
  }AppInfo_Type;

variable Setid_Type = struct
    {
    setid = 1,
    uid = UID,
    gid = GID,
    user = USER
    };
