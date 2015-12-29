private define askonsubst (fn, lnr, fpart, context, lpart, replace)
{
  variable f = __get_reference ("ask");
  variable char_ar =  ['y', 'n', 'q', 'a', 'c'];
  variable hl_reg = Array_Type[2];
  variable ar =
    ["@" + fn + " linenr: " + string (lnr+1),
     "replace?",
     repeat ("_", COLUMNS),
     sprintf ("%s%s%s", fpart, context, lpart),
     repeat ("_", COLUMNS),
     "with?",
     repeat ("_", COLUMNS),
     sprintf ("%s%s%s", fpart, replace, lpart),
     repeat ("_", COLUMNS),
     "y[es]/n[o]/q[uit]/a[ll]/c[ansel]"];

  hl_reg[0] = [5, LINES - 10, strlen (fpart), 1, strlen (context)];
  hl_reg[1] = [2, LINES - 6, strlen (fpart), 1, strlen (replace)];

  (@f) (ar, char_ar;hl_region = hl_reg);
}
