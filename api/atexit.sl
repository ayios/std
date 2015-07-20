define at_exit ()
{
  variable f;

  if (any ("input" == _get_namespaces ()))
    {
    f = __get_reference ("input->at_exit");
    (@f);
    }

  if (any ("smg" == _get_namespaces ()))
    {
    f = __get_reference ("smg->reset");
    (@f);
    }
}
