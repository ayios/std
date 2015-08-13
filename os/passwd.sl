loadfrom ("crypt", "cryptInit", NULL, &on_eval_err);

static define encryptpasswd (passwd)
{
  passwd = NULL == passwd ? getpasswd () : passwd;

  variable data = rand->getstr ('0', 'z', 40);

  return crypt->encrypt (data, passwd);
}

static define confirmpasswd (data, passwd)
{
  @passwd = getpasswd ();
 
  return crypt->decrypt (data, @passwd);
}

static define authenticate (user, passwd)
{
  return auth (user, passwd);
}
