define dir_parents (dir)
{
  variable
    ar,
    i;

  ar = strchop (dir, '/', 0);

  ifnot (strlen (ar[0]))
    {
    ar[1] = strcat ("/", ar[1]);
    ar = ar[[1:]];
    }

  ifnot (strlen (ar[-1]))
    ar = ar[[0:length(ar) - 2]];

  if (1 < length (ar))
    for (i=1;i < length (ar);i++)
      ar[i] = path_concat (ar[i-1], ar[i]);

  return ar;
}
