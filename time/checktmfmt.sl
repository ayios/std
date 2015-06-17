loadfrom ("time", "isleap", NULL, &on_eval_err);

define checktmfmt (tim)
{
  ifnot (tim.tm_year)
    return "0: is not a valid year", NULL;

  ifnot (-1 < tim.tm_mon < 13)
    return sprintf ("%d: is not a valid month", tim.tm_mon + 1), NULL;

  variable m_ar = [31, 28 + isleap (tim.tm_year), 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

  ifnot (1 <= tim.tm_mday <= m_ar[tim.tm_mon - 1])
    return sprintf ("%d: is not a valid day", tim.tm_mday), NULL;
 
  if ((tim.tm_hour > 23 || tim.tm_min > 59 || tim.tm_sec > 59) ||
       (tim.tm_hour < 0  || tim.tm_min < 0  || tim.tm_sec < 0 ))
    return "Not a valid hour/minutes/second format", NULL;

  return 0;
}
