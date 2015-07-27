private variable OSAPPSFILE = TEMPDIR + "/" + string (OSPPID) + "_apps.txt";
private variable COAPPSFILE = TEMPDIR + "/" + string (OSPPID) + "_conn_apps.txt";

define _osappnew_ (s)
{
  variable apps = readfile (OSAPPSFILE);
 
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
  variable apps = readfile (COAPPSFILE);
 
  rline->set (s);
  rline->prompt (s, s._lin, s._col);

  () = rline->commandcmp (s, apps);
    if (any (apps == s.argv[0]))
      {
      variable app = strtok (s.argv[0], "::");
      if (app[0] != APP.appname || app[1] != string (PID))
        con_to_oth (s.argv[0], APP_RECON_OTH);
      }

  rline->set (s);
  rline->prompt (s, s._lin, s._col);
}

