new_exception ("__RunTimeError", AnyError, "__RTERROR");
new_exception ("__EvalError", AnyError, "__EVLERROR");

public define $__ ()
{
  _pop_n (_NARGS);
}

eval (`
private variable _NS_ = Assoc_Type[Struct_Type, struct
  {
  __ = struct
    {
    _ = Assoc_Type[Any_Type],
    error_handler
    },
  ___ = Assoc_Type[Struct_Type, struct
    {
    st_mtime,
    st_size,
    fn,
    fun
    }]
  }];

private define ns_ (ns)
{
  return _NS_[ns];
}

private define ns__ ()
{
  return assoc_get_keys (_NS_);
}

public define ____ ()
{
  return ns_("__").__;
}

private define error__handler ()
{
  variable err = ns_("err").__.get_errno ();
  variable l__ = ns_(err.ns).__;

  if (NULL == l__)
    throw err.exc;

  variable err_fun = l__.error_handler;

  if (NULL == err_fun)
    throw err.exc;

  (@err_fun) (err);
}

private define gen_err_s (fun, line)
{
  return struct {fun = fun, line = line};
}

private define check__fun (ns, fun)
{
  variable ref = NULL;
  ifnot (NULL == wherefirst (get_struct_field_names (ns_(ns).__) == fun))
    ref = get_struct_field (ns_(ns).__, fun);
  else
    if (qualifier_exists ("funref"))
      {
      ns_("__").__.add_fun (ns, fun, qualifier ("funref"));
      ref = get_struct_field (ns_(ns).__, fun);
      }
    else if (qualifier_exists ("reg__fun"))
      {
      ns_("__").__.reg_fun (ns, fun;;__qualifiers ());
      ref = get_struct_field (ns_(ns).__, fun);
      }

  if (NULL == ref || 0 == __is_callable (ref))
    throw __RunTimeError, fun + " function is NULL",
      gen_err_s (_function_name, __LINE__ - 2);

  return ref;
}

private define check__ns (ns)
{
  ifnot (any (ns__ == ns))
    ifnot (qualifier_exists ("init__ns"))
      throw __RunTimeError, ns + " doesn't exists, specify the 'init__ns' qualifier to set it",
        gen_err_s (_function_name, __LINE__ - 2);
    else
      ns_("__").__.init (ns;;__qualifiers ());
}

private variable lastns = "__";

public define _____ ()
{
  variable ns = lastns, fun;

  switch (_NARGS)

    {
    case 0: return ns_(ns).__;
    }

    {
    case 1: ns = ();
    lastns = ns;
    check__ns (ns;;struct {@__qualifiers (), init__ns});
    return ns_(ns).__;
    }

    {
    case 2:
      variable exc;
      variable args = qualifier ("args", {});
      fun = ();
      ns = ();
      try
        {
        check__ns (ns;;struct {@__qualifiers (), init__ns});
        fun = check__fun (ns, fun;;struct {@__qualifiers (), reg__fun});
        (@fun) (ns_(ns).__, __push_list (args);;__qualifiers ());
        lastns = ns;
        }
      catch __RunTimeError:
        {
        exc = __get_exception_info ();
        exc =  ns_("err").__.exc_generate (NULL,
        "caller : " + ns + " " + exc.message, NULL, exc.object.fun,
          exc.object.line, ns_("__").__._["dir"]["__FILE__"], exc.descr, exc.error);

        ns_("err").__.set_errno (NULL, __RunTimeError, ns, ns_("err").__.exc_to_array (exc));
        error__handler ();
        }
     }
}

public define __ ()
{
  variable args = __pop_list (_NARGS - 1);
  variable fun = ();
  _____ ("__", fun;;struct {@__qualifiers (), args = args});
}

private define eval__string ()
{
  try
    {
    eval (qualifier ("buf"), qualifier ("ns"));
    }
  catch AnyError:
    throw __EvalError;
}

private define eval__ (s, ns, buf)
{
  try
    {
    eval__string (;buf = buf, ns = ns);
    }
  catch __EvalError:
    {
    ns_("err").__.set_errno (buf, __EvalError, ns, ns_("err").__.exc_to_array (NULL));
    error__handler ();
    }
}

private define add__field (ns, field)
{
  variable f = get_struct_field_names (ns_(ns).__);
  variable s = eval (``struct {`` +
    strjoin (f, ",") + "," + field + ``};``);

  variable i;
   _for i (0, length (f) - 1)
     set_struct_field (s, f[i], get_struct_field (ns_(ns).__, f[i]));

  ns_(ns).__ = s;
}

private define add__fun (s, ns, funnm, fun)
{
  if (NULL == wherefirst (get_struct_field_names (ns_(ns).__) == funnm))
    add__field (ns, funnm);

  set_struct_field (ns_(ns).__, funnm, fun);
  ns_(ns).___[funnm].fun = get_struct_field (ns_(ns).__, funnm);
}

private define _fnf_ (ns, fun)
{
  return qualifier ("dir",
    ns_("__").__._["dir"]["ns"] + ns + "/" + fun + qualifier ("rev", "_")
    + qualifier ("ext", ".sl"));
}

private define reg__fun (s, ns, fun)
{
  variable fn = qualifier ("fnfun", _fnf_ (ns, fun;;__qualifiers ()));
  variable st = stat_file (fn);

  if (NULL == st)
    throw __RunTimeError, "fun: " + fun + ", in ns " + ns + ","
      + errno_string (errno), gen_err_s (_function_name, __LINE__ - 2);

  variable buf = ns_("io").__.read (fn);

  ns_(ns).___[fun].st_mtime = st.st_mtime;
  ns_(ns).___[fun].st_size = st.st_size;
  ns_(ns).___[fun].fn = fn;

  ns_("__").__._["_g_"] = struct {fun = fun, ns = ns};

  eval (buf + ``
    eval ("____._[\"_g_\"] = &" +
   ____._["_g_"].fun, ____._["_g_"].ns);``, ns);

  add__fun (NULL, ns, fun, ____._["_g_"]);
  ____._["_g_"] = NULL;
}

private define rehash__ (ns, fun)
{
  variable reh = 0;
  variable exists = wherefirst (get_struct_field_names (ns_(ns).__) == fun);
  ifnot (NULL == exists)
    ifnot (NULL == ns_(ns).___[fun].fn)
      {
      variable st = stat_file (ns_(ns).___[fun].fn);
      if (st.st_mtime != ns_(ns).___[fun].st_mtime ||
          st.st_size != ns_(ns).___[fun].st_size)
        reh = 1;
      }

  if (NULL == exists || qualifier_exists ("force") || reh)
    ns_("__").__.reg_fun (ns, fun;;__qualifiers ());
}

private define reg__key (ns, fun)
{
  ns_(ns).___[fun] = struct
    {
    st_mtime = qualifier ("st_mtime"),
    st_size = qualifier ("st_size"),
    fn = qualifier ("fn"),
    fun,
    };

  add__field (ns, fun);
}

private define set__ns (s, ns)
{
  ns_(ns).__ = qualifier ("__", ns_(ns).__);
  ns_(ns).___ = qualifier ("___", Assoc_Type[Struct_Type, struct
    {st_mtime, st_size}]);
  ns_(ns).__.error_handler = qualifier ("error_handler");

  variable buf = ``
  public define `` + ns + ``__ ()
    {
    variable lns = _function_name;
    lns = substr (lns, 1, strlen (lns) - 2);
    ns_ (lns).__;
    }

  public define `` + ns + `` ()
    {
    variable args = __pop_list (_NARGS - 1);
    variable fun = ();
    variable lns = _function_name ();
    _____ (lns, fun;;struct {@__qualifiers (), args = args});
    }
    ``;

  eval (buf, "__");

  variable fun = qualifier ("fun");
  if (NULL == fun)
    return;

  variable i;
  _for i (0, length (fun) - 1)
    reg__key (ns, fun[i];;__qualifiers ());

  if (qualifier_exists ("reg__fun"))
    _for i (0,  length (fun) - 1)
      ns_("__").__.reg_fun (ns, fun[i];;__qualifiers ());
}

private define init__ (s, ns)
{
  if (any (ns__ == ns))
    ifnot (qualifier_exists ("reinit__ns"))
      return;

  eval (``sleep (0.0001);``, ns);
  set__ns (s, ns;; __qualifiers ());
}

private define use__ (s, ns, prev)
{
  ifnot (NULL == prev)
    @prev = current_namespace ();

  try
    use_namespace (ns);
  catch NamespaceError:
    {
    ns_("__").__.init (ns;;__qualifiers ());
    use_namespace (ns);
    }
}

init__ (NULL, "__";
  fun = ["add_fun", "reg_fun", "use", "init", "eval", "rehash"]);

array_map (&add__fun, NULL, "__",
  ["add_fun", "reg_fun", "use", "init", "eval", "rehash"],
  [&add__fun, &reg__fun, &use__, &init__, &eval__, &rehash__]);

`, "__");

