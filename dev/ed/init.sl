% resume, _resume;
%% l = __pop_list( 
%%            __push_list ({11,12,13,14,10}),
%%            v = _stkdepth () ,
%%            _stk_roll (v),
%%            v));

% GET OPTIONS
% from env
% from def->qualifiers

new_exception ("__RunTimeError", AnyError, "__RTERROR");
new_exception ("__EvalError", AnyError, "__EVLERROR");

typedef struct
  {
  _,
  __,
  _R_,
  _r_,
  } NS_Type;

eval (`
private variable _NS_ = Assoc_Type[Struct_Type,
@Struct_Type ("_", "__", "___")];
private define I_ (i, ns)
{
return _NS_[ns];
}
private define I__ (i)
{
return assoc_get_keys (_NS_);
}
private define I___ (i, ns)
{
assoc_delete_key (_NS_);
}
static variable __ = struct {
_ = &I_,
__ = &I__,
___ = &I___,
__err__ = Ref_Type[2],
};
public define ___ (ns)
{
return _NS_[ns];
}
_NS_["_"].__ = __;
`, "_");

% pure stylistic (conforms also with vim's blackhole register)
public define $_ ()
{
  _pop_n (_NARGS);
}

private variable _ = Assoc_Type[NS_Type];

% early creation of the "eval" ns, to satisfy the intepreter at the first call
eval (`static variable __ = struct {string}`, "eval");
% method will be re-defined
eval (`private define string__ (s, buf, ns){eval (buf, ns);}__.string = &string__`, "eval");

$1 = current_namespace ();
$1 = strlen ($1) ? $1 : "Global";
eval ("sleep (0.0001);", "ns");
use_namespace ("ns");

private define _set_ (ns) % functions that are not belong to the object,
{                        % declared as _fun_
  _[ns] = @NS_Type;
  _[ns].__ = eval ("__", ns);
  _[ns]._R_ = Assoc_Type[Ref_Type];
  _[ns]._r_ = Assoc_Type[Struct_Type];
}

private define init__ (s, ns)  % methods declared as private
{                             % fun name ends with __
  eval->__.string ("sleep (0.0001);", ns);

  variable buf = `            % backquote'd (eval) multiline strings.
static variable __ = struct { % indicated by a newline and initial indent
err_handler,                  % set to 0. (for eye'catching syntax errors)
v = Assoc_Type[Assoc_Type],   % by|and not letting (hopefully) editor confuse
`                             % with syntax checking and|or hilight properly.
+ qualifier ("__", "")        % also give us code free of escaping chars
+ `};` % declare __ as static
;      % qualifier "__" = field names (methods) of the object

  eval->__.string (buf, ns);

  buf = "";

  variable vtypes = qualifier ("vtypes");
  ifnot (NULL == vtypes) % qualifier "vtypes" = keys (Datatype's)
    {                    % of the `v' variable, can also be set
    variable t;          % afterwards by using __->__.set (...)
    _for t (0, length (vtypes) - 1)
      buf += `__.v["` + vtypes[t] + `"] = Assoc_Type [` + vtypes[t] + `];`;
    } % accessible as ns->__.v["Datatype"][varname]
      % or by using __->__.get (...)

  eval (buf, ns);

  _set_ (ns);
}

private define use__ (s, ns, prev) % s (as first arg) is the underlying object
{                                  % used as s.method (arg, ...)
  ifnot (NULL == prev)
    @prev = current_namespace ();  % NULL or a reference

  try
    use_namespace (ns);
  catch NamespaceError:
    {
    s.init (ns;;__qualifiers ()); % pass qualifiers on other function calls
    use_namespace (ns);
    }
}

% declaration of the __ variable, no need to do it again (unless there is a need)
static variable __ = struct {use = &use__, init = &init__};

% "de" ns (development and debug)
__.use ("de", NULL;__ = "bug, msg_handler, hold_handler",
vtypes = [`Ref_Type`, `Struct_Type`,`Integer_Type`, `Array_Type`]);

__.v["Integer_Type"]["_debug"] = 1;

private define msg_handler__ (s, msg)
{
  send_msg_dr (msg, 1, NULL, NULL);
}

private define hold_handler__ (s)
{
  $_(getch);
}

private define bug__ (s, msg)
{
  ifnot (__.v["Integer_Type"]["_debug"])
    ifnot (qualifier_exists ("force"))
      return;

  s.msg_handler (msg);

  if (qualifier_exists ("hold"))
    s.hold_handler ();
}

__.bug = &bug__;
__.msg_handler = &msg_handler__;
__.hold_handler = &hold_handler__;

ns->__.use ("err", NULL;__ = "exc_to_array", vtypes = [`Assoc_Type`]);

private define exc_to_array__ (s, exc)
{
  if (NULL == exc)
    exc = __get_exception_info ();

  if (NULL == exc)
    return ["No exception in the stack"];

  return strchop (sprintf ("Caught an exception:%s\n\
Message:     %s\n\
Object:      %S\n\
Function:    %s\n\
Line:        %d\n\
File:        %s\n\
Description: %s\n\
Error:       %d\n",
    _push_struct_field_values (exc)), '\n', 0);
}

__.exc_to_array = &exc_to_array__;

ns->__.use ("eval", NULL);

private define string__ (s, buf, ns)
{
  try
    {
    eval (buf, ns);
    }
  catch AnyError:
    throw __EvalError, "", err->__.exc_to_array (__get_exception_info ());

}

__.string = &string__;

ns->__.use ("__", NULL;__ = "put,get,set");

private define set__ (s, ns, type, varname, valtype)
{
  eval (`__.v["` + string (type) + `"]["` + varname + `"] = ` + valtype, ns);
}

private define put__ (s, ns, type, varname, varval)
{
  variable i = qualifier ("index", "");
  variable f = qualifier ("field", "");
  eval (`__.v["` + string (type) + `"]["` + varname + `"]` +
  i + f + `= ` + varval, ns);
}

private define get__ (s, ns, type, varname)
{
  return eval (`__.v["` + string (type) + `"]["` + varname + `"]`, ns);
}

__.get = &get__;
__.put = &put__;
__.set = &set__;

ns->__.use ("io", NULL;__ = "read");

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

__.read = &read__;

ns->__.use ("an", NULL;__ = "fun");

private define fun__ (buf)
{
}

__.fun = &fun__;

ns->__.use ("R", NULL;__ = "rehash");

private define _reg_fun_ ();
private define R ();
private variable _R_ = Assoc_Type[Ref_Type, &_reg_fun_];
private variable _r_ = Assoc_Type[Struct_Type];
static variable _g_;

private define _fnf_ (f)
{
  return qualifier ("dir", path_dirname (__FILE__) + "/reqs/")
     + f + qualifier ("ext", ".sl");
}

private define _reg_fun_ (fun)
{
  variable fnf = qualifier ("fn_fun", &_fnf_);
  variable fn = (@fnf) (qualifier ("fun", fun);;__qualifiers ());
  variable st = stat_file (fn);
  variable buf = io->__.read (fn);
  variable f = struct
    {
    mtime = st.st_mtime,
    size  = st.st_size,
    fname = fn
    };

  _g_ = fun;

  _r_[fun] = f;

  eval (buf + `
    eval ("_g_ = &" + _g_, "R");`, "R");

  _R_[fun] = __tmp (_g_);
}

private define R (req)
{
  (@_R_[req]) (;;__qualifiers ());
}

private define R_ (req)
{
  ifnot (assoc_key_exists (_r_, req))
    _reg_fun_ (req;;__qualifiers ());
}

static define _R_get (req)
{
  R_ (req;;__qualifiers ());
  return (_R_[req]);
}

public define R__ ()
{
  variable args = __pop_list (_NARGS);

  R_ (args[0];;__qualifiers ());

  switch (_NARGS)
    {
   case 1: (R(args[0])) (;;__qualifiers ());
    }

    {
   case 2: (R(args[0])) (args[1];;__qualifiers ());
    }

    {
   case 3:
    ((R(args[0])) (args[1];;__qualifiers ())) (args[2];;__qualifiers ());
    }
}

__.rehash = _R_get ("rehash__";dir = path_dirname (__FILE__) + "/reqs/", ext = "");

ns->__.use (__tmp ($1), NULL);

__->__.set ("de", Struct_Type, "s",  `struct {w,q}`);
de->__.bug (string (__->__.get ("de", Struct_Type, "s")););

%__->__.set ("de", Struct_Type, "s",  `struct {w,q}`);
%de->__.bug (string (__->__.get ("de", Struct_Type, "s")););
%__->__.put ("de", Array_Type,  "_vget", `11`;index = `[2]`);
%de->__.v["Array_Type"]["_vget"][9] = 10;
%de->__.bug (string (__->__.get ("de", Array_Type, "_vget")[2]););
%__->__.put ("_vget", `a`, "de");
%de->__.bug (string (__->__.get ("_vget", "de"));hold);
%__->__.put ("_vget", `"1"`, "de");
%de->__.bug (string (__->__.get ("_vget", "de"));hold);



