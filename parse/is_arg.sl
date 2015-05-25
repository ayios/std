define is_arg (arg, argv)
{
  variable index = wherenot (strncmp (argv, arg, strlen (arg)));
  return length (index) ? index[0] : NULL;
}

