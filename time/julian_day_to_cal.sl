load.from ("time", "week_day", NULL;err_handler = &__err_handler__);
 
define julian_day_to_cal (tim, jdn)
{
  variable
    a,
    lyear,
    months = [
      "January", "February", "March", "April", "May", "June", "July",
      "August", "September", "October", "November", "December"],
    week_days = [
      "Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday"],
    z = jdn;

  if (jdn > 2299160)
    {
      variable
        w = typecast (((z - 1867216.25) / 36524.25), Int_Type),
        x = typecast (w / 4, Int_Type);
      a = z + 1 + w - x;
    }
  else
    a = z;

  variable
    b = a + 1524,
    c = typecast ((b - 122.1) / 365.25, Int_Type),
    d = typecast (365.25 * c, Int_Type),
    e = typecast ((b - d) / 30.6001, Int_Type),
    f = typecast (30.6001 * e, Int_Type),
    lday = b - d - f,
    lmonth = e - 1;

  if (lmonth > 12)
    lmonth = e - 13;

  if (lmonth == 1 || lmonth == 2)
    lyear = c - 4715;
  else
    lyear = c - 4716;

  variable weekday = week_day (tim;jdn = jdn);

  return sprintf ("%d %s, %d, %s", lday, months[lmonth - 1], lyear,
      week_days[weekday]);
}
