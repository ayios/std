define _usage ()
{
  verboseon ();

  variable
    if_opt_err = _NARGS ? () : " ",
    helpfile = qualifier ("helpfile", sprintf ("%s/help.txt", COMDIR)),
    ar = _NARGS ? [if_opt_err] : String_Type[0];

  if (NULL == helpfile)
    {
    IO.tostderr ("No Help file available for " + com);

    ifnot (length (ar))
      exit_me (1);
    }

  ifnot (access (helpfile, F_OK))
    ar = [ar, IO.readfile (helpfile)];

  ifnot (length (ar))
    {
    IO.tostdout ("No Help file available for " + com);
    exit_me (1);
    }

  IO.tostdout (ar);

  exit_me (_NARGS);
}

define info ()
{
  verboseon ();

  variable
    info_ref = NULL,
    infofile = qualifier ("infofile", sprintf ("%s/desc.txt", COMDIR)),
    ar;

  if (NULL == infofile || -1 == access (infofile, F_OK))
    {
    IO.tostdout ("No Info file available for " + com);
    exit_me (0);
    }

  ar = IO.readfile (infofile);

  IO.tostdout (ar);

  exit_me (0);
}