____._["dir"] = Assoc_Type[String_Type];
____._["dir"]["__FILE__"] = __FILE__;
____._["dir"]["me"] = path_dirname (__FILE__);
____._["dir"]["ns"] = ____._["dir"]["me"] + "/ns/";
____._["_g_"] = NULL;

____.use ("err", NULL; fun = ["exc_to_array", "exc_generate", "set_errno", "get_errno"]);

private variable __errno = NULL;

private define set_errno__ (s, buf, exc, ns, err)
{
  __errno = struct {buf = buf, exc = exc, ns = ns, err = err};
}

private define get_errno__ (s)
{
  return __errno;
}

private define exc_to_array__ (s, exc)
{
  if (NULL == exc)
    exc = __get_exception_info ();

  if (NULL == exc)
    return ["No exception in the stack"];

  return strchop (sprintf ("Exception: %S\n\
Message:     %s\n\
Object:      %S\n\
Function:    %s\n\
Line:        %d\n\
File:        %s\n\
Description: %s\n\
Error:       %d\n",
    _push_struct_field_values (exc)), '\n', 0);
}

private define exc_generate__ (s, trac, msg, obj, fun, line, file, descr, err)
{
  return struct
    {
    error = err,
    descr = descr,
    file = file,
    line = line,
    function = fun,
    object = obj,
    message = msg,
    traceback = trac
    };
}

