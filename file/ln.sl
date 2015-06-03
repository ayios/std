loadfrom ("file", "copyfile", NULL, &on_eval_err);

define ln (source, dest, opts)
{
  variable
    tmp,
    retval,
    backupdest,
    st_source = stat_file (source),
    st_dest = lstat_file (dest);

  if (NULL == st_source)
    {
    st_source = stat_file (path_concat (path_dirname (dest), source));
    if (NULL == st_source)
      {
      tostderr (sprintf ("accessing `%s': No such file or directory", source));
      return -1;
      }
    }

  if ((source == dest)
     || ((st_dest != NULL)
     && (st_source.st_ino == st_dest.st_ino &&
       NULL == opts.nodereference && NULL == opts.force)
     && (st_source.st_dev == st_dest.st_dev &&
       NULL == opts.nodereference && NULL == opts.force)))
    {
    tostderr (sprintf ("`%s' and `%s' are the same file", source, dest));
    return -1;
    }

  if (NULL == opts.symbolic && stat_is ("dir", st_source.st_mode))
    {
    tostderr (sprintf ("`%s': hard link not allowed for directory", dest));
    return -1;
    }

  if (NULL != st_dest && stat_is ("dir", st_dest.st_mode))
    ifnot (stat_is ("lnk", st_dest.st_mode))
      {
      dest = path_concat (dest, path_basename (source));
      st_dest = lstat_file (dest);
      }

  if (NULL != st_dest && stat_is ("dir", st_dest.st_mode) && NULL == opts.nodereference)
    {
    tostderr (sprintf ("`%s': cannot overwrite directory", source));
    return -1;
    }

  if (NULL != st_dest)
    {
    if (opts.interactive)
      {
      retval = ask ([sprintf ("replace `%s'?", dest),
        "y[es remove]", "n[o abort]"],
        ['y', 'n']);

      if ('n' == retval)
        {
        tostdout (sprintf ("Not confirmed, to remove %s, aborting ...", dest));
        return 0;
        }

      opts.force = 1;
      }

    if (opts.backup || opts.force)
      {
      backupdest = strcat (dest, opts.suffix);
      if (stat_is ("lnk", st_dest.st_mode))
        {
        variable
          value = readlink (dest),
          st_backup = stat_file (backupdest);

        if (NULL != st_backup)
          if (-1 == remove (backupdest))
            {
            tostderr (sprintf
              ("%s: backup file exists, and can not be removed", backupdest));
            return -1;
            }

        if (-1 == symlink (value, backupdest))
          {
          tostderr (sprintf ("creating backup symbolic link failed `%s', ERRNO: %s",
             dest, errno_string (errno)));
          return -1;
          }

        st_backup = stat_file (backupdest);
        }
      else if (stat_is ("reg", st_dest.st_mode))
        {
        retval = copyfile (dest, backupdest);
        if (-1 == retval)
          return -1;

        st_backup = lstat_file (backupdest);
        }
      else
        {
        tostderr ("Operation is not permitted, dest is not neither a link or a regular file");
        return -1;
        }

      ifnot (access (source, X_OK))
        () = chmod (backupdest, 0755);
      }

    if (opts.force)
      {
      retval = remove (dest);
      if (-1 == retval)
        {
        tostderr (sprintf ("%s: destination cannot be removed", dest));
        return -1;
        }
      }
    }

  if (NULL != st_dest)
    {
    tmp = stat_file (dest);
    if (NULL != tmp)
      if (stat_is ("dir", tmp.st_mode))
        if (opts.nodereference && (opts.force || opts.backup))
          if (-1 == remove (dest))
            {
            if (__is_initialized (&backupdest))
              () = remove (backupdest);

            tostderr (sprintf ("%s: cannot be removed", dest));
            return -1;
            }
    }

  if (opts.symbolic)
    retval = symlink (source, dest);
  else
    retval = hardlink (source, dest);
 
  if (-1 == retval)
    tostderr (sprintf ("creating %s failed `%s', ERRNO: %s", opts.symbolic
        ? "symbolic link" : "hardlink", dest, errno_string (errno)));
  else
    tostdout (sprintf ("`%s' %s `%s'%s", dest, opts.symbolic ? "->" : "=>",
        source, opts.backup  ? sprintf (" (backup: `%s')", backupdest) : ""));

  if (-1 == retval)
    {
    if (NULL != opts.force && __is_initialized (&backupdest))
      {
      tmp = stat_file (dest);
      if (stat_is ("lnk", st_backup.st_mode))
        () = symlink (value, dest);
      else
        () = copyfile (backupdest, dest);
      }
    }

  if (opts.force && NULL == opts.backup && __is_initialized (&backupdest))
    ()= remove (backupdest);

  return retval;
}
