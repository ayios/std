private define _ask_ (s, fn, lnr, fpart, context, lpart, replace)
{
  variable f = __get_reference ("ask");
  return (@f) (["@" + fn + " linenr: " + string (lnr+1),
     "replace?",
     repeat ("_", COLUMNS),
     sprintf ("%s%s%s", fpart, context, lpart),
     repeat ("_", COLUMNS),
     "with?",
     repeat ("_", COLUMNS),
     sprintf ("%s%s%s", fpart, replace, lpart),
     repeat ("_", COLUMNS),
     "y[es replace]",
     "n[o  dont replace]",
     "q[uit all the replacements]",
     "a[ll replace all, dont ask again for this file]"],
     ['y', 'n', 'q', 'a']; hl = [
       struct {color = 1, row = 5, col = strlen (fpart), dr = 1, dc = strlen (context)},
       struct {color = 2, row = 9, col = strlen (fpart), dr = 1, dc = strlen (replace)}]);
}

private define find_new_lines (ar, pat)
{
  variable i;
  variable newlines = 0;

  _for i (1, strlen (pat) - 1)
    if ('n' == pat[i] && '\\' == pat[i - 1])
      newlines++;

  return newlines;
}

private define assign_substitute (substitution)
{
  variable
    sub,
    i = 1,
    list = {},
    len = strlen (substitution);

  while (i <= len)
    {
    sub = substr (substitution, i, 1);

    if (sub == "\\")
      {
      sub = substr (substitution, i + 1, 1);
      i += 2;

      if (__is_datatype_numeric (_slang_guess_type (sub)))
        {
        list_append (list, integer (sub));
        continue;
        }

      switch (sub)
        {
        case "\\" :
          list_append (list, "\\");
        continue;
        }

        {
        case "n" :
          list_append (list, "\n");
        continue;
        }

        {
        case "t" :
          list_append (list, "\t");
        continue;
        }
 
        {
        case "s" :
          list_append (, " ");
        continue;
        }

        {
        throw ParseError, "Waiting one of \"t,n,s,\\,integer\" after the backslash";
        }
      }

    list_append (list, sub);
    i++;
    }

  return list;
}

static define search_and_replace (s, ar)
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
    lnronfile = NULL == s.lnronfile ? 0 : s.lnronfile,
    i = 0,
    found = 0,
    fname = NULL == s.fname ? "" : "file:" + s.fname,
    matches = 0;

  ar = [ar];

  s.newlines = find_new_lines (ar, s.patstr);
  s.numchanges = 0;

  while (i < length (ar))
    {
    if (i + s.newlines > length (ar) - 1)
      break;
 
    s.lnronfile = lnronfile + i;    
      
    str = strjoin (ar[[i:i+s.newlines]], s.newlines ? "\n" : "");
 
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
          }

        if (s.askwhensubst)
          {
          variable
            lfpart = strreplace (fpart, "\n", "\\n"),
            lcontext = strreplace (context, "\n", "\\n"),
            llpart = strreplace (lpart, "\n", "\\n"),
            lreplace = strreplace (replace, "\n", "\\n");
          
          retval = s.ask (fname, s.lnronfile, lfpart, lcontext, llpart, lreplace);

           switch (retval)

             {
             case 'n': break;
             }

             {
             case 'a': s.askwhensubst = 1;
             }

             {
             case 'q':
               if (s.numchanges)
                 return ar, 0;
               else
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
        ar = [ar[[:i-1]], tok, ar[[i+1+s.newlines:]]];
      else
        ar = [tok, ar[[i+1+s.newlines:]]];

      if (NULL == s.global)
        return ar, 0;

      i += length (tok);
      continue;
      }

    i++;
    }

  ifnot (s.numchanges)
    return 1;

  return ar, 0;
}

static define init (pat, sub)
{
  variable s = @Search_Type;
 
  try
    {
    s.pat = pcre_compile (pat, qualifier ("pcreopts", 0));
    s.substlist = assign_substitute (sub);
    }
  catch ParseError:
    return __get_exception_info.message, NULL;

  s.numchanges = 0;
  s.patstr = pat;
  s.global = qualifier ("global");
  s.askwhensubst = qualifier ("askwhensubst", 1);
  s.ask = &_ask_;

  return s;
}
