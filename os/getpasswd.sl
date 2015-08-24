define getpasswd ()
{
  variable passwd = "";
  variable prompt = "password:";
  variable chr;

  smg->atrcaddnstrdr (prompt, 0, MSGROW, 0, MSGROW, strlen (prompt), COLUMNS);

  while (chr = getch (), chr != '\r')
    {
    if (chr == keys->BACKSPACE && strlen (passwd))
      passwd = substr (passwd, 1, strlen (passwd) - 1);
    else
      passwd+= char (chr);
    }
 
  send_msg (" ", 0);

  return passwd;
}
