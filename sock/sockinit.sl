private variable gbt;

static variable
 sock_f_s_srv = Assoc_Type[Ref_Type],
 sock_f_g_srv = Assoc_Type[Ref_Type],
 sock_f_s_clnt = Assoc_Type[Ref_Type],
 sock_f_g_clnt = Assoc_Type[Ref_Type];

%% get_bit Integer_Type [0-9] (fd)
static define get_bit (fd)
{
  return (read (fd, &gbt, 1), pop (), gbt[0] - '0');
}

%% send_bit Void_Type (fd, Integer_Type [0-9])
static define send_bit (fd, i)
{
  () = write (fd, sprintf ("%S", i));
}

%% get_int Integer_Type (fd)
static define get_int (fd)
{
  return (read (fd, &gbt, 16), pop (), eval (gbt));
}

%% send_int Void_Type (fd, Integer_Type)
static define send_int (fd, i)
{
  () = write (fd, sprintf ("%S", i));
}

%% get_str String_Type (fd)
static define get_str (fd)
{
  return (read (fd, &gbt, 4096), pop (), gbt);
}

%% send_str Void_Type (fd, String_Type)
static define send_str (fd, str)
{
  () = write (fd, str);
}

%% get_str_ar String_Type [] (fd)
static define get_str_ar (fd)
{
  gbt = get_int (fd);
  send_bit (fd, 0);
  return (read (fd, &gbt, gbt), pop (), strchop (gbt, '\n', 0));
}

%% send_str_ar Void_Type (fd, String_Type [])
static define send_str_ar (fd, str_ar)
{
  str_ar = strjoin (str_ar, "\n");
  send_int (fd, int (sum (strbytelen (str_ar))));
  () = get_bit (fd);
  () = write (fd, str_ar);
}

%% get_int_ar Integer_Type [] (fd)
static define get_int_ar (rdfd, wrfd)
{
  gbt = get_int (rdfd);
  send_bit (wrfd, 1);
  return (read (rdfd, &gbt, gbt), pop (), eval (gbt));
}

%% send_int_ar Void_Type (fd, Integer_Type[])
static define send_int_ar (rdfd, wrfd, int_ar)
{
  int_ar = "[" + strjoin (array_map (String_Type, &string, int_ar), ",") + "];";
  send_int (wrfd, int (sum (strbytelen (int_ar))));
  () = get_bit (rdfd);
  () = write (wrfd, int_ar);
}

%% get_bit_send_bit Integer_Type [0-9] (fd, Integer_Type [0-9])
static define get_bit_send_bit (fd, i)
{
  gbt = get_bit (fd);
  send_bit (fd, i);
  return gbt;
}

%% get_bit_send_int Integer_Type [0-9] (fd, Integer_Type)
static define get_bit_send_int (fd, i)
{
  gbt = get_bit (fd);
  send_int (fd, i);
  return gbt;
}

%% get_bit_send_str Integer_Type [0-9] (fd, String_Type)
static define get_bit_send_str (fd, str)
{
  gbt = get_bit (fd);
  send_str (fd, str);
  return gbt;
}

%% get_bit_send_int_ar Integer_Type (fd, Integer_Type[])
static define get_bit_send_int_ar (fd, int_ar)
{
  gbt = get_bit (fd);
  send_int_ar (fd, int_ar);
  return gbt;
}

%% get_bit_send_str_ar Integer_Type (fd, String_Type [])
static define get_bit_send_str_ar (fd, str_ar)
{
  gbt = get_bit (fd);
  send_str_ar (fd, str_ar);
  return gbt;
}

%% send_bit_get_bit Integer_Type [0-9] (fd, Integer_Type [0-9])
static define send_bit_get_bit (fd, i)
{
  send_bit (fd, i);
  return get_bit (fd);
}

%% send_bit_get_int Integer_Type (fd, Integer_Type [0-9])
static define send_bit_get_int (fd, i)
{
  send_bit (fd, i);
  return get_int (fd);
}

