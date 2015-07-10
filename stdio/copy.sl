loadfrom ("file", "copyfile", NULL, &on_eval_err);
loadfrom ("sys", "modetoint", NULL, &on_eval_err);
define clean (force, backup, backupfile, dest)
{
  if (force)
    {
    ifnot (NULL == backupfile)
      if (NULL == backup)
        () = rename (backupfile, dest);
      else
        () = copyfile (backupfile, dest);
    }
  else
    ifnot (NULL == backup)
      ifnot (NULL == backupfile)
        () = remove (backupfile);
}

define copy (source, dest, st_source, st_dest, opts)
{
  variable
    msg,
    link,
    mode,
    retval,
    force = NULL,
    backuptext = "",
    backup = NULL;

  ifnot (NULL == st_dest)
    {
    if (opts.noclobber)
      {
      tostderr (dest + ": Cannot overwrite existing file; noclobber option is given");
      return 0;
      }

    if (opts.update && st_source.st_mtime <= st_dest.st_mtime)
      {
      tostdout ("`" + dest + "' is newer than `" + source + "', aborting ...");
      return 0;
      }
 
    % TODO QUIT
    if (opts.interactive)
      {
      retval = ask
        ([sprintf ("cp: overwrite `%s'?", dest), "y[es]/n[o]/q[uit] or escape to abort"],
        ['y', 'n', 'q']);

      if (any (['n', 033, 'q'] == retval))
        {
        tostdout (source + " aborting ...");
        return 0;
        }
      }

    if (opts.backup)
      ifnot (any ([istype (st_source.st_mode, "fifo"), istype (st_source.st_mode, "blk"),
          istype (st_source.st_mode, "chr"), istype (st_source.st_mode, "sock")]))
        {
        backup = sprintf ("%s%s", dest, opts.suffix);

        if (-1 == copyfile (dest, backup))
          {
          tostderr ("cannot backup, " + dest);
          return -1;
          }

        ifnot (access (dest, X_OK))
          () = chmod (backup, 0755);

        backuptext = sprintf ("(backup: `%s')", backup);
        }

    ifnot (st_dest.st_mode & S_IWUSR)
      if (NULL == opts.force)
        {
        tostderr (dest + ": is not writable, try --force");
        return 0;
        }
      else
        ifnot (any ([istype (st_source.st_mode, "fifo"), istype (st_source.st_mode, "blk"),
            istype (st_source.st_mode, "chr"), istype (st_source.st_mode, "sock")]))
          {
          if (NULL == opts.backup)
            {
            backup = sprintf ("%s%s", dest, opts.suffix);

            if (-1 == copyfile (dest, backup))
              {
              tostderr ("cannot backup, %s" + dest);
              return -1;
              }

            ifnot (access (dest, X_OK))
              () = chmod (backup, 0755);
            }

          if (-1 == remove (dest))
            {
            tostderr (dest + ": couldn't be removed");
            return -1;
            }

          force = 1;
          }
    }

  if (stat_is ("lnk", st_source.st_mode))
    {
    link = readlink (source);
    if (NULL == stat_file (source))
      {
      tostderr ("source `" + source + "' points to the non existing file `" + link +
          "', aborting ...");
 
      clean (force, opts.backup, backup, dest);
 
      return -1;
      }
    else if (NULL == opts.nodereference)
      if (-1 == symlink (link, dest))
        {
        clean (force, opts.backup, backup, dest);

        return -1;
        }
    }
  else if (any ([istype (st_source.st_mode, "fifo"), istype (st_source.st_mode, "blk"),
      istype (st_source.st_mode, "chr"), istype (st_source.st_mode, "sock")]))
    {
    tostdout ("cannot copy special file `" + source + "': Operation not permitted");

    clean (force, opts.backup, backup, dest);
 
    return 0;
    }
  else
    {
    if (-1 == copyfile (source, dest))
      {
      clean (force, opts.backup, backup, dest);

      return -1;
      }
    }

  if (force && NULL != opts.backup)
    () = remove (backup);

  ifnot (NULL == opts.permissions)
    () = lchown (dest, st_source.st_uid, st_source.st_gid);

  mode = modetoint (st_source.st_mode);

  () = chmod (dest, mode);

  tostdout (sprintf ("`%s' -> `%s' %s", source, dest, backuptext));

  return 0;
}
