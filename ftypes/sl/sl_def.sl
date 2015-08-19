private variable BLOCKS = Assoc_Type[String_Type];

define sl_blocks (swi, col)
{
  variable sw = repeat (" ", swi);
  variable tw = repeat (" ", swi + col);
  variable iw = repeat (" ", col);
    
  BLOCKS["if else"] = iw + "if ()\n" + tw + "\n" + iw + "else\n" + tw;

  BLOCKS["if else_if else"] =
    iw + "if ()\n" + tw + "\n" + iw + "else if\n" + tw + "\n" + iw + "else\n" + tw;

  BLOCKS["for i (0, length (ar) - 1)"] = iw + "for i (0, length (ar) - 1)";

  BLOCKS["private define"] = "private define ()\n{\n" + sw + "\n}";

  return BLOCKS;
}
