private define unique_words (ar, str, end)
{
  variable i;

  variable words = Assoc_Type[Null_Type];
  variable pat = sprintf ("(%s%s\\w*)", "\\w*", str);

  try
    {
    pat = pcre_compile (pat, PCRE_UTF8|PCRE_UCP);
    }
  catch ParseError:
    return String_Type[0];

  end = NULL == end ? length (ar) - 1 : end;

  _for i (0, end)
    if (pcre_exec (pat, ar[i]))
      words[pcre_nth_substr (pat, ar[i], 0)] = NULL;

  words = assoc_get_keys (words);
  words[array_sort (words)];
}