array_map (____.add_fun, NULL, "err",
  ["exc_to_array", "exc_generate", "set_errno", "get_errno"],
  [&exc_to_array__, &exc_generate__, &set_errno__, &get_errno__]);

____.use ("io", NULL;fun = ["read", "tostdout"]);

private define read__ (s, fn)
{
  variable fd = open (fn, O_RDONLY);
  variable buf;
  variable str = "";

  if (NULL == fd)
    return NULL;

  while (read (fd, &buf, 1024) > 0)
    str += buf;

  return str;
}

private define tostdout__ (msg)
{
  () = fprintf (stdout, "%s\n", msg);
}

array_map (____.add_fun, NULL, "io",
  ["read", "tostdout"],
  [&read__, &tostdout__]);

____.use ("input", NULL;fun = ["getch"]);

private define getch__ ()
{
  variable ch;
  () = system ("stty raw");
  () = fread_bytes (&ch, 1, stdin);
  () = system ("stty sane");
  return ch[0];
}

____.add_fun ("input", "getch", &getch__);

____.use ("de", NULL;fun = ["bug", "msg_handler", "hold_handler"]);

de__._["_debug"] = 1;

private define msg_handler__ (s, msg)
{
  io__.tostdout (msg);
}

private define hold_handler__ (s)
{
  $__ (input__.getch ());
}

private define bug__ (s, msg)
{
  ifnot (de__._["_debug"])
    ifnot (qualifier_exists ("force"))
      return;

  s.msg_handler (msg);

  if (qualifier_exists ("hold"))
    s.hold_handler ();
}

array_map (____.add_fun, NULL, "de",
  ["bug",  "msg_handler",  "hold_handler"],
  [&bug__, &msg_handler__, &hold_handler__]);

