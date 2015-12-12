define _osappnew_ (s)
{
  Sock.send_int (SOCKET, APP_GET_ALL);
  variable apps = Sock.get_str (SOCKET);
  apps = strchop (apps, '\n', 0);

  rline->set (s);
  rline->prompt (s, s._lin, s._col);

  () = rline->commandcmp (s, apps);

  if (any (apps == s.argv[0]))
    con_to_oth (s.argv[0], APP_CON_NEW);

  rline->set (s);
  rline->prompt (s, s._lin, s._col);
}

define _osapprec_ (s)
{
  Sock.send_int (SOCKET, APP_GET_CONNECTED);

  variable apps = Sock.get_str (SOCKET);
  variable me = APP.appname + "::" + string (Env.vget ("PID"));
  apps = strchop (strtrim_end (apps), '\n', 0);
  apps = apps[wherenot (me == apps)];

  rline->set (s);
  rline->prompt (s, s._lin, s._col);

  () = rline->commandcmp (s, apps);

  if (any (apps == s.argv[0]))
    ifnot (me == s.argv[0])
      con_to_oth (s.argv[0], APP_RECON_OTH);

  rline->set (s);
  rline->prompt (s, s._lin, s._col);
}
