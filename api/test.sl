loadfrom ("api", "_test", NULL, &on_err);

define maain (l)
{
  variable b = mainn (l);
  () = fprintf (stdout, "maain %d\n", b);
  return b;
}
