private variable BLOCKS = Assoc_Type[String_Type];

define sl_blocks (swi, col)
{
  variable sw = repeat (" ", swi);
  variable tw = repeat (" ", swi + col);
  variable iw = repeat (" ", col);
 
  BLOCKS["if else"] = iw + "if ()\n" + tw + "\n" + iw + "else\n" + tw;

  BLOCKS["if else_if else"] =
    iw + "if ()\n" + tw + "\n" + iw + "else if\n" + tw + "\n" + iw + "else\n" + tw;

  BLOCKS["_for i (0, length (ar) - 1)"] = iw + "for i (0, length (ar) - 1)";

  BLOCKS["private define"] = "private define ()\n{\n" + sw + "\n}";

  return BLOCKS;
}

define sl_autoindent (s, line)
{
  if (line == "}")
    return s._indent;

  variable indent = strlen (line) - strlen (strtrim_beg (line));
  variable lc = line[-1];

  if (any (lc == [';', ',']))
    {
    if (lc == ',')
      {
      variable ar = ["private", "variable"];
      variable ln = strlen (ar);

      if (any (0 == array_map (Integer_Type, &strncmp, line, ar, ln)))
        indent+= s._shiftwidth;
      }

    return indent;
    }

  return indent + s._shiftwidth;
}
