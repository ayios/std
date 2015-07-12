define getlines (fname, indent, st)
{
  indent = repeat (" ", indent);
  if (-1 == access (fname, F_OK) || 0 == st.st_size)
    {
    st.st_size = 0;
    return [sprintf ("%s\000", indent)];
    }

  return array_map (String_Type, &sprintf, "%s%s", indent, readfile (fname));
}
