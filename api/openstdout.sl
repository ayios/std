variable STDOUT = Dir.vget ("TEMPDIR") + "/" + string (Env.vget ("PID")) + "_" + APP.appname + "_stdout." +
  APP.stdouttype;
variable STDOUTFD = initstream (STDOUT);
variable OUT_VED = NULL;

if (is_defined ("init_ftype"))
  {
  OUT_VED = init_ftype (APP.stdouttype);
  OUT_VED._fd = STDOUTFD;
  }

if (is_defined (APP.stdouttype + "_settype"))
  (@__get_reference (APP.stdouttype + "_settype")) (OUT_VED, STDOUT, VED_ROWS, NULL);

define tostdout__ ()
{
  variable fmt = "%S";
  loop (_NARGS) fmt += " %S";
  variable args = __pop_list (_NARGS);

  () = lseek (STDOUTFD, 0, SEEK_END);

  if (1 == length (args) && typeof (args[0]) == Array_Type &&
    any ([String_Type, Integer_Type, UInteger_Type] == _typeof (args[0])))
    {
    args = args[0];
    if (any (_typeof (args) == [Integer_Type, UInteger_Type]))
      args = array_map (String_Type, &string, args);

    ifnot (qualifier_exists ("n"))
      args += "\n";

    try
      {
      () = array_map (Integer_Type, &write, STDOUTFD, args);
      }
    catch AnyError:
      throw __Error, "IOWriteError::" + _function_name + "::" + errno_string (errno), NULL;
    }
  else
    {
    variable str = sprintf (fmt, __push_list (args), qualifier_exists ("n") ? "" : "\n");
    () = write (STDOUTFD, str);
    }

}

__.fput ("IO", "tostdout?", &tostdout__;ReInitFunc=1);

SPECIAL = [SPECIAL, STDOUT];
