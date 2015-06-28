loadfrom ("crypt", "cryptInit", NULL, &on_eval_err);
loadfrom ("rand", "randInit", NULL, &on_eval_err);

static define getpasswd ()
{
  variable passwd = "";
  variable prompt = "password: ";
  variable chr;

  smg->atrcaddnstrdr (prompt, 0, PROMPTROW, 0, PROMPTROW, strlen (prompt), COLUMNS);

  while (chr = getch (), chr != '\r')
    {
    if (chr == keys->BACKSPACE && strlen (passwd))
      passwd = substr (passwd, 1, strlen (passwd) - 1);
    else
      passwd+= char (chr);
    }
 
  return passwd;
}

static define encryptpasswd (passwd)
{
  passwd = NULL == passwd ? getpasswd () : passwd;

  variable data = rand->getstr ('0', 'z', 40);

  return crypt->encrypt (data, passwd);
}

static define confirmpasswd (data)
{
  variable passwd = "";
  variable prompt = "password: ";

  smg->atrcaddnstrdr (prompt, 0, PROMPTROW, 0, PROMPTROW, strlen (prompt) , COLUMNS);

  variable chr;

  while (chr = getch (), chr != '\r')
    {
    if (chr == keys->BACKSPACE && strlen (passwd))
      passwd = substr (passwd, 1, strlen (passwd) - 1);
    else
      passwd += char (chr);
    }
 
  return crypt->decrypt (data, passwd);
}
