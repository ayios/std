private define buf_fun (s, k)
{
  variable i = Assoc_Type[Integer_Type];
  i["len"] = 111;
  i["b"] = 333;
  return i[k];
}

private define void (s, arg)
{
  send_msg_dr (arg, 1, NULL, NULL);
}

private define init_buf ()
{
  return struct {f = &buf_fun, s = "string", v = &void};
}

