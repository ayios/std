define _messages_ (argv)
{
  variable ved = @VED_CB;

  viewfile (ERR_VED, "MSG", NULL, NULL);
 
  variable f = __get_reference ("setbuf");
  
  VED_CB = ved;

  (@f) (VED_CB._absfname);
  VED_CB.draw ();
}

