loadfrom ("string", "repeat", NULL, &on_eval_err);
loadfrom ("wind", "topline", NULL, &on_eval_err);

define toplinedr (str)
{
  _topline_ (&str, COLUMNS);
  smg->atrcaddnstrdr (str, 2, 0, 0, mywind.ptr[0], mywind.ptr[1], COLUMNS);
}

define topline (str)
{
  _topline_ (&str, COLUMNS);
  smg->atrcaddnstr (str, 2, 0, 0, COLUMNS);
}