%% send_bit_get_str String_Type (fd, Integer_Type)
static define send_bit_get_str (fd, i)
{
  send_bit (fd, i);
  return get_str (fd);
}

%% send_bit_get_str_ar String_Type [] (fd, Integer_Type [0-9])
static define send_bit_get_str_ar (fd, i)
{
  send_bit (fd, i);
  return get_str_ar (fd);
}

%% send_bit_get_int_ar Integer_Type [] (fd, Integer_Type [0-9])
static define send_bit_get_int_ar (fd, i)
{
  send_bit (fd, i);
  return get_int_ar (fd);
}

%% get_int_send_bit Integer_Type (fd, Integer_Type)
static define get_int_send_bit (fd, i)
{
  gbt = get_int (fd);
  send_bit (fd, i);
  return gbt;
}

%% send_int_get_bit Integer_Type [0-9] (fd, Integer_Type)
static define send_int_get_bit (fd, i)
{
  send_int (fd, i);
  return get_bit (fd);
}

%% send_int_get_int Integer_Type [0-9] (fd, Integer_Type)
static define send_int_get_int (fd, i)
{
  send_int (fd, i);
  return get_int (fd);
}

%% get_str_send_bit String_Type (fd, Integer_Type[0-9])
static define get_str_send_bit (fd, i)
{
  gbt = get_str (fd);
  send_bit (fd, i);
  return gbt;
}

%% send_str_get_bit Integer_Type (fd, String_Type)
static define send_str_get_bit (fd, str)
{
  send_str (fd, str);
  return get_bit (fd);
}

%% get_int_ar_send_bit Integer_Type [] (fd, Integer_Type)
static define get_int_ar_send_bit (fd, i)
{
  gbt = get_int_ar (fd);
  send_bit (fd, i);
  return gbt;
}

%% send_int_ar_get_bit Integer_Type (fd, Integer_Type[])
static define send_int_ar_get_bit (fd, int_ar)
{
  send_int_ar (fd, int_ar);
  return get_bit (fd);
}

%% get_str_ar_send_bit String_Type [] (fd, Integer_Type [0-9])
static define get_str_ar_send_bit (fd, i)
{
  gbt = get_str_ar (fd);
  send_bit (fd, i);
  return gbt;
}

%% send_str_ar_get_bit Integer_Type (fd, String_Type [])
static define send_str_ar_get_bit (fd, str_ar)
{
  send_str_ar (fd, str_ar);
  return get_bit (fd);
}

%% send_str_ar_get_int Integer_Type (fd, String_Type [])
static define send_str_ar_get_int (fd, str_ar)
{
  send_str_ar (fd, str_ar);
  return get_int (fd);
}

%% get_struct Struct_Type (fd)
define get_struct (fd)
{
  variable
    i,
    type,
    field,
    fields,
    s = get_str_send_bit (fd, 0);

  s = eval (s);
  fields = get_struct_field_names (s);
  _for i (0, length (fields) - 1)
    {
    type = get_str_send_bit (fd, 0);
    if ("Null_Type" == type)
      continue;

    field = (@sock_f_g_srv[type]) (fd, 0);
    set_struct_field (s, fields[i], field);
    }

  return s;
}

%% send_struct Void_Type (fd, Struct_Type)
define send_struct (fd, s)
{
  variable
    i,
    type,
    field,
    fields = get_struct_field_names (s);
 
  () = send_str_get_bit (fd, sprintf ("struct {%s};", strjoin (fields, ",")));
 
  _for i (0, length (fields) - 1)
    {
    field = get_struct_field (s, fields[i]);
    type = string (typeof (field));
 
    if ("Null_Type" == type)
      {
      () = send_str_get_bit (fd, type);
      continue;
      }

    if ("Array_Type" == type)
      type = sprintf ("%S_Ar", _typeof (field));
 
    () = send_str_get_bit (fd, type);
    () = (@sock_f_s_clnt[type]) (fd, field);
    }
}

