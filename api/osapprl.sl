define _osappnew_ (s)
{
  sock->send_int (SOCKET, APP_GET_ALL);
  variable apps = sock->get_str (SOCKET);
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
  sock->send_int (SOCKET, APP_GET_CONNECTED);
  variable apps = sock->get_str (SOCKET);
  apps = strchop (strtrim_end (apps), '\n', 0);
 
  rline->set (s);
  rline->prompt (s, s._lin, s._col);

  () = rline->commandcmp (s, apps);

  if (any (apps == s.argv[0]))
    {
    variable app = strtok (s.argv[0], "::");
    if (2 == length (app))
      if (app[0] != APP.appname || app[1] != string (PID))
        con_to_oth (s.argv[0], APP_RECON_OTH);
    }

  rline->set (s);
  rline->prompt (s, s._lin, s._col);
}

