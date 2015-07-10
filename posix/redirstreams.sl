private define redirstreamtofile (stream, file, flags, mode)
{
  variable oldfd, newfd;

  if (NULL == mode)
    newfd = open (file, flags);
  else
    newfd = open (file, flags, mode);

  if (NULL == newfd)
    throw OpenError, " ", errno_string (errno);

  oldfd = dup_fd (fileno (stream));
 
  if (-1 == dup2_fd (newfd, _fileno (stream)))
    throw OpenError, " ", "dup2_fd failed " + errno_string (errno);
 
  return newfd, oldfd;
}

private define _parse_flags_mode_ (file, flags, mode)
{
  if (-1 == access (file, F_OK))
    if (NULL == @flags)
      @flags = FILE_FLAGS["<>"];
    else
      ifnot (assoc_key_exists (FILE_FLAGS, @flags))
        @flags = FILE_FLAGS["<>"];
      else
        @flags = FILE_FLAGS[@flags];
  else
    if (NULL == @flags)
      @flags = FILE_FLAGS["<>>|"];
    else
      ifnot (assoc_key_exists (FILE_FLAGS, @flags))
        @flags = FILE_FLAGS["<>>|"];
      else
        @flags = FILE_FLAGS[@flags];
 
  ifnot (NULL == @mode)
    if (String_Type == typeof (@mode))
      ifnot (assoc_key_exists (PERM, @mode))
        @mode = NULL;

  if (@flags & O_CREAT && NULL == @mode)
    @mode = PERM["___PUBLIC"];
}

private define _redir_ (stream, file, flags, mode)
{
  _parse_flags_mode_ (file, &flags, &mode);
 
  try
    return redirstreamtofile (stream, file, flags, mode);
  catch OpenError:
    {
    ifnot (qualifier_exists ("dont_print"))
      tostderr (__get_exception_info.object);

    return NULL;
    }
}

define redirstdout (file, flags, mode)
{
  return _redir_ (stdout, file, flags, mode;;__qualifiers ());
}

define redirstderr (file, flags, mode)
{
  return _redir_ (stderr, file, flags, mode;;__qualifiers ());
}
