define week_day (tim)
{
  variable
    err,
    lday,
    lmonth,
    lyear,
    jdn = qualifier ("jdn", julian_day_nr (tim;hour = 12));
 
  if (NULL == jdn)
    {
    err = ();
    return err, NULL;
    }

  variable a = (14 - tim.tm_mon) / 12;

  lyear = tim.tm_year - a + (0 > tim.tm_year);
  lmonth = (tim.tm_mon + 1) + (12 * a ) - 2;

  if (jdn > 2299160)
    lday = (tim.tm_mday + lyear + (lyear / 4) - (lyear / 100) +  (lyear / 400)
           + (31 * lmonth) / 12) mod 7;
  else
    lday = (5 + tim.tm_mday + lyear + lyear / 4 + (31 * lmonth) / 12) mod 7;

  return lday;
}
