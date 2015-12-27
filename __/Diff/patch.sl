private define patch (diff)
{
  ifnot (Array.istype (diff, String_Type))
    {
    IO.tostderr ("function argument type should be of String_Type[]");
    return NULL;
    }

  variable l = {}, i;
  _for i (0, length (diff) - 1)
    if ('-' == diff[i][0])
      continue;
    else
      list_append (l, substr (diff[i], 2, -1));

  list_to_array (l, String_Type);
}

