importfrom ("std", "pcre", NULL, &on_eval_err);
loadfrom ("dir", "fswalk", NULL, &on_eval_err);

private variable
  MAXDEPTH = 1,
  PAT = NULL,
  NEWLINES = 0,
  RECURSIVE = 0,
  HIDDENDIRS = 0,
  HIDDENFILES = 0,
  LINENRS = Integer_Type[0],
  COLS = Integer_Type[0],
  FNAMES = String_Type[0],
  LINES = String_Type[0],
  INDEX = 0;

private define grepit (lline, file)
{
  variable
    col,
    holdcol = 0,
    orig = lline;

  while (pcre_exec (PAT, lline))
    {
    FNAMES = [FNAMES, file];
    LINENRS = [LINENRS, INDEX];
    col = pcre_nth_match (PAT, 0);
    COLS = [COLS, holdcol + col[0] + 1];
    LINES = [LINES, strreplace (orig, "\n", "\\n")];

    holdcol = COLS[-1];

    ifnot (holdcol + 1 > strlen (orig))
      lline = substr (orig, holdcol + 1, -1);
    else
      break;
    }
}

private define exec (file)
{
  INDEX = 1;
 
  variable
    str,
    i = 0,
    ar = readfile (file);
 
  while (i < length (ar))
    {
    if (i + NEWLINES > length (ar) - 1)
      break;

    str = strjoin (ar[[i:i+NEWLINES]], NEWLINES ? "\n" : "");
 
    i++;
 
    try
      grepit (str, file);
    catch AnyError:
      {
      tostderr (sprintf ("caught an error in exec func in script: %s", __FILE__));
      tostderr (sprintf ("file that occured: %s", file));
      tostderr (sprintf ("linenr that occured: %d", i));
      tostderr (sprintf ("line that occured: %S", ar[i]));
      }

    INDEX++;
    }
}

private define dir_callback_a (dir, st)
{
  ifnot (HIDDENDIRS)
    if ('.' == path_basename (dir)[0])
      return 0;

  if (length (strtok (dir, "/")) > MAXDEPTH)
    return 0;

  return 1;
}

private define file_callback (file, st)
{
  ifnot (stat_is ("reg", st.st_mode))
    return 1;
 
  if (access (file, R_OK))
    return 1;
 
  ifnot (HIDDENFILES)
    if ('.' == path_basename (file)[0])
      return 1;

  exec (file);

  return 1;
}

private define recursivefunc (dir, depth)
{
  variable
    fs = fswalk_new (&dir_callback_a, &file_callback);
 
  MAXDEPTH = length (strtok (dir, "/")) + depth;
 
  fs.walk (dir);
 
  return 0;
}

private define grep (file, depth)
{
  if (_isdirectory (file))
    ifnot (RECURSIVE)
      return 0;
    else
      return recursivefunc (file, depth);

  if (-1 == access (file, F_OK|R_OK))
    {
    tostderr (sprintf ("%s: %s", file, errno_string (errno)));
    return 1;
    }

  exec (file);
}

private define dir_callback (dir, st)
{
  ifnot (HIDDENDIRS)
    if ('.' == path_basename (dir)[0])
      return 0;

  if (length (strtok (dir, "/")) > MAXDEPTH)
    return 0;

  return 1;
}

private define file_callback_c (file, st, filelist)
{
  if (stat_is ("lnk", st.st_mode))
    if ((NULL == stat_file (file)) && (errno == ENOENT))
      list_append (filelist, sprintf ("%s: %s", file, readlink (file)));

  return 1;
}

private define file_callback_b (file, st, filelist)
{
  if (pcre_exec (PAT, path_basename (file)))
    list_append (filelist, file);

  return 1;
}

private define findfilesfunc (dir, depth)
{
  ifnot (_isdirectory (dir))
    {
    if (pcre_exec (PAT, path_basename (dir)))
      return [dir];

    return String_Type[0];
    }

  variable
    filelist = {},
    fs = fswalk_new (&dir_callback, &file_callback_b; fargs = {filelist});
 
  MAXDEPTH = length (strtok (dir, "/")) + depth;
  fs.walk (dir);
 
  ifnot (length (filelist))
    return String_Type[0];

  return list_to_array (filelist);
}

private define danglinglinksfunc (dir, depth)
{
  variable
    filelist = {},
    fs = fswalk_new (&dir_callback, &file_callback_c; fargs = {filelist});
 
  MAXDEPTH = length (strtok (dir, "/")) + depth;
  fs.walk (dir);
 
  ifnot (length (filelist))
    return String_Type[0];

  return list_to_array (filelist);
}

define main ()
{
  variable
    i,
    ia,
    err,
    files,
    maxdepth = NULL,
    findfiles = NULL,
    danglinglinks = NULL,
    c = cmdopt_new (&_usage);

  c.add ("pat", &PAT;type="string");
  c.add ("hidden-dirs", &HIDDENDIRS);
  c.add ("hidden-files", &HIDDENFILES);
  c.add ("maxdepth", &maxdepth;type = "int");
  c.add ("recursive", &RECURSIVE);
  c.add ("findfiles", &findfiles);
  c.add ("danglinglinks", &danglinglinks);
  c.add ("help", &_usage);
  c.add ("info", &info);

  i = c.process (__argv, 1);

  if (i == __argc && danglinglinks == NULL == findfiles)
    {
    tostderr (sprintf ("%s: it requires a filename", __argv[0]));
    exit_me (1);
    }

  if (NULL == PAT && NULL == danglinglinks)
    {
    tostderr (sprintf (
      "%s: pattern was not given, I don't know what to look", __argv[0]));
    exit_me (1);
    }

  ifnot (RECURSIVE)
    maxdepth = 0;
  else
    if (NULL == maxdepth)
      maxdepth = 1000;
   
  ifnot (NULL == PAT)
    {
    ifnot (strlen (PAT))
      exit_me (1);

    _for ia (1, strlen (PAT) - 1)
      if ('n' == PAT[ia] && '\\' == PAT[ia - 1])
        NEWLINES++;
 
    try (err)
      {
      PAT = pcre_compile (PAT, 0);
      }
    catch ParseError:
      {
      tostderr (err.descr);
      exit_me (1);
      }
    }

  if (danglinglinks == NULL == findfiles)
    {
    files = __argv[[i:]];
    files = files[where (strncmp (files, "--", 2))];

    array_map (Void_Type, &grep, files, maxdepth);
 
    ifnot (length (LINENRS))
      {
      tostdout ("Nothing found");
      exit_me (2);
      }

    _for i (0, length (LINENRS) - 1)
      tostdout (sprintf ("%s|%d col %d| %s", FNAMES[i], LINENRS[i], COLS[i], LINES[i]));

    exit_me (0);
    }
 
  if (i == __argc)
    files = [getcwd ()];
  else
    files = __argv[[i:]];
 
  files = files[where (strncmp (files, "--", 2))];
 
  variable ar;

  ifnot (NULL == findfiles)
    ar = array_map (Array_Type, &findfilesfunc, files, maxdepth);
  else
    ar = array_map (Array_Type, &danglinglinksfunc, files, maxdepth);

  ifnot (length (ar))
    {
    tostdout ("Nothing found");
    exit_me (2);
    }
  else
    _for i (0, length (ar) - 1)
      array_map (Void_Type, &tostdout, array_map
          (String_Type, &sprintf, "%s|0 col 0| 1", ar[i]));

  exit_me (0);
}
