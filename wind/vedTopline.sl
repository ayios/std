loadfrom ("string", "repeat", NULL, &on_eval_err);
loadfrom ("wind", "topline", NULL, &on_eval_err);

define topline (str)
{
  str += sprintf (" ftype (%s) LANG (%s) ", VED_CB._type,
    input->getmapname ());

  _topline_ (&str, COLUMNS);
  smg->atrcaddnstr (str, 16, 0, 0, COLUMNS);
}

define toplinedr (str)
{
  str += sprintf (" ftype (%s) LANG (%s) ", VED_CB._type,
    input->getmapname ());

  _topline_ (&str, COLUMNS);
  smg->atrcaddnstrdr (str, 16, 0, 0, VED_CB.ptr[0], VED_CB.ptr[1], COLUMNS);
}
