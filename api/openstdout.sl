variable STDOUT = Dir->Vget ("TEMPDIR") + "/" + string (Env->Vget ("PID")) + "_" + APP.appname + "_stdout." +
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
  variable str;
  variable fmt = "%S";
  loop (_NARGS) fmt += " %S";
  variable args = __pop_list (_NARGS);

  () = lseek (STDOUTFD, qualifier ("offset", 0), qualifier ("seek_pos", SEEK_END));

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

  if (-1 == write (STDOUTFD, str))
    throw __Error, "IOWriteError::" + _function_name + "::" + errno_string (errno), NULL;
}

IO->Fun ("tostdout?", &tostdout__);

SPECIAL = [SPECIAL, STDOUT];
