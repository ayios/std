loadfrom ("crypt", "cryptInit", NULL, &on_eval_err);
loadfrom ("rand", "randInit", NULL, &on_eval_err);

static define getsessionhashpaswd ()
{
  variable passwd = "";
  variable prompt = "Session password: ";
  variable chr = 0;

  smg->atrcaddnstrdr (prompt, 0,  0, 0, 0, strlen (prompt) , LINES);

  while (chr = getch (), chr != '\r')
    {
    if (keys->BACKSPACE && strlen (passwd))
      passwd = substr (passwd, 1, strlen (passwd) - 1);
    else
      passwd += char (chr);
    }
 
  variable data = rand->getstr ('0', 'z', 40);

  return crypt->encrypt (data, passwd);
}
