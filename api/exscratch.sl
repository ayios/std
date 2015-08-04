define scratch (argv)
{
  variable ved = @get_cur_buf ();

  viewfile (SCRATCH_VED, "SCRATCH", [1, 0], 0);

  variable f = __get_reference ("setbuf");
 
  (@f) (ved._absfname);
  ved.draw ();
}

define _scratch_ (ved)
{
  if (qualifier_exists ("draw") && qualifier ("draw") == 0)
    return;

  viewfile (SCRATCH_VED, "SCRATCH", [1, 0], 0);

  variable f = __get_reference ("setbuf");
 
  (@f) (ved._absfname);
  ved.draw ();
}

