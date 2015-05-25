private define new_ar (rtype, num)
{
  return rand (rtype, num * 2);
}

private define _putar_ (ar, randar, index, imin, num)
{
  variable i;

  _for i (0, length (ar) - 1)
    {
    if (ar[i] < imin)
      continue;

    randar[@index] = ar[i];

    @index++;

    if (@index == num)
      break;
    }
}

static define rand_int_ar (imin, imax, num)
{
  if (imin >= imax)
    return NULL;

  variable
    i,
    ar,
    randar = Integer_Type[num],
    index = 0,
    rtype = rand_new ();

 
  while (index < num)
    {
    ar = new_ar (rtype, num);
    ar = __tmp (ar) mod (imax);
    _putar_ (ar, randar, &index, imin, num);
    }

  return randar;
}

static define getstr (imin, imax, len)
{
  return strjoin (array_map (String_Type, &char, rand_int_ar (imin, imax, len)));
}
