private variable gbt;

private define get_int (fd)
{
  () = read (fd, &gbt, 32);
  eval (gbt);
}

private define send_int (fd, i)
{
  () = write (fd, sprintf ("%S", i));
}

private define get_str (fd)
{
  () = read (fd, &gbt, 16384);
  gbt;
}

private define send_str (fd, str)
{
  () = write (fd, str);
}

private define get_str_ar (rdfd, wrfd)
{
  gbt = get_int (rdfd);
  send_int (wrfd, 0);
  () = read (rdfd, &gbt, gbt);
  strchop (gbt, '\n', 0);
}

private define send_str_ar (rdfd, wrfd, str_ar)
{
  str_ar = strjoin (str_ar, "\n");
  send_int (wrfd, int (sum (strbytelen (str_ar))));
  () = get_int (rdfd);
  () = write (wrfd, str_ar);
}

private define get_int_ar (rdfd, wrfd)
{
  gbt = get_int (rdfd);
  send_int (wrfd, 1);
  () = read (rdfd, &gbt, gbt);
  eval (gbt);
}

private define send_int_ar (rdfd, wrfd, int_ar)
{
  int_ar = "[" + strjoin (array_map (String_Type, &string, int_ar), ",") + "];";
  send_int (wrfd, int (sum (strbytelen (int_ar))));
  () = get_int (rdfd);
  () = write (wrfd, int_ar);
}

__.new ("Sock";methods = "send_int,get_int,send_str,get_str," +
  "send_int_ar,get_int_ar,send_str_ar,get_str_ar",
  funcs = ["send_int__", "get_int_", "send_str__", "get_str_",
   "send_int_ar___", "get_int_ar__", "send_str_ar___", "get_str_ar__"],
  refs = [&send_int, &get_int, &send_str, &get_str,
   &send_int_ar, &get_int_ar, &send_str_ar, &get_str_ar]);
