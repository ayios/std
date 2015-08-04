define shell ()
{
  variable argv = __pop_list (_NARGS);

  argv = list_to_array (argv, String_Type);

  variable s = os->init_app ("shell", path_dirname (__FILE__), argv);

  if (-1 == os->doproc (s, argv;;__qualifiers ()))
    return NULL;
 
  if (qualifier_exists ("dont_connect"))
    return s;

  os->connect_to_child (s);

  return 0;
}
