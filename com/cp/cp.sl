importfrom ("std", "pcre", NULL, &on_eval_err);

loadfrom ("dir", "makedir", NULL, &on_eval_err);
loadfrom ("dir", "parents", NULL, &on_eval_err);
loadfrom ("stdio", "copy", NULL, &on_eval_err);
loadfrom ("dir", "cprecursive", NULL, &on_eval_err);
loadfrom ("dir", "cprecursive_opts", NULL, &on_eval_err);
loadfrom ("dir", "evaldir", NULL, &on_eval_err);
loadfrom ("dir", "are_same_files", NULL, &on_eval_err);

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
      interactive,
      noclobber,
      force,
      backup,
      maxdepth = 0,
      update,
      suffix = "~",
      permissions,
      nodereference,
      @opts_share_cprec_init (),
      },
    recursive = NULL,
    parents = NULL,
    dest,
    source,
    st_source,
    isdir_source,
    destname,
    index,
    st_destname,
    stat_dest,
    files,
    path_arr,
    retval,
    exit_code = 0,
    ar = String_Type[0],
    i,
    c = cmdopt_new (&_usage);

  c.add ("all", &opts.permissions);
  c.add ("backup", &opts.backup);
  c.add ("suffix", &opts.suffix;type = "string");
  c.add ("dereference", &opts.nodereference);
  c.add ("i|interactive", &assign_interactive_noclobber, &opts.interactive, &opts.noclobber, 1);
  c.add ("force", &opts.force);
  c.add ("n|no-clobber", &assign_interactive_noclobber, &opts.interactive, &opts.noclobber, 0);
  c.add ("u|update", &opts.update);
  c.add ("R|r|recursive", &recursive);
  c.add ("maxdepth", &opts.maxdepth;type = "int");
  c.add ("parents", &parents);
  c.add ("ignoredir", &opts.ignoredir;type = "string", append);
  c.add ("ignore", &opts.ignorepat;type = "string");
  c.add ("match",  &opts.matchpat;type = "string");
  c.add ("nothidden", &opts.copy_hidden;type="string", optional=NULL);
  c.add ("v|verbose", &verboseon);
  c.add ("help", &_usage);
  c.add ("info", &info);

  i = c.process (__argv, 1);

  ifnot (i + 2  <= __argc)
    {
    tostderr (sprintf ("%s: additional argument is required", __argv[0]));
    return 1;
    }

  if (opts.noclobber && opts.backup)
    {
    tostderr ("Options: `--backup' and `--no-clobber' are mutually exclusive");
    return 1;
    }

  if (opts.maxdepth)
    recursive = 1;

  ifnot (NULL == opts.matchpat)
    opts.matchpat = pcre_compile (opts.matchpat, 0);
 
  ifnot (NULL == opts.ignorepat)
    opts.ignorepat = pcre_compile (opts.ignorepat, 0);
 
  if (length (opts.ignoredir))
    opts.ignoredir = list_to_array (opts.ignoredir);
  else
    opts.ignoredir = NULL;

  dest = evaldir (__argv[-1]);
  stat_dest = stat_file (dest);

  files = __argv[[i:__argc - 2]];

  if ((NULL == stat_dest || 0 == stat_is ("dir", stat_dest.st_mode))
    && 1 < length (files))
    {
    tostderr (sprintf ("target %s is not a directory", dest));
    return 1;
    }

  _for i (0, length (files) -1)
    {
    source = strtrim_end (files[i], "/");
    st_source = lstat_file (source);

    if (NULL == st_source)
      {
      tostderr (sprintf ("cannot stat `%s': No such file or directory", source));
      exit_code = 1;
      continue;
      }

    isdir_source= stat_is ("dir", st_source.st_mode);

    ifnot (NULL == parents)
      {
      variable lsource = source;
      if (path_is_absolute (source))
        lsource = source[[1:]];

      if (isdir_source)
        if ("." == dest)
          destname = lsource;
        else
          destname = path_concat (dest, lsource);
      else
        if ("." == dest)
          destname = path_dirname (lsource);
        else
          destname = path_concat (dest, path_dirname (lsource));

      path_arr = dir_parents (destname);
      st_destname = stat_file (destname);

      ifnot (NULL == st_destname)
        path_arr = path_arr[[1:]];

      _for index (0, length (path_arr) - 1)
        if (-1 == makedir (path_arr[index], NULL))
          break;

      if (NULL == st_destname)
        st_destname = stat_file (destname);
      }
    else
      if ("." == dest)
        {
        destname = path_basename (source);
        st_destname = stat_file (destname);
        }
      else
        (destname, st_destname) = dest, stat_dest;

    if (NULL != st_destname && stat_is ("dir", st_destname.st_mode))
      if (path_basename (source) != path_basename (destname))
        {
        destname = path_concat (destname, path_basename (source));
        st_destname = stat_file (destname);
        }

    if (source == destname ||
        1 == are_same_files (source, destname;
          fnamea_st = st_source, fnameb_st = st_destname))
      {
      tostdout (sprintf ("`%s' and `%s' are the same file", source, destname));
      exit_code = 1;
      continue;
      }

    if ((NULL != st_destname && 0 == stat_is ("dir", st_destname.st_mode)) && isdir_source)
      {
      tostderr (sprintf (
        "cannot overwrite non directory `%s' with directory `%s'", destname, source));
      exit_code = 1;
      continue;
      }

    if (isdir_source)
      if (NULL == recursive)
        {
        tostdout (sprintf ("omitting directory `%s'", source));
        exit_code = 1;
        continue;
        }
      else
        {
        if (cprecursive (source, destname, opts) == -1)
          exit_code = 1;
        continue;
        }

    if (NULL == opts.copy_hidden)
      if ('.' == path_basename (source)[0])
        {
        tostdout (sprintf ("omitting hidden file `%s'", source));
        continue;
        }

    ifnot (NULL == opts.matchpat)
      ifnot (pcre_exec (opts.matchpat, source))
        {
        tostdout (sprintf ("ignore file: %s", source));
        continue;
        }

    ifnot (NULL == opts.ignorepat)
      if (pcre_exec (opts.ignorepat, source))
        {
        tostdout (sprintf ("ignore file: %s", source));
        continue;
        }
 
    retval = copy (source, destname, st_source, st_destname, opts);
    if (-1 == retval)
      exit_code = 1;
    }

   exit_me (exit_code);
}
