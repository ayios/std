loadfrom ("crypt", "cryptInit", NULL, &on_eval_err);
loadfrom ("rand", "randInit", NULL, &on_eval_err);

ifnot (is_defined ("SMGINITED"))
  loadfrom ("os", "getpasswd", NULL, &on_eval_err);
else
  loadfrom ("os", "smg_getpasswd", NULL, &on_eval_err);

static define encryptpasswd (passwd)
{
  passwd = NULL == passwd ? getpasswd () : passwd;

  variable data = rand->getstr ('0', 'z', 40);

  return crypt->encrypt (data, passwd);
}

static define confirmpasswd (data)
{
  variable passwd = getpasswd ();
 
  return crypt->decrypt (data, passwd);
}

static define authenticate (user, passwd)
{
  return auth (user, passwd);
}
