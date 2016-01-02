variable STDERR = Dir.vget ("TEMPDIR") + "/" + string (Env.vget ("PID")) + "_" + APP.appname + "_stderr.txt";
variable STDERRFD = initstream (STDERR);
variable ERR_VED;

define tostderr__ ()
{
  variable str;
  variable fmt = "%S";
  loop (_NARGS) fmt += " %S";
  variable args = __pop_list (_NARGS);

  () = lseek (STDERRFD, qualifier ("offset", 0), qualifier ("seek_pos", SEEK_END));

  if (1 == length (args) && typeof (args[0]) == Array_Type &&
    any ([String_Type, BString_Type, Integer_Type, UInteger_Type] == _typeof (args[0])))
    {
    args = args[0];
    if (any (_typeof (args) == [Integer_Type, UInteger_Type]))
      args = array_map (String_Type, &string, args);

    str = strjoin (args, "\n");

    ifnot (qualifier_exists ("n"))
      str += "\n";
    }
  else if (1 == length (args) &&
    any ([String_Type, BString_Type] == typeof (args[0])))
      str = args[0] + (qualifier_exists ("n") ? "" : "\n");
  else
    str = sprintf (fmt, __push_list (args), qualifier_exists ("n") ? "" : "\n");

  if (-1 == write (STDERRFD, str))
    throw __Error, "IOWriteError::" + _function_name + "::" + errno_string (errno), NULL;
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
