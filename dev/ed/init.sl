%typedef struct
%  {
%  resume,
%  _resume,
%  main,
%  keys,
%  } Lib_Type;
%
%private define _null_ ()
%{
%%CLEAR
%}
%
%typedef struct
%  {
%  func,
%  regstd,
%  args,
%  } Action_Type;
%
%private variable _L_ = Assoc_Type[Lib_Type];
%
%static define __init__ (pgnam)
%{
%  variable s = @Lib_Type;
%%  s.keys = Assoc_Type[Action_Type];
%%  s.keys["key"].func = &_null_;
%%  s = struct {std[fields]};
%%  f = qualifier ("features");
%%  _for i (0, length (f) - 1)
%%  s = {@s, f}; % growstruct ()
%}
%
%% is under resuming => var
%% get lines -> return an array
%
%% list type for the stack
%% l = __pop_list( 
%%            __push_list ({11,12,13,14,10}),
%%            v = _stkdepth () ,
%%            _stk_roll (v),
%%            v));
%
%

ns_use ("de", &$1);

private variable _debug = 0;
static define bug(msg){ifnot(_debug)ifnot(qualifier_exists("force"))return;
send_msg_dr(msg,1,NULL,NULL);if(qualifier_exists("wait"))()=getch();}

ns_use ("io", NULL);

static define read (fn)
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

ns_use ("R", NULL);

private variable _T = Assoc_Type[DataType_Type];
_T["i"] = Integer_Type;
_T["S"] = Struct_Type;
_T["s"] = String_Type;

private define _dec_Type (t)
{
  variable i, ar = strchop (t, '_', 0), len = length (ar),
    a = DataType_Type[len];

  _for i (0, len - 1)
   a[i] = _T[ar[i]];

 return a;
}

private define reg_fun ();
private define R ();
private variable _R_ = Assoc_Type[Ref_Type, &reg_fun];
private variable _r_ = Assoc_Type[Struct_Type];
static variable _g_;

private define _fnf_ (f)
{
  return qualifier ("dir", path_dirname (__FILE__) + "/r/")
     + f + qualifier ("ext", ".sl");
}

private define reg_fun (fun)
{
  variable fnf = qualifier ("fn_fun", &_fnf_);
  variable fn = (@fnf) (qualifier ("fun", fun);;__qualifiers ());
  variable st = stat_file (fn);
  variable buf = io-> read (fn);
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
    (@_R_[req]) (req;;__qualifiers ());
}

static define function (buf)
{
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


%%%

static variable __ = struct
{
rehash = _R_get ("rehash__";dir = path_dirname (__FILE__) + "/reqs/", ext = ""),
};

$1 = strlen ($1) ? $1 : "Global";
ns_use (__tmp ($1), NULL);

%$6 = R__ ("nr");
%$7 = (@r-> _R_get ("nr"));
