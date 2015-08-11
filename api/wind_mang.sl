define wind_mang (s)
{
  (@__get_reference ("handle_w")) (get_cur_buf ());
  rline->set (s);
  rline->prompt (s, s._lin, s._col);
}
