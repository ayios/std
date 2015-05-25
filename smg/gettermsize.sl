define gettermsize ()
{
  variable
    retval,
    fp = popen ("stty size", "r");

  () = fgets (&retval, fp);

  () = pclose (fp);

  retval = strtok (retval);

  return integer (retval[0]), integer (retval[1]);
}
