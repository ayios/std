private define set_basic_color (field, color)
{
  variable colors =
    [
    "white", "red", "green", "brown", "blue", "magenta",
    "cyan", "lightgray", "gray", "brightred", "brightgreen",
    "yellow", "brightblue", "brightmagenta", "brightcyan",
    "blackongray", "blackonwhite", "blackonred", "blackonbrown",
    "blackonyellow", "brownonyellow", "brownonwhite"
    ];

  set_struct_field (COLOR, field, wherefirst (colors == color));
}

array_map (Void_Type, &set_basic_color,
  ["normal", "error", "success", "warn", "prompt",
   "border", "focus", "hlchar", "infoline", "activeframe",
   "hlregion", "topline"],
  [COLOR.normal, COLOR.error, COLOR.success, COLOR.warn,
   COLOR.prompt, COLOR.border, COLOR.focus, COLOR.hlchar,
   COLOR.infoline, COLOR.activeframe, COLOR.hlregion,
   COLOR.topline]);

array_map (Void_Type, &slsmg_define_color, [0:14:1],
  [
  "white", "red", "green", "brown", "blue", "magenta",
  "cyan", "lightgray", "gray", "brightred", "brightgreen",
  "yellow", "brightblue", "brightmagenta", "brightcyan"
  ],
  "black");

array_map (Void_Type, &slsmg_define_color, [15:19:1],
  "black",
  array_map (String_Type, &substr,
  [
  "blackongray", "blackonwhite", "blackonred", "blackonbrown",
  "blackonyellow",
  ], 8, -1)
  );

array_map (Void_Type, &slsmg_define_color, [20:21:1],
  "brown",
  array_map (String_Type, &substr,
  [
  "brownonyellow", "brownonwhite",
  ], 8, -1)
  );

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
  slsmg_init_smg ();
}

static define reset ()
{
  slsmg_reset_smg ();
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
  () = fprintf (stderr, "%S\n", str);
  () = fprintf (stderr, "%S\n", getenv ("TERM"));
  () = fflush (stderr);
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
