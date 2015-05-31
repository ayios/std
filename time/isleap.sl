define isleap (year)
{
  if ((0 == year mod 4 && 0 != year mod 100) || 0 == year mod 400)
    return 1;

  return 0;
}
