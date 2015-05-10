loadfile ("initfunctions", NULL, &on_eval_err);
loadfile ("sl_settype", NULL, &on_eval_err);

set_img ();

private define _vedloop_ (s)
{
  forever
    {
    count = -1;
    cf_._chr = getch ();
 
    if ('1' <= cf_._chr <= '9')
      {
      count = "";
 
      while ('0' <= cf_._chr <= '9')
        {
        count += char (cf_._chr);
        cf_._chr = getch ();
        }

      count = integer (count);
      }

    if (any (pagerc == cf_._chr))
      (@pagerf[string (cf_._chr)]);
 
    if (':' == cf_._chr)
      rlf_.read ();

    if (cf_._chr == 'q')
      (@clinef["q"]) (;force);
    }
}

vedloop = &_vedloop_;

define ved (s, fname, rows)
{
  sl_settype (s, fname, rows, NULL);

  cf_ = s;
 
  set_img ();
  write_prompt (" ", 0);

  s.draw ();

  variable func = get_func ();

  if (func)
    {
    count = get_count ();
    if (any (pagerc == func))
      (@pagerf[string (func)]);
    }

  if (DRAWONLY)
    return;
 
  topline_dr (" -- PAGER --");

  (@vedloop) (s);
}
