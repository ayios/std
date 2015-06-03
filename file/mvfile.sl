loadfrom ("file", "copyfile", NULL, &on_eval_err);

define mvfile (source, dest, opts)
{
  variable
    backup,
    retval,
    backuptext = "",
    st_dest = stat_file (dest);

%TODO CHMOD
  if (NULL != st_dest && opts.backup)
    {
    backup = strcat (dest, opts.suffix);
    retval = copyfile (dest, backup);
    if (-1 == retval)
      {
      tostderr (sprintf ("%s: backup failed", backup));
      return -1;
      }

    backuptext = sprintf (" (backup: %s)", backup);
    }
  
  if (NULL != st_dest && opts.interactive)
    {
    retval = ask ([
      sprintf ("overwrite %s ?", dest),
      "y[es overwrite]",
      "n[o do not overwrite]",
      ],
      ['y',  'n']);
    
    switch (retval)
      {
      case 'q':
        return 0;
      }

      {
      case 'n':
        return 0;
      }
    }

  retval = rename (source, dest);

  if (-1 == retval)
    {
    if ("Cross-device link" == errno_string (errno))
      {
      retval = copyfile (source, dest);
      if (-1 == retval)
        {
        tostderr (sprintf
          ("%s: failed to mv to %s, Couldn't bypass the Cross-device link", source, dest));
        return -1;
        }

      if (-1 == remove (source))
        {
        () = remove (dest);
        tostderr (sprintf
          ("%s: failed to mv to %s, ERRNO: %s", source, dest, errno_string (errno)));
        return -1;
        }
      }
    else
      {
      tostderr (sprintf (
        "Failed to move %s to %s, ERRNO: %s", source, dest, errno_string (errno)));
      return -1;
      }
    }

  tostdout (sprintf ("`%s' -> `%s'%s", source, dest, backuptext));
  return 0;
}
