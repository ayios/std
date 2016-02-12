private define unique_words (ar, str, end)
{
  variable i;
  variable words = Assoc_Type[Null_Type];
  variable pat = sprintf ("(%s%s\\w*)", "\\w*", str);

  try
    {
    pat = pcre_compile (pat, PCRE_UTF8|PCRE_UCP|PCRE_NO_UTF8_CHECK);
    }
  catch ParseError:
    {
    IO.tostderr ("PCRE PARSE ERROR", __get_exception_info.message);
    return String_Type[0];
    }

  end = NULL == end ? length (ar) - 1 : end;

  _for i (0, end)
    if (pcre_exec (pat, ar[i]))
      words[pcre_nth_substr (pat, ar[i], 0)] = NULL;

  if (qualifier_exists ("ign_pat"))
    if (assoc_key_exists (words, str))
      assoc_delete_key (words, str);

  words = assoc_get_keys (words);
  words[array_sort (words)];
}
