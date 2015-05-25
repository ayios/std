static define getloginname ()
{
  variable name;

  () = fputs ("login: ", stdout);
  () = fgets (&name, stdin);
  () = fflush (stdout);

  return strtrim_end (name);
}

