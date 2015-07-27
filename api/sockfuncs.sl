define send_int (fd, i)
{
  sock->send_int (fd, i);
}

define get_int (fd)
{
  return sock->get_int (fd);
}

define send_str (fd, str)
{
  sock->send_str (fd, str);
}