%% send_struct_get_bit Integer_Type (fd, Struct_Type)
define send_struct_get_bit (fd, s)
{
  send_struct (fd, s);
  return get_bit (fd);
}

%% get_struct_send_bit Struct_Type (fd, Integer_Type)
define get_struct_send_bit (fd, i)
{
  gbt = get_struct (fd);
  send_bit (fd, i);
  return gbt;
}

%% get_double Double_Type (fd)
define get_double (fd)
{
  return typecast ((read (fd, &gbt, 64), pop (), eval (gbt)), Double_Type);
}

%% get_uinteger UInteger_Type (fd)
define get_uinteger (fd)
{
  return typecast ((read (fd, &gbt, 64), pop (), eval (gbt)), UInteger_Type);
}

%% get_ullong UInteger_Type (fd)
define get_ullong (fd)
{
  return typecast ((read (fd, &gbt, 64), pop (), eval (gbt)), ULLong_Type);
}

%% get_llong UInteger_Type (fd)
define get_llong (fd)
{
  return typecast ((read (fd, &gbt, 64), pop (), eval (gbt)), LLong_Type);
}

%% get_double_send_bit Double_Type (fd, Integer_Type)
static define get_double_send_bit (fd, i)
{
  gbt = get_double (fd);
  send_bit (fd, i);
  return gbt;
}

%% get_llong_send_bit LLong_Type (fd, Integer_Type)
static define get_llong_send_bit (fd, i)
{
  gbt = get_llong (fd);
  send_bit (fd, i);
  return gbt;
}

%% get_ullong_send_bit ULLong_Type (fd, Integer_Type)
static define get_ullong_send_bit (fd, i)
{
  gbt = get_ullong (fd);
  send_bit (fd, i);
  return gbt;
}

%% get_uinteger_send_bit UInteger_Type (fd, Integer_Type)
static define get_uinteger_send_bit (fd, i)
{
  gbt = get_uinteger (fd);
  send_bit (fd, i);
  return gbt;
}

sock_f_g_clnt["String_Type"] = &send_bit_get_str;
sock_f_g_clnt["Integer_Type"] = &send_bit_get_int;
sock_f_g_clnt["String_Type_Ar"] = &send_bit_get_str_ar;
sock_f_g_clnt["Integer_Type_Ar"] = &send_bit_get_int_ar;

sock_f_s_clnt["String_Type"] = &send_str_get_bit;
sock_f_s_clnt["Integer_Type"] = &send_int_get_bit;
sock_f_s_clnt["Double_Type"] = &send_int_get_bit;
sock_f_s_clnt["UInteger_Type"] = &send_int_get_bit;
sock_f_s_clnt["String_Type_Ar"] = &send_str_ar_get_bit;
sock_f_s_clnt["Integer_Type_Ar"] = &send_int_ar_get_bit;
sock_f_s_clnt["Struct_Type"] = &send_struct_get_bit;


sock_f_g_srv["String_Type"] = &get_str_send_bit;
sock_f_g_srv["Integer_Type"]= &get_int_send_bit;
sock_f_g_srv["Double_Type"] = &get_double_send_bit;
sock_f_g_srv["UInteger_Type"] = &get_uinteger_send_bit;
sock_f_g_srv["LLong_Type"] = &get_llong_send_bit;
sock_f_g_srv["ULLong_Type"] = &get_ullong_send_bit;
sock_f_g_srv["String_Type_Ar"] = &get_str_ar_send_bit;
sock_f_g_srv["Integer_Type_Ar"] = &get_int_ar_send_bit;
sock_f_g_srv["Struct_Type"] = &get_struct_send_bit;

sock_f_s_srv["String_Type"] = &get_bit_send_str;
sock_f_s_srv["Integer_Type"] = &get_bit_send_int;
sock_f_s_srv["Integer_Type_Ar"] = &get_bit_send_int_ar;
sock_f_s_srv["String_Type_Ar"] = &get_bit_send_str_ar;

