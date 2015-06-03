static define find_unique_words_in_lines (ar, str, end)
{
  variable i;

  variable words = Assoc_Type[Null_Type];

  try
    {
    variable pat = pcre_compile ("(?<=\\s)(" + str + "\\w*)", PCRE_UTF8);
    }
  catch ParseError:
    return String_Type[0];

  end = NULL == end ? length (ar) - 1 : end;

  _for i (0, end)
    if (pcre_exec (pat, ar[i]))
      words[pcre_nth_substr (pat, ar[i], 0)] = NULL;
  
  words = assoc_get_keys (words);
  return words[array_sort (words)];
}
