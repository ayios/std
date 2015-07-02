define getpasswd ()
{
  variable passwd = "";
  variable chr;
  
  () = fputs ("password: ", stdout);
  () = fflush (stdout);

  while (chr = getch (), chr != '\r')
    {
    if (chr == keys->BACKSPACE && strlen (passwd))
      passwd = substr (passwd, 1, strlen (passwd) - 1);
    else
      passwd+= char (chr);
    }
 
  return passwd;
}
