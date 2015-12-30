private define tostdout ()
{
  variable fmt = "%S";
  loop (_NARGS) fmt += " %S";
  variable args = __pop_list (_NARGS);

  if (-1 == lseek (stdoutfd, 0, SEEK_END))
    throw __Error, "IOLseekError::" + _function_name + "::" +
      errno_string (errno), NULL;

  if (1 == length (args) && typeof (args[0]) == Array_Type &&
    String_Type == _typeof (args[0]))
    {
    args = args[0];

    if (Integer_Type == _typeof (args))
      args = array_map (String_Type, &string, args);

    ifnot (qualifier_exists ("n"))
      args += "\n";

    try
      {
      () = array_map (Integer_Type, &write, stdoutfd, args);
      }
    catch AnyError:
      throw __Error, "IOWriteError::" + _function_name + "::" + errno_string (errno), NULL;
    }
  else
    {
    variable str = sprintf (fmt, __push_list (args), qualifier_exists ("n") ? "" : "\n");
    if (-1 == write (stdoutfd, str))
      throw __Error, "IOWriteError::" + _function_name + "::" + errno_string (errno), NULL;
    }
}
