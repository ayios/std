__.sadd ("Array", "shift", "shift__", NULL;trace = 0);

private define unique (s, a) % upstream code
{
  variable
    i,
    j,
    len = length (a);

  if (len <= 1)
    return [0:len-1];

	 i = array_sort (a);

  a = a[i];

  if (a[0] == a[-1])
   return [0];

  j = where (s.shift (a,-1) != a);
  i[j];
}
