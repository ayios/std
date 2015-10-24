% resume, _resume;
%% l = __pop_list( 
%%            __push_list ({11,12,13,14,10}),
%%            v = _stkdepth () ,
%%            _stk_roll (v),
%%            v));

% GET OPTIONS
% from env
% from def->qualifiers

% var->___["declare"].onlyif (1 == v, "varname");

$1 = current_namespace ();
$1 = strlen ($1) ? $1 : "Global";

new_exception ("__RunTimeError", AnyError, "__RTERROR");
new_exception ("__EvalError", AnyError, "__EVLERROR");

public define $_ () % pure stylistic (same with vim's blackhole register)
{
  _pop_n (_NARGS);
}

eval (`
private variable _NS_ = Assoc_Type[Struct_Type, struct {_, __, ___}];

public define ___ (ns)
{
  return _NS_[ns].__;
}

private define error__handler ()
{
  variable err = ___ ("err").get_errno ();
  variable l__ = _NS_[err.ns].__;

  if (NULL == l__)
    return;

  variable err_fun = l__.err_handler;

  if (NULL == err_fun)
    return;

  (@err_fun) (err);
}

private define check__ns (ns)
{
  ifnot (assoc_key_exists (_NS_, ns))
    ifnot (qualifier_exists ("init__ns"))
      {
      ___ ("de").bug (ns + " doesn't exists, specify the 'init__ns' qualifier to set it");
      ___ ("err").set_errno (NULL, ns,
        ___ ("err").exc_to_array ( ___ ("err").exc_generate ("", ns + "doesn't exists",
          NULL, _function_name,  __LINE__, "__",  "Run Time Error", __RunTimeError)));

      error__handler ();
      return NULL;
      }
    else
      {
      ___ ("_").init (ns;;__qualifiers ());
      return ___ (ns);
     }

  return ___ (ns);
}

private define check__fun (ns, fun)
{
  variable ref = NULL;
  ifnot (NULL == wherefirst (get_struct_field_names (_NS_[ns].__) == fun))
    ref = get_struct_field (_NS_[ns].__, fun);
  else
    if (qualifier_exists ("reg__fun"))
      {
      ___ ("_").reg_fun (ns, fun;;__qualifiers ());
      ref = get_struct_field (_NS_[ns].__, fun);
      }

  if (NULL == ref)
    {
     ___ ("err").set_errno (NULL, ns,
       ___ ("err").exc_to_array ( ___ ("err").exc_generate ("", fun + " is NULL",
          NULL, _function_name,  __LINE__, "__",  "Run Time Error", __RunTimeError)));
     error__handler ();
    }

  return ref;
}

public define ____ ()
{
  variable ns = "_", fun;

  switch (_NARGS)

    {
    case 0: return ___ (ns);
    }

    {
    case 1: ns = ();
    return check__ns (ns;;struct {@__qualifiers (), init__ns});
    }

    {
    case 2:
      fun = ();
      ns = ();
      variable s = check__ns (ns;;struct {@__qualifiers (), init__ns});

      if (NULL == s)
        return NULL;

      fun = check__fun (ns, fun;;struct {@__qualifiers (), reg__fun});

      if (fun == NULL)
        return;

      variable args = qualifier ("args", {});
      (@fun) (___ (ns), __push_list (args));
    }
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
    ___ ("err").set_errno (NULL, buf, ns, ___ ("err").exc_to_array (NULL));
    error__handler ();
    }
}

private define add__field (ns, field)
{
  variable f = get_struct_field_names (_NS_[ns].__);
  variable s = eval (``struct {`` +
    strjoin (f, ",") + "," + field + ``};``);

  variable i;
   _for i (0, length (f) - 1)
     set_struct_field (s, f[i], get_struct_field (_NS_[ns].__, f[i]));

  _NS_[ns].__ = s;
  eval (``__ =  ___ ("`` + ns + ``");``, ns);
}

private define add__fun (s, ns, funnm, fun)
{
  if (NULL == wherefirst (get_struct_field_names (_NS_[ns].__) == funnm))
    add__field (ns, funnm);

  set_struct_field (_NS_[ns].__, funnm, fun);
  _NS_[ns].___[funnm].fun = get_struct_field (_NS_[ns].__, funnm);
}

private define _fnf_ (ns, fun)
{
  return qualifier ("dir", ___ ("_")._["dir"]["ns"] + ns + "/" + fun +
    qualifier ("ext", ".sl"));
}

private define reg__fun (s, ns, fun)
{
  variable fnf = qualifier ("fn_fun", &_fnf_);
  variable fn = (@fnf) (ns, fun;;__qualifiers ());
  variable st = stat_file (fn);
  variable buf = ___ ("io").read (fn);

  _NS_[ns].___[fun].st_mtime = st.st_mtime;
  _NS_[ns].___[fun].st_size = st.st_size;
  _NS_[ns].___[fun].fn = fn;

  ___ ("_")._["_g_"] = struct {fun = fun, ns = ns};

  eval (buf + ``
    eval ("___(\"_\")._[\"_g_\"] = &" +
   ___ ("_")._["_g_"].fun, ___ ("_")._["_g_"].ns);``, ns);

  add__fun (NULL, ns, fun, ___ ("_")._["_g_"]);
  ___ ("_")._["_g_"] = NULL;
}

private define rehash__ (ns, fun)
{
  variable reh = 0;
  variable exists = wherefirst (get_struct_field_names (_NS_[ns].__) == fun);
  ifnot (NULL == exists)
    ifnot (NULL == _NS_[ns].___[fun].fn)
      {
      variable st = stat_file (_NS_[ns].___[fun].fn);
      if (st.st_mtime != _NS_[ns].___[fun].st_mtime ||
          st.st_size != _NS_[ns].___[fun].st_size)
        reh = 1;
      }

  if (NULL == exists || qualifier_exists ("force") || reh)
    ___ ("_").reg_fun (ns, fun;;__qualifiers ());
}

private define reg__key (ns, fun)
{
  _NS_[ns].___[fun] = struct
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
  _NS_[ns] = struct
    {
    _ = Assoc_Type[Any_Type],
    __ = qualifier ("__", eval ("__", ns)),
    ___ = qualifier ("___", Assoc_Type[Struct_Type, struct {st_mtime, st_size, fn, fun}]),
    };

  _NS_[ns].__.error_handler = qualifier ("error_handler");
  _NS_[ns].__._ = eval (``_``, ns);

  variable fun = qualifier ("fun");
  if (NULL == fun)
    return;

  variable i;
  _for i (0, length (fun) - 1)
    reg__key (ns, fun[i];;__qualifiers ());

  if (qualifier_exists ("reg__fun"))
    _for i (0,  length (fun) - 1)
      ___ ("_").reg_fun (ns, fun[i];;__qualifiers ());
}

private define init__ (s, ns)
{
  eval__ (NULL, ns, ``sleep (0.0001);``);

  variable buf = ``

  static variable _ = Assoc_Type[Any_Type];
  static variable __ = struct
    {
    _,
    error_handler,
    };

  ``;

  eval__ (NULL, ns, buf);

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
    s.init (ns;;__qualifiers ());
    use_namespace (ns);
    }
}

init__ (NULL, "_";fun = ["add_fun", "reg_fun", "use", "init", "eval", "rehash"]);
array_map (&add__fun, NULL, "_",
  ["add_fun", "reg_fun", "use", "init", "eval", "rehash"],
  [&add__fun, &reg__fun, &use__, &init__, &eval__, &rehash__]);

`, "_");

___ ("_")._["dir"] = Assoc_Type[String_Type];
___ ("_")._["dir"]["me"] = path_dirname (__FILE__);
___ ("_")._["dir"]["ns"] = ___ ("_")._["dir"]["me"] + "/ns/";
___ ("_")._["_g_"] = NULL;

_->__.use ("err", NULL;fun = ["exc_to_array", "exc_generate", "set_errno", "get_errno"]);

private variable __errno = NULL;

private define set_errno__ (s, buf, ns, err)
{
  __errno = struct {buf = buf, ns = ns, err = err};
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

  return strchop (sprintf ("Exception: %s\n\
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

array_map (___ ("_").add_fun, NULL, "err",
  ["exc_to_array", "exc_generate", "set_errno", "get_errno"],
  [&exc_to_array__, &exc_generate__, &set_errno__, &get_errno__]);

_->__.use ("io", NULL;fun = ["read"]);

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

___ ("_").add_fun ("io", "read", &read__);

_->__.use ("de", NULL;fun = ["bug", "msg_handler", "hold_handler"]);

_["_debug"] = 1;

private define msg_handler__ (s, msg)
{
  send_msg_dr (msg, 1, NULL, NULL);
}

private define hold_handler__ (s)
{
  $_ (getch);
}

private define bug__ (s, msg)
{
  ifnot (_["_debug"])
    ifnot (qualifier_exists ("force"))
      return;

  s.msg_handler (msg);

  if (qualifier_exists ("hold"))
    s.hold_handler ();
}

array_map (___ ("_").add_fun, NULL, "de",
  ["bug",  "msg_handler",  "hold_handler"],
  [&bug__, &msg_handler__, &hold_handler__]);

_->__.use (__tmp ($1), NULL);
