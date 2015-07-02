static define getloginname ()
{
  variable name;

  () = fputs ("login: ", stdout);
  () = fgets (&name, stdin);
  () = fflush (stdout);

  return strtrim_end (name);
}


static define login ()
{
  USER = getloginname ();

  (UID, GID) = setpwuidgid (USER, 1);

  GROUP = setgrname (GID, 1);

  variable passwd = getpasswd ();

  if (-1 == authenticate (USER, passwd))
    {
    tostderr ("authentication error");
    exit_me (1);
    }
  
  return encryptpasswd (passwd);
}

