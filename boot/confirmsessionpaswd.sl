loadfrom ("crypt", "cryptInit", NULL, &on_eval_err);

static define confirmsessionpaswd (data)
{
  variable passwd = "";
  variable prompt = "Confirm Session password: ";

  smg->atrcaddnstrdr (prompt, 0,  0, 0, 0, strlen (prompt), LINES);

  variable chr = 0;

  while (chr = getch (), chr != '\r')
    {
    if (keys->BACKSPACE && strlen (passwd))
      passwd = substr (passwd, 1, strlen (passwd) - 1);
    else
      passwd += char (chr);
    }
 
  return crypt->decrypt (data, passwd);
}
