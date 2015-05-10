variable lpagerf = Assoc_Type[Ref_Type];
variable lpagerc;

loadfile ("initfunctions", NULL, &on_eval_err);
loadfile ("listfuncs", NULL, &on_eval_err);

private define _vedloop_ (s)
{
  forever
    {
    count = -1;
    cf_._chr = getch ();
 
    if ('0' <= cf_._chr <= '9')
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

    if (any (lpagerc == cf_._chr))
      (@lpagerf[string (cf_._chr)]);
 
    if (':' == cf_._chr)
      rlf_.read ();

    if (cf_._chr == 'q')
      (@clinef["q"]) (;force);
    }
}

vedloop = &_vedloop_;
