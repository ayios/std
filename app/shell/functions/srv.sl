private variable issmg = 0;

private define _ask_ (p, cmp_lnrs, wrfd, rdfd)
{
  variable i;
  variable ocmp_lnrs = @cmp_lnrs;
  
  sock->send_bit (wrfd, 1);
  
  variable str = sock->get_str (rdfd);

  () = widg->askprintstr (str, NULL, &cmp_lnrs);
  
  sock->send_bit (wrfd, 1);

  if (length (cmp_lnrs) < length (ocmp_lnrs))
    {
    _for i (0, length (ocmp_lnrs) - 1)
      ifnot (any (ocmp_lnrs[i] == cmp_lnrs))
        ocmp_lnrs[i] = -1;

    ocmp_lnrs = ocmp_lnrs[wherenot (ocmp_lnrs == -1)];
    smg->restore (ocmp_lnrs, NULL, 1);
    }

  return cmp_lnrs;
}

private define _sendmsgdr_ (p, wrfd, rdfd)
{
  sock->send_bit (wrfd, 1);
  
  variable str = sock->get_str (rdfd);
  
  send_msg_dr (str, 0, NULL, NULL); 

  sock->send_bit (wrfd, 1);
}

private define _restorestate_ (p, cmp_lnrs, wrfd)
{
  if (length (cmp_lnrs))
    smg->restore (cmp_lnrs, NULL, 1);
 
  sock->send_bit (wrfd, 1);
}

define waitfunc (p, wrfd, rdfd)
{
  variable buf;
  variable cmp_lnrs = Integer_Type[0];

  issmg = 0;

  forever
    {
    buf = sock->get_str (rdfd);
    buf = strtrim_end (buf);
    
    if ("exit" == buf)
      return;
    
    if ("restorestate" == buf)
      {
      _restorestate_ (p, cmp_lnrs, wrfd);
      continue;
      }
    
    if ("send_msg_dr" == buf)
      {
      _sendmsgdr_ (p, wrfd, rdfd);
      continue;
      }

    if ("ask" == buf)
      {
      cmp_lnrs = _ask_ (p, cmp_lnrs, wrfd, rdfd);
      continue;
      }

    if ("close_smg" == buf)
      {
      ifnot (issmg)
        {
        smg->suspend ();
        issmg = 1;
        }

      sock->send_bit (wrfd, 1);
      continue;
      }

    if ("restore_smg" == buf)
      {
      if (issmg)
        {
        smg->resume ();
        issmg = 0;
        }

      sock->send_bit (wrfd, 1);
      continue;
      }
    }
}
