private define tostr (s)
{
 s.v = string (s.v);
}

private define put (s, val)
{
  s.v = val;
}

private define nr ()
{
  return struct {v, put = &put, tostr = &tostr};
}
