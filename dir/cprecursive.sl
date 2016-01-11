load.module ("std", "pcre", NULL;err_handler = &__err_handler__);
load.from ("stdio", "copy", NULL;err_handler = &__err_handler__);
load.from ("__/FS", "walk", NULL;err_handler = &__err_handler__);
load.from ("dir", "makedir", NULL;err_handler = &__err_handler__);

public variable PCRE_UCP = 0x20000000;

private define dir_callback (dir, st, source, dest, opts, exit_code)
{
  ifnot (NULL == opts.ignoredir)
    {
    variable ldir = strtok (dir, "/");
    if (any (ldir[-1] == opts.ignoredir))
      {
      IO.tostdout (sprintf ("ignored dir: %s", dir));
      return 0;
      }
    }

  (dest, ) = strreplace (dir, source, dest, 1);

  if (NULL == stat_file (dest))
    if (-1 == makedir (dest, NULL))
      {
      @exit_code = -1;
      return -1;
      }

  1;
}

private define file_callback (file, st_source, source, dest, opts, exit_code)
{
  if (NULL == opts.copy_hidden)
    if ('.' == path_basename (file)[0])
      {
      IO.tostdout (sprintf ("omitting hidden file `%s'", file));
      return 1;
      }

  ifnot (NULL == opts.matchpat)
    ifnot (pcre_exec (opts.matchpat, file))
      {
      IO.tostdout (sprintf ("ignore file: %s", file));
      return 1;
      }

  ifnot (NULL == opts.ignorepat)
    if (pcre_exec (opts.ignorepat, file))
      {
      IO.tostdout (sprintf ("ignore file: %s", file));
      return 1;
      }

  (dest, ) = strreplace (file, source, dest, 1);


  if (copy (file, dest, st_source, stat_file (dest), opts) == -1)
    {
    @exit_code = -1;
    return -1;
    }

  1;
}

define cprecursive (source, dest, opts)
{
  variable exit_code = 0;

  FS.walk (source, &dir_callback, &file_callback;
    dargs = {source, dest, opts, &exit_code},
    fargs = {source, dest, opts, &exit_code},
    maxdepth = opts.maxdepth);

  exit_code;
}
