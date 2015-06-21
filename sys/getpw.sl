define getgrname (gid, exit_on_err)
{
  variable fp = fopen ("/etc/group", "r");

  if (NULL == fp)
    {
    tostderr ("/etc/group is not readable, this shouldn't be happen");
 
    if (exit_on_err)
      exit (1);
 
    return NULL;
    }

  variable buf = NULL;
  variable rec;

  while (-1 != fgets (&buf, fp))
    {
    rec = strchop (buf, ':', 0);

    ifnot (length (rec) == 4)
      {
      tostderr ("wrong entry fields in /etc/group");

      if (exit_on_err)
        exit (1);

      return NULL;
      }

    if (string (gid) == rec[2])
      return rec[0];
    }

  tostderr ("cannot find your GID " + string (gid) + " in /etc/group, who are you?");
 
  if (exit_on_err)
    exit (1);

  return NULL;
}

define getpwname (uid, exit_on_err)
{
  variable fp = fopen ("/etc/passwd", "r");

  if (NULL == fp)
    {
    tostderr ("/etc/passwd is not readable, this shouldn't be happen");
 
    if (exit_on_err)
      exit (1);
 
    return NULL;
    }

  variable buf = NULL;
  variable rec;

  while (-1 != fgets (&buf, fp))
    {
    rec = strchop (buf, ':', 0);

    ifnot (length (rec) == 7)
      {
      tostderr ("wrong entry fields in /etc/passwd");

      if (exit_on_err)
        exit (1);

      return NULL;
      }

    if (string (uid) == rec[2])
      return rec[0];
    }

  tostderr ("cannot find your UID " + string (uid) + " in /etc/passwd, who are you?");
 
  if (exit_on_err)
    exit (1);

  return NULL;
}

define getpwuidgid (name, exit_on_err)
{
  variable fp = fopen ("/etc/passwd", "r");

  if (NULL == fp)
    {
    tostderr ("/etc/passwd is not readable, this shouldn't be happen");
 
    if (exit_on_err)
      exit (1);

    return NULL, NULL;
    }

  variable buf, rec, uid, gid;

  while (-1 != fgets (&buf, fp))
    {
    rec = strchop (buf, ':', 0);

    ifnot (length (rec) == 7)
      {
      tostderr ("wrong entry fields in /etc/passwd");

      if (exit_on_err)
        exit (1);

      return NULL, NULL;
      }
 
    if (name == rec[0])
      {
      try
        {
        uid = integer (rec[2]);
        gid = integer (rec[3]);
        }
      catch SyntaxError:
        {
        tostderr ("uid|gid field is not an integer");
        if (exit_on_err)
          exit (1);

        return NULL, NULL;
        }

      return uid, gid;;
      }
    }

  tostderr ("cannot find your username " + name + " in /etc/passwd, who are you?");
 
  if (exit_on_err)
    exit (1);
 
  return NULL, NULL;
}
