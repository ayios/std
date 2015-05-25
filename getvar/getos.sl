define getos ()
{
  variable buf;
 
  variable fp = popen ("uname -o -m", "r");
 
  () = fgets (&buf, fp);
 
  variable ar = strtok (buf);

  return ar[1], ar[0];
}
