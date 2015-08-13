importfrom ("std", "pcre", NULL, &on_eval_err);

loadfrom ("file", "remove", NULL, &on_eval_err);
loadfrom ("dir", "fswalk", NULL, &on_eval_err);
loadfrom ("dir", "evaldir", NULL, &on_eval_err);
loadfrom ("array", "arrayfuncs", NULL, &on_eval_err);

define assign_string_pattern (pat, pattern, what)
{
  @pattern = pat;
  @what = 1;
}

define file_callback (file, st, filelist, opts)
{

  ifnot (NULL == opts.pattern)
    if (pcre_exec (opts.pattern, file))
      {
      if (opts.ignore)
        return 1;
      }
    else
      if (opts.match)
        return 1;

  list_append (filelist, file);

  return 1;
}

define dir_callback (dir, st, filelist)
{
  list_append (filelist, dir);

  return 1;
}

define main ()
{
  variable
    i,
    st,
    files,
    retval,
    maxdepth,
    no_preserve_root,
    exit_code = 0,
    opts = struct
      {
      ignore,
      match,
      pattern,
      },
    interactive = NULL,
    inter_opts = ["always", "once"],
    recursive = NULL,
    filelist = {},
    dirlist = {},
    c = cmdopt_new (&_usage);

  c.add ("--no-preserve-root", &no_preserve_root);
  c.add ("ignore", &assign_string_pattern, &opts.pattern, &opts.ignore;type = "string");
  c.add ("match", &assign_string_pattern, &opts.pattern, &opts.match;type = "string");
  c.add ("r|recursive", &recursive);
  c.add ("i|interactive", &interactive;type="string", optional = "always");
  c.add ("v|verbose", &verboseon);
  c.add ("help", &_usage);
  c.add ("info", &info);

  i = c.process (__argv, 1);

  if (i == __argc)
    {
    tostderr (sprintf ("%s: argument is required", __argv[0]));
    exit_me (1);
    }
  else
    files = __argv[[i:]];
 
  files = files[wherenot ("." == files)];
  files = files[where (strncmp (files, "--", 2))];

  ifnot (NULL == opts.pattern)
    opts.pattern = pcre_compile (opts.pattern, 0);

  _for i (0, length (files) - 1)
    if ("/" == files[i] && NULL != recursive)
      {
      if (NULL == no_preserve_root)
        {
        tostderr ("Cannot remove the / (root) directory");
        exit_code = 1;
        files[i] = NULL;
        }
      else
        {
        list_append (dirlist, files[i]);
        files[i] = NULL;
        }
      }
    else
      {
      files[i] = evaldir (files[i];dont_change);

      st = lstat_file (files[i]);

      if (NULL == st)
        {
        tostderr (sprintf ("%s: No such file", files[i]));
        files[i] = NULL;
        exit_code = 1;
        continue;
        }

      if (stat_is ("dir", st.st_mode))
        if (NULL == recursive)
          {
          tostdout (sprintf ("%s: omitting directory", files[i]));
          files[i] = NULL;
          exit_code = 1;
          continue;
          }
        else
          {
          if (-1 == access (files[i], W_OK))
            tostderr (sprintf ("%s: cannot remove, permission denied", files[i]));
          else
            list_append (dirlist, files[i]);

          files[i] = NULL;
          exit_code = 1;
          continue;
          }

      if (-1 == access (files[i], W_OK) && 0 == stat_is ("lnk", st.st_mode))
        {
        tostderr (sprintf ("%s: cannot remove, permission denied", files[i]));

        files[i] = NULL;

        exit_code = 1;
        }
      }

  files = files[wherenot (_isnull (files))];

  variable fs;

  if (length (dirlist))
    _for i (0, length (dirlist) - 1)
      {
      fs = fswalk_new (&dir_callback, &file_callback;
          dargs = {filelist},
          fargs = {filelist, opts});

      fs.walk (dirlist[i]);
      }

  filelist = [length (files) ? files : "", length (filelist) ?
    list_to_array (filelist) : ""];
  filelist = filelist[where (strlen (filelist))];
  filelist = filelist[unique (filelist)];
  filelist = filelist[array_sort (filelist;dir=-1)];

  ifnot (length (filelist))
    exit_me (0);

  if (NULL != interactive || (recursive != NULL && 1 < length (filelist)))
    {
    ifnot (NULL == interactive)
      {
      if (NULL == wherefirst (inter_opts == interactive))
        {
        tostderr (sprintf
          ("%s: wrong interactive option. Valid are (always,once,never)", interactive));
        exit_me (1);
        }
      }
    else interactive = "once";
 

    if (interactive == "once")
      {
      retval = ask ([
        sprintf ("There %d files for removal", length (filelist)),
        "Do you want to proceed?",
        "y[es remove files all files without asking again]",
        "q[uit question and abort the operation]",
        "s[how files and redo the question]"
        ],
        ['y', 'q', 's']);

      switch (retval)

        {
        case 'y':
          interactive = NULL;
        }

        {
        case 'q':
          tostdout ("Aborting ...");
          exit_me (0);
        }

        {
        case 's':
          retval = ask ([
            sprintf ("There %d files for removal", length (filelist)),
            "Do you want to proceed?",
            "y[es remove files all files without asking again]",
            "q[uit question and abort the operation]"
            ],
            ['y', 'q']);

          switch (retval)
            {
            case 'y':
              interactive = NULL;
            }

            {
            case 'q':
              tostdout ("Aborting ...");
              exit_me (0);
            }
        }
      }
    else if ("never" == interactive)
      interactive = NULL;
    }

  _for i (0, length (filelist) - 1)
    {
    st = lstat_file (filelist[i]);
    
    retval = __remove (filelist[i], &interactive, stat_is ("dir", st.st_mode));

    if (-1 == retval)
      exit_code = 1;

    if ("exit" == interactive)
      {
      tostdout ("Quiting ...");
      exit_me (exit_code);
      }
    }

  exit_me (exit_code);
}
