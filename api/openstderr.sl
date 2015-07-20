variable STDERR = TEMPDIR + "/" + string (PID) + "_" + APP.appname + "_stderr.txt";
variable STDERRFD = initstream (STDERR);
variable ERR_VED;

define tostderr (str)
{
  () = lseek (STDERRFD, 0, SEEK_END);
  () = write (STDERRFD, str);
}

if (is_defined ("init_ftype"))
  {
  ERR_VED = init_ftype ("txt");
  ERR_VED._fd = STDERRFD;
  }

if (is_defined ("txt_settype"))
  txt_settype (ERR_VED, STDERR, VED_ROWS, NULL);

