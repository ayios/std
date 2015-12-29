private define assign (substitution)
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
          list_append (list, " ");
          continue;
        }

        {
        case "&" :
          list_append (list, NULL);
          continue;
        }

        {
        throw ParseError, "Waiting one of \"t,n,s,&,\\,integer\" after the backslash";
        }
      }

    list_append (list, sub);
    i++;
    }

  list;
}
