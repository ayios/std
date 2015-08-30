private variable SUSPENDSTATE = 0;

private define set_basic_color (field, color)
{
  variable colors =
    [
    "white", "red", "green", "brown", "blue", "magenta",
    "cyan", "lightgray", "gray", "brightred", "brightgreen",
    "yellow", "brightblue", "brightmagenta", "brightcyan",
    "blackongray", "blackonwhite", "blackonred", "blackonbrown",
    "blackonyellow", "brownonyellow", "brownonwhite", "blackongreen",
    "blackoncyan",
    ];

  set_struct_field (COLOR, field, wherefirst (colors == color));
}

array_map (Void_Type, &set_basic_color,
  ["normal", "error", "success", "warn", "prompt",
   "border", "focus", "hlchar",   "hlregion", "topline",
   "infofg", "infobg", "diffpl", "diffmn", "visual"
  ],
  [COLOR.normal, COLOR.error, COLOR.success, COLOR.warn,
   COLOR.prompt, COLOR.border, COLOR.focus, COLOR.hlchar,
   COLOR.hlregion, COLOR.topline, COLOR.infofg, COLOR.infobg,
   COLOR.diffpl, COLOR.diffmn, COLOR.visual]);

array_map (Void_Type, &slsmg_define_color, [0:14:1],
  [
  "white", "red", "green", "brown", "blue", "magenta",
  "cyan", "lightgray", "gray", "brightred", "brightgreen",
  "yellow", "brightblue", "brightmagenta", "brightcyan"
  ], "black");

array_map (Void_Type, &slsmg_define_color, [15:19:1],
  "black", array_map (String_Type, &substr,
  ["blackongray", "blackonwhite", "blackonred", "blackonbrown",
  "blackonyellow"], 8, -1));

array_map (Void_Type, &slsmg_define_color, [20:21:1],
  "brown", array_map (String_Type, &substr,
  ["brownonyellow", "brownonwhite"], 8, -1));

array_map (Void_Type, &slsmg_define_color, [22:23:1],
  "black", array_map (String_Type, &substr,
  ["blackongreen", "blackoncyan"], 8, -1));
  
static define get_color (clr)
{
  return get_struct_field (COLOR, clr);
}

static define refresh ()
{
  slsmg_refresh ();
}

static define init ()
{
  if (SMGINITED)
    return;

  slsmg_init_smg ();
  SMGINITED = 1;
}

static define reset ()
{
  ifnot (SMGINITED)
    return;

  slsmg_reset_smg ();
  SMGINITED = 0;
}

static define suspend ()
{
  if (SUSPENDSTATE)
    return;

  slsmg_suspend_smg ();
  SUSPENDSTATE = 1;
}

static define resume ()
{
  ifnot (SUSPENDSTATE)
    return;

  slsmg_resume_smg ();
  SUSPENDSTATE = 0;
}

static define setrc (row, col)
{
  slsmg_gotorc (row, col);
}

static define setrcdr (row, col)
{
  slsmg_gotorc (row, col);
  slsmg_refresh ();
}

static define getrc (row, col)
{
  return [slsmg_get_row (), slsmg_get_column ()];
}

static define char_at ()
{
  return slsmg_char_at ();
}

static define hlregion (clr, r, c, dr, dc)
{
  slsmg_set_color_in_region (clr, r, c, dr, dc);
}

static define hlregiondr (clr, r, c, dr, dc)
{
  slsmg_set_color_in_region (clr, r, c, dr, dc);
  slsmg_refresh ();
}

static define cls ()
{
  slsmg_cls ();
}

static define addnstr (str, len)
{
  slsmg_write_nstring (str, len);
}

static define addnstrdr (str, len, nr, nc)
{
  slsmg_write_nstring (str, len);
  slsmg_gotorc (nr, nc);
  slsmg_refresh ();
}

static define atrcaddnstr (str, clr, row, col, len)
{
  slsmg_gotorc (row, col);
  slsmg_set_color (clr);
  slsmg_write_nstring (str, len);
}

static define atrcaddnstrdr (str, clr, row, col, nr, nc, len)
{
  atrcaddnstr (str, clr, row, col, len);
  slsmg_gotorc (nr, nc);
  slsmg_refresh ();
}

static define aratrcaddnstr (ar, clrs, rows, cols, len)
{
  array_map (Void_Type, &atrcaddnstr, ar, clrs, rows, cols, len);
}

static define aratrcaddnstrdr (ar, clrs, rows, cols, nr, nc, len)
{
  array_map (Void_Type, &atrcaddnstr, ar, clrs, rows, cols, len);
  slsmg_gotorc (nr, nc);
  slsmg_refresh ();
}

static define eraseeol ()
{
  slsmg_erase_eol ();
}

static define atrceraseeol (row, col)
{
  slsmg_gotorc (row, col);
  slsmg_erase_eol ();
}

static define atrceraseeoldr (row, col)
{
  atrceraseeol (row, col);
  slsmg_refresh ();
}

static define set_img (lines)
{
  variable i;
 
  SMGIMG = List_Type[lines];
 
  _for i (0, length (SMGIMG) - 1)
    SMGIMG[i] = {" ", 0, i, 0};
}

static define restore (r, ptr, refresh)
{
  variable len = length (r);
  variable ar = String_Type[0];
  variable rows = Integer_Type[0];
  variable clrs = Integer_Type[0];
  variable cols = Integer_Type[0];
  variable columns = qualifier ("columns", COLUMNS);
  variable i;

  _for i (0, len - 1)
    {
    ar = [ar, SMGIMG[r[i]][0]];
    clrs = [clrs, SMGIMG[r[i]][1]];
    rows = [rows, SMGIMG[r[i]][2]];
    cols = [cols, SMGIMG[r[i]][3]];
    }

  aratrcaddnstr (ar, clrs, rows, cols, columns);

  ifnot (NULL == ptr)
    smg->setrc (ptr[0], ptr[1]);

  ifnot (NULL == refresh)
    smg->refresh ();
}

