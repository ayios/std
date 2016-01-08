define at_exit ()
{
  variable f;
  variable nss = _get_namespaces ();

  if (any ("input" == nss))
    {
    f = __get_reference ("input->at_exit");
    (@f);
    }

  if (any ("smg" == nss))
    {
    f = __get_reference ("smg->reset");
    (@f);
    }
}
