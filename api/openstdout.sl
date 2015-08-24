variable STDOUT = TEMPDIR + "/" + string (PID) + "_" + APP.appname + "_stdout." + APP.stdouttype;
variable STDOUTFD = initstream (STDOUT);
variable OUT_VED = NULL;

if (is_defined ("init_ftype"))
  {
  OUT_VED = init_ftype (APP.stdouttype);
  OUT_VED._fd = STDOUTFD;
  }

if (is_defined (APP.stdouttype + "_settype"))
  (@__get_reference (APP.stdouttype + "_settype")) (OUT_VED, STDOUT, VED_ROWS, NULL);

define tostdout (str)
{
  () = lseek (STDOUTFD, 0, SEEK_END);
  () = write (STDOUTFD, str);
}

SPECIAL = [SPECIAL, STDOUT];
