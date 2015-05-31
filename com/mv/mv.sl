loadfrom ("file", "mvfile", NULL, &on_eval_err);
loadfrom ("dir", "mvdir", NULL, &on_eval_err);  
loadfrom ("dir", "evaldir", NULL, &on_eval_err);

define assign_interactive_noclobber (interactive, noclobber, code)
{
  @interactive = code ? 1 : NULL;
  @noclobber = code ? NULL : 1;
}

define main ()
{
  variable
    opts = struct
      {
      nodereference,
      interactive,
      noclobber,
      backup,
      update,
      suffix = "~",
      permissions = 1,
      maxdepth = 1000,
      @opts_share_cprec_init (),
      },
    dest,
    source,
    st_source,
    destname,
    st_destname,
    st_dest,
    files,
    retval,
    exit_code = 0,
    i,
    c = cmdopt_new (&_usage);

  c.add ("backup", &opts.backup);
  c.add ("suffix", &opts.suffix;type = "string");
  c.add ("i|interactive", &assign_interactive_noclobber, &opts.interactive, &opts.noclobber, 1);
  c.add ("n|no-clobber", &assign_interactive_noclobber, &opts.interactive, &opts.noclobber, 0);
  c.add ("u|update", &opts.update);
  c.add ("v|verbose", &verboseon);
  c.add ("help", &_usage);
  c.add ("info", &info);

  i = c.process (__argv, 1);

  ifnot (i + 2  <= __argc)
    {
    tostderr (sprintf ("%s: additional argument is required", __argv[0]));
    exit_me (1);
    }

  opts.ignoredir = NULL;

  dest = evaldir (__argv[-1]);
  files = __argv[[i:__argc-2]];

  st_dest = stat_file (dest);
  if (NULL == st_dest || 0 == stat_is ("dir", st_dest.st_mode))
    if (length (files) > 1)
      {
      tostderr (sprintf ("target `%s' is not a directory", dest));
      exit_me (1);
      }

  _for i (0, length (files) - 1)
    {
    source = strtrim_end (files[i], "/");
    st_source = stat_file (source);

    if (NULL == st_source)
      {
      tostderr (sprintf ("cannot stat `%s': No such file or a directory", source));
      exit_code = 1;
      continue;
      }

    if ("." == dest)
      {
      destname = path_basename (source);
      st_destname = stat_file (destname);
      }
    else
      (destname, st_destname) = dest, st_dest;

    if (NULL != st_destname && stat_is ("dir", st_destname.st_mode))
      if (path_basename (source) != path_basename (destname))
        {
        destname = path_concat (destname, path_basename (source));
        st_destname = stat_file (destname);
        }

    if ((source == destname) || (
        (NULL != st_destname) && (st_source.st_ino == st_destname.st_ino)
        && (st_source.st_dev == st_destname.st_dev)))
      {
      tostderr (sprintf ("`%s' and `%s' are the same file", source, destname));
      exit_code = 1;
      continue;
      }

    if ((opts.update && NULL != st_destname))
      ifnot (st_source.st_mtime > st_destname.st_mtime)
        continue;

    if (stat_is ("dir", st_source.st_mode))
      {
      if (NULL != st_destname && stat_is ("dir", st_destname.st_mode))
        {
        tostderr (sprintf (
          "cannot overwrite non-directory `%s' with directory `%s'", destname, source));
        exit_code = 1;
        continue;
        }

      retval = mvdir (source, destname, opts);
      if (-1 == retval)
        exit_code = 1;
      continue;
      }
 
    retval = mvfile (source, destname, opts);
    if (-1 == retval)
      exit_code = 1;
    }
 
  exit_me (exit_code);
}
