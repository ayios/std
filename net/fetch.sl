importfrom ("std", "curl", NULL, &on_eval_err);

private define write_to_var_callback (out, str)
{
  @out += str;
  return 0;
}

private define write_callback (fp, str)
{
  variable len = bstrlen (str);
  if (len != fwrite (str, fp))
    return -1;

  return 0;
}

private define fetch (s, url)
{
  variable
    write_to_var = qualifier_exists ("write_to_var");

  ifnot (write_to_var)
    {
    variable
      file = qualifier ("file", strchop (url, '/', 0)[-1]),
      fp = fopen (file, "w");

    if (NULL == fp)
      {
      tostderr (sprintf ("%s: can't open, ERRNO: %s", file, errno_string (errno)));
      return -1;
      }
    }
  else
    {
    s.write_callback = &write_to_var_callback;
    s.output =  "";
    }
 
  try
    {
    variable c = curl_new (url);

    if (s.followlocation)
      curl_setopt (c, CURLOPT_FOLLOWLOCATION, 1);
 
    ifnot (write_to_var)
      curl_setopt (c, CURLOPT_WRITEFUNCTION, s.write_callback, fp);
    else
      curl_setopt (c, CURLOPT_WRITEFUNCTION, s.write_callback, &s.output);
 
    ifnot (NULL == s.progress_callback)
      curl_setopt (c, CURLOPT_PROGRESSFUNCTION, s.progress_callback, s);
 
    curl_setopt (c, CURLOPT_HTTPHEADER, [s.useragent]);

    if (s.connectiontimeout)
      curl_setopt (c, CURLOPT_CONNECTTIMEOUT, s.connectiontimeout);

    curl_setopt (c, CURLOPT_NOSIGNAL, 1);

    ifnot (NULL == s.cacert)
      curl_setopt (c, CURLOPT_CAINFO, s.cacert);

    curl_perform (c);
    }
  catch CurlError:
    {
    ifnot (qualifier_exists ("dont_print"))
      array_map (Void_Type, &tostderr, err__.exc_to_array ());

    ifnot (write_to_var)
      {
      () = fclose (fp);
      () = remove (file);
      }

    return __get_exception_info.error;
    }

  variable buf;

  ifnot (write_to_var)
    {
    if (-1 == fclose (fp))
      {
      tostderr (sprintf ("Unable to close file `%s'", file));
      if (-1 == remove (file))
        tostderr (sprintf ("Unable to remove file `%s', ERRNO: %s", file,
          errno_string (errno)));

      return -1;
      }

    fp = fopen (file, "rb");
    if (-1 == fread (&buf, String_Type, 100, fp))
      {
      tostderr (sprintf ("Unable to read file `%s'", file));
      return -1;
      }

    if (-1 == fclose (fp))
      {
      tostderr (sprintf ("Unable to close file `%s'", file));
      if (-1 == remove (file))
        tostderr (sprintf ("Unable to remove file `%s', ERRNO: %s", file,
          errno_string (errno)));

      return -1;
      }
    }
  else
    buf = substr (s.output, 1, 100);

  if (string_match (buf, "404 Not Found", 1))
    {
    tostderr (sprintf ("remote file `%s' didn't retrieved (404 Not Found)",
       path_basename (url)));
      return -1;
    }

  return 0;
}

define fetch_new ()
{

  variable s = struct
    {
    fetch = &fetch,
    write_callback = &write_callback,
    progress_callback,
    output,
    followlocation = 1,
    useragent = "User-Agent: S-Lang cURL Module",
    cacert = "/etc/ssl/certs/ca-certificates.crt",
    connectiontimeout = 0,
    };

  return s;
}
