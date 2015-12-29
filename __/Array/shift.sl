private define shift (s, x, n) % code from upstream
{
  variable len = length(x);
  ifnot (len)
    return x;

  n = len + n mod len;
  x[[n:n+len-1] mod len];
}
