define julian_day_nr (tim)
{
  variable
    lhour = qualifier ("hour", tim.tm_hour),
    lmonth = tim.tm_mon + 1;

  % http://en.wikipedia.org/wiki/Julian_day
  % until 1/1/4713 B.C

  % Calendar change
  if (tim.tm_year == 1582 && lmonth == 10 &&
    (tim.tm_mday < 15 &&  tim.tm_mday > 4))
    return "This happens to be a day within 4 - 15 of October of 1582", NULL;

  variable
    jdn,
    newmonth,
    newyear,
    a = (14 - lmonth) / 12;

  newyear = (tim.tm_year + 4801 - _ispos (tim.tm_year)) - a;
  newmonth = lmonth +  (12 * a) - 3;

  if (tim.tm_year > 1582 ||
      (tim.tm_year == 1582 && (lmonth > 10 || (lmonth == 10 && tim.tm_mday > 4))))
    jdn = tim.tm_mday + ((153 * newmonth + 2) / 5) + (newyear * 365) + (newyear / 4)
        - (newyear / 100) + (newyear / 400) - 32045;
  else
    jdn = tim.tm_mday + (153 * newmonth + 2) / 5 + newyear * 365 + newyear / 4 - 32083;

  if (12 > lhour >= 0)
    jdn--;
 
  return jdn;
}
