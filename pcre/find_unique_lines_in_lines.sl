define find_unique_lines_in_lines (ar, str, end)
{
  variable i;
  variable lines = Assoc_Type[Null_Type];
  variable pat = sprintf ("^%s%s", qualifier_exists ("ign_lead_ws")
                 ? "\\s*" : "", str);
  try
    {
    pat = pcre_compile (pat, PCRE_UTF8);
    }
  catch ParseError:
    return String_Type[0];

  end = NULL == end ? length (ar) - 1 : end;

  _for i (0, end)
    if (pcre_exec (pat, ar[i]))
      lines[ar[i]] = NULL;

  lines = assoc_get_keys (lines);
  return lines[array_sort (lines)];
}
