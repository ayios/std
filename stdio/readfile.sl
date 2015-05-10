define readfile (file)
{
  variable
    end = qualifier ("end", NULL),
    fp = fopen (file, "r");

  if (NULL == fp)
    return NULL;

  ifnot (NULL == end)
    return array_map (String_Type, &strtrim_end, fgetslines (fp, end), "\n");

  return array_map (String_Type, &strtrim_end, fgetslines (fp), "\n");
}

