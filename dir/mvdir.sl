load.from ("dir", "fswalk", NULL;err_handler = &__err_handler__);
load.from ("dir", "cprecursive", NULL;err_handler = &__err_handler__);
load.from ("dir", "cprecursive_opts", NULL;err_handler = &__err_handler__);

private define file_callback (file, st, filelist)
{
  list_append (filelist, file);
  return 1;
}

private define dir_callback (dir, st, dirlist)
{
  list_append (dirlist, dir);
  return 1;
}

define mvdir (source, dest, opts)
{
  variable
    i,
    st,
    ar,
    files,
    retval,
    backup,
    fswalk,
    backuptext = "",
    sourcedirs = {},
    sourcefiles = {},
    st_dest = stat_file (dest);

  fswalk = fswalk_new (&dir_callback, &file_callback;
      dargs = {sourcedirs}, fargs = {sourcefiles});

  fswalk.walk (source);
 
  if (NULL != st_dest && opts.backup)
    {
    backup = sprintf ("%s%s", dest, opts.suffix);
    files = listdir (backup);
    if (NULL != files || length (files))
      {
      IO.tostderr (sprintf ("cannot backup `%s': Directory not empty", backup));
      return -1;
      }
 
    opts.backup = NULL;
    retval = cprecursive (dest, backup, opts);
    opts.backup = 1;

    if (-1 == retval)
      {
      IO.tostderr (sprintf ("%s: backup failed", backup));
      return -1;
      }

    backuptext = sprintf (" (backup: `%s')", backup);
    }
 
  variable keep_backup_opt = opts.backup;
  opts.backup = NULL;
  retval = cprecursive (source, dest, opts);
  opts.backup = keep_backup_opt;

  if (-1 == retval)
    return -1;

  sourcefiles = length (sourcefiles) ? list_to_array (sourcefiles) : String_Type[0];
  _for i (0, length (sourcefiles) - 1)
    if (-1 == remove (sourcefiles[i]))
      {
      IO.tostderr (sprintf ("%s: failed to remove file", sourcefiles[i]));
      return -1;
      }

  sourcedirs = list_to_array (sourcedirs);
  sourcedirs = sourcedirs[array_sort (sourcedirs;dir=-1)];
  _for i (0, length (sourcedirs) - 1)
    if (-1 == rmdir (sourcedirs[i]))
      {
      IO.tostderr (sprintf ("%s: failed to remove dir", sourcedirs[i]));
      return -1;
      }

  IO.tostderr (sprintf ("`%s' -> `%s'%s", source, dest, backuptext));
  return 0;
}
