loadfrom ("proc", "procInit", NULL, &on_eval_err);

private define untar (archive, file, verbose, tar)
{
  variable status;
  variable p = proc->init (0, 0, 0);
 
  status = p.execv ([tar, sprintf ("-x%sf", verbose ? "v" : ""), archive,
    "--strip-components=1"], NULL);

  () = remove (archive);

  return status.exit_status;
}

private define func_z (archive, verbose, type)
{
  variable
    status,
    tar = which ("tar"),
    exec = which (type == ".xz" ? "xz" : type == ".bz2" ? "bzip2" : "gzip");

  if (NULL == exec)
    {
    tostderr (sprintf ("%s executable couldn't be found in PATH",
      type == ".xz" ? "xz" : type == ".bz2" ? "bzip2" : "gzip"));
    return -1;
    }

  if (NULL == tar)
    {
    tostderr ("tar executable couldn't be found in PATH");
    return -1;
    }
 
   variable p = proc->init (0, 1, 0);
 
   p.stdout.file = "archive.tar";
   p.stdout.append_flags = O_BINARY;
 
   status = p.execv ([exec, "-dc", archive], NULL);

  if (status.exit_status)
    {
    tostderr (sprintf ("ERROR while extracting %s", archive));
    return -1;
    }

  return untar ("archive.tar", archive, verbose, tar);
}

private define func_unrar (archive, verbose, type)
{
  variable
    status,
    unrar = [which ("unrar")];

  if (NULL == unrar)
    {
    tostderr ("unrar executable couldn't be found in PATH");
    return -1;
    }

  unrar = [unrar, "e", "-y", sprintf ("-id%s", verbose ? "c" : "q"), archive];
 
  variable p = proc->init (0, 0, 0);
  status = p.execv (unrar, NULL);

  return status.exit_status;
}

private define func_unzip (archive, verbose, type)
{
  variable
    status,
    unzip = [which ("unzip")];

  if (NULL == unzip)
    {
    tostderr ("unzip executable couldn't be found in PATH");
    return -1;
    }

  unzip = [unzip, sprintf ("-%suo", verbose ? "" : "q"), archive];
 
  variable p = proc->init (0, 0, 0);

  status = p.execv (unzip, NULL);
 
  return status.exit_status;
}

define extract (archive, verbose, dir, strip)
{
  variable
    retval,
    method,
    newdir,
    type = path_extname (archive),
    methods = [&func_z, &func_z, &func_z, &func_z, &func_unzip, &func_unrar],
    bsname = path_basename_sans_extname (archive),
    saveddir = getcwd ();

  ifnot (saveddir == dir)
    if (-1 == chdir (dir))
      {
      tostderr (sprintf ("couldn't change directory to: %s", dir));
      return -1;
      }
 
  if (NULL == strip)
    {
    % it could be different than the actual name stored in archive
    if (1 < length (strchop (bsname, '-', 0)))
      {
      bsname = strchop (bsname, '-', 0);
      newdir = bsname[0];
      if (2 < length (strchop (strjoin (bsname[[1:]]), '.', 0)))
        newdir += sprintf ("-%s", strjoin (strchop (strjoin (bsname[[1:]]), '.', 0)[[0:1]], "."));
      }
    % easy fallback (I don't really care), this program is based on unix standards
    else
      {
      newdir = bsname;
      while (1 < length (strchop (newdir, '.', 0)))
        newdir = path_basename_sans_extname (newdir);
      }
 
    if (-1 == access (newdir, F_OK))
      if (-1 == mkdir (newdir))
        {
        tostderr (sprintf ("couldn't create directory: %s, errno: %s",
          newdir, errno_string (errno)));

        return -1;
        }

    () = chdir (newdir);
    }

  ifnot (any (type == [".xz", ".bz2", ".zip", ".gz", ".tgz", ".rar"]))
    {
    tostderr (sprintf ("%s: Unkown type", type));
    return -1;
    }
 
  method = methods[where (type == [".xz", ".gz", ".tgz", ".bz2", ".zip", ".rar"])[0]];
  retval = (@method) (archive, verbose, type);
 
  ifnot (saveddir == dir)
    () = chdir (saveddir);
 
  return retval;
}
