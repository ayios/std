private variable width;
private variable initblocks = 0;
private variable shiftwidth = NULL;

variable BLOCKS = Assoc_Type[String_Type];

private define _blocks_ (lshiftwidth)
{
  if (initblocks)
    if (lshiftwidth == shiftwidth)
      return;
    else
      shiftwidth = lshiftwidth;
  else
    shiftwidth = lshiftwidth;

  width = repeat (" ", shiftwidth);

  BLOCKS["if else"] =
    width + "if ()\n" + width + "\n" + width + "else\n" + width;

  BLOCKS["if else_if else"] =
    width + "if ()\n" + width + "\n" + width + "elseif\n" + width + "else if\n" + width;
  
  initblocks = 1;
}

private define sl_complete_blocks (s, line)
{
  _blocks_ (s._shiftwidth);
}

define sl_init_compl (s)
{
  shiftwidth = s._shiftwidth;
}
