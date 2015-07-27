define scratch (argv)
{
  variable ved = @VED_CB;

  viewfile (SCRATCH_VED, "SCRATCH", [1, 0], 0);

  variable f = __get_reference ("setbuf");
 
  VED_CB = ved;

  (@f) (VED_CB._absfname);
  VED_CB.draw ();
}

define _scratch_ (ved)
{
  if (qualifier_exists ("draw") && qualifier ("draw") == 0)
    return;

  viewfile (SCRATCH_VED, "SCRATCH", [1, 0], 0);

  variable f = __get_reference ("setbuf");
 
  VED_CB = ved;

  (@f) (VED_CB._absfname);
  VED_CB.draw ();
}
