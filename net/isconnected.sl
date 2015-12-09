load.from ("net", "fetch", NULL;err_handler = &__err_handler__);

define isconnected ()
{
  variable
    s = fetch_new ();

  return any ([42, 40, 39] == s.fetch ("http://www.google.com";write_to_var, dont_print)) ? 0 : 1;
}
