define getpwname (uid, exit_on_err)
{
  variable fp = fopen ("/etc/passwd", "r");

  if (NULL == fp)
    {
    tostderr ("/etc/passwd is not readable, this shouldn't be happen");
    
    if (exit_on_err)
      exit (1);
    }

  variable buf = NULL;
  variable rec;

  while (-1 != fgets (&buf, fp))
    {
    rec = strchop (buf, ':', 0);
    if (string (uid) == rec[2])
      return rec[0];
    }

  tostderr ("cannot find your UID " + string (uid) + " in /etc/passwd, who are you?");
  
  if (exit_on_err)
    exit (1);
}

define getpwuid (name, exit_on_err)
{
  variable fp =fopen ("/etc/passwd", "r");

  if (NULL == fp)
    {
    tostderr ("/etc/passwd is not readable, this shouldn't be happen");
    
    if (exit_on_err)
      exit (1);
    }

  variable buf = NULL;
  variable rec;

  while (-1 != fgets (&buf, fp))
    {
    rec = strchop (buf, ':', 0);
    if (name == rec[0])
      return atoi (rec[2]);
    }

  tostderr ("cannot find your username " + name + " in /etc/passwd, who are you?");
  
  if (exit_on_err)
    exit (1);
}
