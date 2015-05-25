private variable CRYPTO_DEFAULT_SYMETRIC = "aes-256-cbc";
private variable CRYPTO_DEFAULT_DIGEST = "md5";
private variable CRYPTO_DEFAULT_ROUNDS = 1;

static define encrypt (data, pass)
{
  variable key, iv;
  variable alg = CRYPTO_DEFAULT_SYMETRIC;
  variable md = CRYPTO_DEFAULT_DIGEST;
  variable rounds = CRYPTO_DEFAULT_ROUNDS;

  variable salt = pack("I2", rand->rand (2));
  (key, iv) = _genkeyiv (pass, salt, rounds, alg, md);

  variable out = _encrypt (data, key, iv, alg);
  out = "Salted__" + salt + out;
  return out;
}

static define decrypt (data, pass)
{
  variable key, iv;
  variable alg = CRYPTO_DEFAULT_SYMETRIC;
  variable md = CRYPTO_DEFAULT_DIGEST;
  variable rounds = CRYPTO_DEFAULT_ROUNDS;
  variable salt = "";
  variable dstart = 0;
  if (data[[0:7]] == "Salted__")
    {
    salt=data[[8:15]];
	  dstart=16;
    }
 
  (key, iv)=_genkeyiv (pass, salt, rounds, alg, md);
 
  variable out = _decrypt (data[[dstart:]], key, iv, alg);
 
  return out;
}
