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
      @flags = File->Vget ("FLAGS")["<>"];
    else
      ifnot (assoc_key_exists (File->Vget ("FLAGS"), @flags))
        @flags = File->Vget ("FLAGS")["<>"];
      else
        @flags = File->Vget ("FLAGS")[@flags];
  else
    if (NULL == @flags)
      @flags = File->Vget ("FLAGS")["<>>|"];
    else
      ifnot (assoc_key_exists (File->Vget ("FLAGS"), @flags))
        @flags = File->Vget ("FLAGS")["<>>|"];
      else
        @flags = File->Vget ("FLAGS")[@flags];

  ifnot (NULL == @mode)
    if (String_Type == typeof (@mode))
      ifnot (assoc_key_exists (File->Vget ("PERM"), @mode))
        @mode = NULL;

  if (@flags & O_CREAT && NULL == @mode)
    @mode = File->Vget ("PERM")["___PUBLIC"];
}

private define _redir_ (stream, file, flags, mode)
{
  try
    {
    _parse_flags_mode_ (file, &flags, &mode);
    redirstreamtofile (stream, file, flags, mode);
    }
  catch AnyError:
    {
    ifnot (qualifier_exists ("dont_print"))
      IO.tostderr (__get_exception_info.object);

    return NULL, NULL;
    }
}

define redir (fp, file, flags, mode)
{
   _redir_ (fp, file, flags, mode;;__qualifiers ());
}
