variable STDERR = Dir.vget ("TEMPDIR") + "/" + string (Env.vget ("PID")) + "_" + APP.appname + "_stderr.txt";
variable STDERRFD = initstream (STDERR);
variable ERR_VED;

define tostderr__ ()
{
  variable fmt = "%S";
  loop (_NARGS) fmt += " %S";
  variable args = __pop_list (_NARGS);

  () = lseek (STDERRFD, 0, SEEK_END);

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
      () = array_map (Integer_Type, &write, STDERRFD, args);
      }
    catch AnyError:
      throw __Error, "IOWriteError::" + _function_name + "::" + errno_string (errno), NULL;
    }
  else
    {
    variable str = sprintf (fmt, __push_list (args), qualifier_exists ("n") ? "" : "\n");
    () = write (STDERRFD, str);
    }
}

__.fput ("IO", "tostderr?", &tostderr__;ReInitFunc=1);

if (is_defined ("init_ftype"))
  {
  ERR_VED = init_ftype ("txt");
  ERR_VED._fd = STDERRFD;
  }

if (is_defined ("txt_settype"))
  txt_settype (ERR_VED, STDERR, VED_ROWS, NULL);

SPECIAL = [SPECIAL, STDERR];
