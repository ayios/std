loadfrom ("sys", "modetoint", NULL, &on_eval_err);

define checkperm (mode, perm)
{
  mode = modetoint (mode);

  ifnot (mode == perm)
    return -1;

  return 0;
}

