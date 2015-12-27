private define istype (a, type)
{
  ifnot (typeof (a) == Array_Type)
    return 0;

  ifnot (NULL == type)
    ifnot (_typeof (a) == type)
      return 0;
  1;
}
