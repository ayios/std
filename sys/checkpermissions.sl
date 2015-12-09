load.from ("sys", "modetoint", NULL;err_handler = &__err_handler__);

define checkperm (mode, perm)
{
  mode = modetoint (mode);

  ifnot (mode == perm)
    return -1;

  return 0;
}

