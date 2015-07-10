define diff (lines, fname, retval)
{
  % if 65536 < size error
  if (strbytelen (lines) >= 256 * 256)
    {
    @retval = NULL;
    return "Bytes are more than 65535";
    }

  variable p = proc->init (1, 1, 1);

  p.stdin.in = lines;

  variable status = p.execv ([which ("diff"), "-u", fname, "-"], NULL);

  if (NULL == status)
    {
    @retval = NULL;
    return "couldn't invoke diff process";
    }

  ifnot (2 > status.exit_status)
    {
    @retval = -1;
    return p.stderr.out;
    }
 
  ifnot (status.exit_status)
    {
    @retval = 0;
    return String_Type[0];
    }
 
  @retval = 1;

  return p.stdout.out;
}

define patch (in, dir, retval)
{
  % if 65536 < size error
  if (strbytelen (in) >= 256 * 256)
    {
    @retval = NULL;
    return "Bytes are more than 65535";
    }

  variable p = proc->init (1, 1, 1);

  p.stdin.in = in;

  variable status = p.execv ([which ("patch"), "-d", dir, "-r",
    sprintf ("%s/patch.rej", TEMPDIR), "-o", "-"], NULL);

  if (NULL == status)
    {
    @retval = NULL;
    return "couldn't invoke patch process";
    }
 
  ifnot (2 > status.exit_status)
    {
    @retval = -1;
    return p.stderr.out;
    }
 
  if (1 == status.exit_status)
    {
    @retval = 1;
    return p.stderr.out;
    }

  @retval = 0;

  return p.stdout.out;
}
