private define exec (s, ar)
{
  variable
    ia,
    tok,
    chr,
    str,
    type,
    match,
    fpart,
    lpart,
    retval,
    context,
    replace,
    finished,
    newlines,
    lnronfile = s.lnronfile,
    i = 0,
    found = 0,
    fname = "file: " + s.fname,
    matches = 0;

  ar = [ar];

  newlines = s.new_lines (ar, s.patstr);
  s.numchanges = 0;

  while (i < length (ar))
    {
    if (i + newlines > length (ar) - 1)
      break;

    s.lnronfile = lnronfile + i;

    str = strjoin (ar[[i:i+newlines]], newlines ? "\n" : "");

    found = pcre_exec (s.pat, str, 0);

    if (found)
      {
      matches++;
      finished = "";
      do
        {
        % CHECK IF PCRE return chars or bytes
        match = pcre_nth_match (s.pat, 0);
        fpart = substr (str, 1, match[0]);
        context = substr (str, match[0] + 1, match[1] - match[0]);
        lpart = substr (str, match[1] + 1, -1);

        replace = "";

        _for ia (0, length (s.substlist) - 1)
          {
          chr = s.substlist[ia];
          type = typeof (chr);

          switch (type)
            {
            case Integer_Type :
              if (found - 1 < chr)
                return "Captured substrings are less than the requested", NULL;
              else
                replace += pcre_nth_substr (s.pat, str, chr);
            }

            {
            case String_Type :
              if (chr == "&")
                replace += context;
              else
                replace += chr;
            }

            {
            case Null_Type :
              replace += "&";
            }

          }

        if (s.askwhensubst)
          {
          variable
            lfpart = strreplace (fpart, "\n", "\\n"),
            lcontext = strreplace (context, "\n", "\\n"),
            llpart = strreplace (lpart, "\n", "\\n"),
            lreplace = strreplace (replace, "\n", "\\n");

          retval = s.askonsubst (fname, s.lnronfile, lfpart, lcontext, llpart, lreplace);

           switch (retval)

             {
             case 'n': break;
             }

             {
             case 'a': s.askwhensubst = 0;
             }

             {
             case 'q':
               if (s.numchanges)
                 return ar, 0;
               else
                 return 1;
             }

             {
             case 'c':
               return 1;
             }
          }

        finished += sprintf ("%s%s", fpart, replace);
        str = lpart;
        s.numchanges++;
        }
      while (found = pcre_exec (s.pat, str, 0), found && s.global);

      tok = strtok (sprintf ("%s%s", finished, str), "\n");

      if (i)
        ar = [ar[[:i-1]], tok, ar[[i+1+newlines:]]];
      else
        ar = [tok, ar[[i+1+newlines:]]];

      if (NULL == s.global)
        return ar, 0;

      i += length (tok);
      continue;
      }

    i++;
    }

  ifnot (s.numchanges)
    return 1;

  ar, 0;
}
