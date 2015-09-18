public variable SMGINITED = 0;
public variable SMGIMG;
public variable LINES;
public variable COLUMNS;
public variable PROMPTROW;
public variable MSGROW;

importfrom ("std", "slsmg", "smg", &on_eval_err);

loadfrom ("colors", "colorsInit", NULL, &on_eval_err);
loadfrom ("smg",  "smginit", 1, &on_eval_err);
loadfrom ("smg",  "getscreensize", NULL, &on_eval_err);

smg->SLsmg_Tab_Width = 1;
(LINES, COLUMNS) = getscreensize ();
PROMPTROW = LINES - 2;
MSGROW = LINES - 1;

loadfrom ("smg", "functions", NULL, &on_eval_err);
loadfrom ("os", "getpasswd", NULL, &on_eval_err);

array_map (Void_Type, &set_struct_field, COLOR, get_struct_field_names (COLOR),
  array_map (Integer_Type, &smg->get_color, get_struct_field_names (COLOR)));

smg->init ();
smg->set_img (LINES - 2);
