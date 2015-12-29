private define new_lines (ar, pat)
{
  variable i;
  variable newlines = 0;

  _for i (1, strlen (pat) - 1)
    if ('n' == pat[i] && '\\' == pat[i - 1])
      newlines++;

  newlines;
}
