load.module ("std", "slsmg", NULL;err_handler = &__err_handler__);

public variable LINES     = SLsmg_Screen_Rows;
public variable COLUMNS   = SLsmg_Screen_Cols;
public variable PROMPTROW = SLsmg_Screen_Rows - 2;
public variable MSGROW    = SLsmg_Screen_Rows - 1;
public variable COLOR = struct
  {
  normal = "white",
  error = "brightred",
  success = "brightgreen",
  warn = "brightmagenta",
  prompt = "yellow",
  border = "brightred",
  focus = "brightcyan",
  hlchar = "blackonyellow",
  hlregion = "white",
  topline = "blackonbrown",
  infofg = "blue",
  infobg = "brown",
  diffpl = "blackongreen",
  diffmn = "blackoncyan",
  visual = "blackonbrown",
  };

static variable IMG;

SLsmg_Tab_Width = 1;

private variable SMGINITED = 0;
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

private define get_color (clr)
{
  get_struct_field (COLOR, clr);
}

array_map (Void_Type, &set_struct_field, COLOR, get_struct_field_names (COLOR),
  array_map (Integer_Type, &get_color, get_struct_field_names (COLOR)));

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
  [slsmg_get_row (), slsmg_get_column ()];
}

static define char_at ()
{
  slsmg_char_at ();
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
  setrcdr (nr, nc);
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
  setrcdr (nr, nc);
}

static define aratrcaddnstr (ar, clrs, rows, cols, len)
{
  array_map (Void_Type, &atrcaddnstr, ar, clrs, rows, cols, len);
}

static define aratrcaddnstrdr (ar, clrs, rows, cols, nr, nc, len)
{
  array_map (Void_Type, &atrcaddnstr, ar, clrs, rows, cols, len);
  setrcdr (nr, nc);
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

static define set_img (lines, ar, clrs, cols)
{
  variable i;

  if (NULL == clrs)
    {
    clrs = Integer_Type[length (lines)];
    clrs[*] = 0;
    }

  if (NULL == cols)
    {
    cols = Integer_Type[length (lines)];
    cols[*] = 0;
    }

  if (NULL == ar)
    {
    ar = String_Type[length (lines)];
    ar[*] = " ";
    }

  _for i (0, length (lines) -1)
    IMG[lines[i]] = {ar[i], clrs[i], lines[i], cols[i]};
}

static define restore (r, ptr, redraw)
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
    ar = [ar, IMG[r[i]][0]];
    clrs = [clrs, IMG[r[i]][1]];
    rows = [rows, IMG[r[i]][2]];
    cols = [cols, IMG[r[i]][3]];
    }

  aratrcaddnstr (ar, clrs, rows, cols, columns);

  ifnot (NULL == ptr)
    setrc (ptr[0], ptr[1]);

  ifnot (NULL == redraw)
    refresh ();
}

public define send_msg_dr (str, clr, row, col)
{
  variable
    lcol = NULL == col ? strlen (str) : col,
    lrow = NULL == row ? MSGROW : row;

  atrcaddnstrdr (str, clr, MSGROW, 0, lrow, lcol, COLUMNS);
}

public define send_msg (str, clr)
{
  atrcaddnstr (str, clr, MSGROW, 0, COLUMNS);
}

init ();

IMG = List_Type[LINES - 2];
set_img ([0:LINES - 3], NULL, NULL, NULL);
