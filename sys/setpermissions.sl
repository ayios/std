define setperm (file, perm)
{
  if (-1 == chmod (file, perm))
    return -1;

  return 0;
}

