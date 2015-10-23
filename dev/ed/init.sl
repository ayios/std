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

static variable _ = Assoc_Type[Any_Type];
static variable __ =  struct {_, error_handler, exc_to_array = &exc_to_array__};
`, "err");

eval (`
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

static variable _ = Assoc_Type[Any_Type];
static variable __ =  struct {_, error_handler, read = &read__};
`, "io");

eval (`

private variable _NS_ = Assoc_Type[Struct_Type, struct {_, __, ___}];

public define ___ (ns)
{
  return _NS_[ns].__;
}

private variable __errno = NULL;

static variable _g_;

private define set__errno (s)
{
  __errno = s;
}

private define get__errno (s)
{
  return __errno;
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

private define error__handler ()
{
  variable err_fun = _NS_[__errno.ns].__.err_handler;

  if (NULL == err_fun)
    return;

  (@err_fun) (__errno);
}

private define eval__ (s, ns, buf)
{
  try
    {
    eval__string (;buf = buf, ns = ns);
    }
  catch __EvalError:
    {
    set__errno (struct {buf = buf, ns = ns, err = err->__.exc_to_array (NULL)});
    error__handler ();
    }
}

private define add__fun (s, ns, funnm, fun)
{
  set_struct_field (_NS_[ns].__, funnm, fun);
  _NS_[ns].___[funnm].fun = get_struct_field (_NS_[ns].__, funnm);
}

private define _fnf_ (ns, fun)
{
  return qualifier ("dir", ___ ("_")._["nsdir"] + ns + "/"
     + fun + qualifier ("ext", ".sl"));
}

private define reg__fun (s, ns, fun)
{
  variable fnf = qualifier ("fn_fun", &_fnf_);
  variable fn = (@fnf) (ns, qualifier ("fun", fun);;__qualifiers ());
  variable st = stat_file (fn);
  variable buf = io->__.read (fn);

  _NS_[ns].___[ns].st_mtime = st.st_mtime;
  _NS_[ns].___[ns].st_size = st.st_size;
  _NS_[ns].___[ns].fn = fn;

  ___ ("_")._["_g_"] = struct {fun = fun, ns = ns};

  eval (buf + ``
    eval ("___(\"_\")._[\"_g_\"] = &" +
   ___ ("_")._["_g_"].fun, ___ ("_")._["_g_"].ns);``, ns);

  add__fun (NULL, ns, fun, ___ ("_")._["_g_"]);
  ___ ("_")._["_g_"] = NULL;
}

private define add__field (ns, field)
{
  variable f = get_struct_field_names (_NS_[ns].__);
  variable s = eval (``struct {`` +
    strjoin (f, ",") + "," + field + ``};``);

  variable i;
   _for i (0, length (f) - 1)
     set_struct_field (s, f[i], get_struct_field (_NS_[ns].__, f[i]));

  return s;
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

  _NS_[ns].__ = add__field (ns, fun);
  eval (``__ =  ___ ("`` + ns + ``");``, ns);
}

private define set__ns (ns)
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

  set__ns (ns;; __qualifiers ());
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

init__ (NULL, "_";fun = ["add_fun", "reg_fun", "use", "init", "eval", "set_errno", "get_errno"]);
array_map (&add__fun, NULL, "_",
  ["add_fun", "reg_fun", "use", "init", "eval", "set_errno", "get_errno"],
  [&add__fun, &reg__fun, &use__, &init__, &eval__, &set__errno, &get__errno]);


set__ns ("err"; __ = err->__);
add__fun (NULL, "err", "exc_to_array", err->__.exc_to_array);
set__ns ("io"; __ = io->__);
add__fun (NULL, "io", "read", io->__.read);

`, "_");

___ ("_")._["nsdir"] = path_dirname (__FILE__) + "/ns/";
___ ("_")._["_g_"] = NULL;

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

_->__.use ("an", NULL;fun = ["fun"]);

private define fun__ (buf)
{
}

_->__.add_fun ("an", "fun", &fun__);

_->__.use ("R", NULL;fun = ["rehash"]);

___("_").reg_fun ("R", "rehash";ext = "");

%static define _R_get (req)
%{
%  R_ (req;;__qualifiers ());
%  return (_R_[req]);
%}
%
%public define R__ ()
%{
%  variable args = __pop_list (_NARGS);
%
%  R_ (args[0];;__qualifiers ());
%
%  switch (_NARGS)
%    {
%   case 1: (R(args[0])) (;;__qualifiers ());
%    }
%
%    {
%   case 2: (R(args[0])) (args[1];;__qualifiers ());
%    }
%
%    {
%   case 3:
%    ((R(args[0])) (args[1];;__qualifiers ())) (args[2];;__qualifiers ());
%    }
%}
%

_->__.use (__tmp ($1), NULL);
