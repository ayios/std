define filterexcom (s, ar)
{
  ifnot ('!' == s._chr)
    ifnot (strlen (s.argv[0]))
      ar = ar[where (strncmp (ar, "!", 1))];

  return ar;
} 

define filterexargs (s, args, type, desc)
{
  if (s._ind && '!' == s.argv[0][0])
    return [args, "--sudo", "--pager"], [type, "void", "void"],
      [desc, "execute command as superuser", "viewoutput in a scratch buffer"];

  return args, type, desc;
}
