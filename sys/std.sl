define isdirectory (file)
{
  variable st = qualifier ("st", stat_file (file));
  return NULL != st && stat_is ("dir", st.st_mode);
}


define writefile (buf, fname)
{
  variable
    mode = qualifier ("mode", "w"),
    fmt = qualifier ("fmt", "%s\n"),
    fp = fopen (fname, mode);

  if (NULL == fp)
    throw OpenError, "Error while opening $fname"$;

  if (any (-1 == array_map (Integer_Type, &fprintf, fp, fmt, buf)))
    throw WriteError, "Error while writting $fname"$;

  if (-1 == fclose (fp))
    throw IOError, errno_string(errno);
}

define struct_field_exists (s, field)
{
  return wherefirst (get_struct_field_names (s) == field);
}

define eval_dir (dir)
{
  if ('~' == dir[0])
    (dir,) = strreplace (dir, "~", getenv ("HOME"), 1);
  else if (0 == path_is_absolute (dir)
          && '$' != dir[0]
          && 0 == qualifier_exists ("dont_change"))
    dir = path_concat (getcwd (), dir);
  else
    dir = eval ("\"" + dir + "\"$");

  return dir;
}

define assoc_add_key (map, key, val)
{
  map[key] = val;
}

define read_fd (fd)
{
  variable
    buf,
    str = "";

  while (read (fd, &buf, 1024) > 0)
    str = sprintf ("%s%s", str, buf);

  return strlen (str) ? str : NULL;
}

define are_same_files (fnamea, fnameb)
{
  variable
    sta = qualifier ("fnamea_st", stat_file (fnamea)),
    stb = qualifier ("fnameb_st", stat_file (fnameb));

  if (any ((sta == NULL) or (stb == NULL)))
    return 0;

  if (sta.st_ino == stb.st_ino && sta.st_dev == stb.st_dev)
    return 1;

  return 0;
}

define pid_status (pid)
{
  variable
    buf,
    fp = popen (sprintf ("ps --no-headers --pid %d", pid), "r");
 
  if (-1 == fgets (&buf, fp))
    return 0;

  if ("<defunct>" == strtok (strtrim_end (buf))[-1])
    return -1;

  return 1;
}

define modetoint (mode)
{
  variable
    S_ISUID = 04000,    % Set user ID on execution
    S_ISGID = 02000,    % Set group ID on execution
    S_ISVTX = 01000,    % Save swapped text after use (sticky)
    CHMOD_MODE_BITS =  (S_ISUID|S_ISGID|S_ISVTX|S_IRWXU|S_IRWXG|S_IRWXO);

  return atoi (sprintf ("%d", mode & CHMOD_MODE_BITS));
}
