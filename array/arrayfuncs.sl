% Short upstream's version
define shift (x, n)
{
   variable len = length(x);
   ifnot (len) return x;

   % allow n to be negative and large
   n = len + n mod len;
   return x[[n:n+len-1] mod len];
}

define unique (a)
{
  variable
    i,
    j,
    len = length(a);

  if (len <= 1) return [0:len-1];

	i = array_sort(a);

  a = a[i];

  if (a[0] == a[-1]) return [0];

  j = where (shift(a,-1)!=a);
  return i[j];
}
