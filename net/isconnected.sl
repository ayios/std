loadfrom ("net", "fetch", NULL, &on_eval_err);

define isconnected ()
{
  variable
    s = fetch_new ();

  return any ([42, 40, 39] == s.fetch ("http://www.google.com";write_to_var, dont_print)) ? 0 : 1;
}
