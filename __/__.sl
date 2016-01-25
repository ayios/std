ifnot (-1 == is_defined ("__Error"))
  new_exception ("__Error", AnyError, "__ERROR");

public define __use_namespace (ns)
{
  try
    use_namespace (ns);
  catch NamespaceError:
    {
    eval (`sleep (0.0001);`, ns);
    use_namespace (ns);
    }
}

__use_namespace ("IO");

private define readfd (fd)
{
  if (NULL == fd)
    throw __Error, "IOFDIsNullError::" + _function_name + ": File Descriptor is NULL", NULL;

  variable buf;
  variable str = "";

  () = lseek (fd, qualifier ("offset", 0), qualifier ("seek_pos", SEEK_SET));

  while (read (fd, &buf, 1024) > 0)
    str += buf;

  str;
}

private define tostderr ()
{
  variable fmt = "%S";
  loop (_NARGS) fmt += " %S";
  variable args = __pop_list (_NARGS);

  if (1 == length (args) && typeof (args[0]) == Array_Type &&
    any ([String_Type, Integer_Type] == _typeof (args[0])))
    {
    args = args[0];

    try
      {
      () = array_map (Integer_Type, &fprintf, stderr, "%S%S", args,
        qualifier_exists ("n") ? "" : "\n");
      }
    catch AnyError:
      throw __Error, "IOWriteError::" + _function_name + "::" + errno_string (errno), NULL;
      }
  else
    if (-1 == fprintf (stderr, fmt, __push_list (args), qualifier_exists ("n") ? "" : "\n"))
      throw __Error, "IOWriteError::" + _function_name + "::" +
        errno_string (errno), NULL;
}

private define  __tostderr__ ()
{
  variable args = __pop_list (_NARGS - 1);
  pop ();
  tostderr (__push_list (args));
}

public variable IO = struct {readfd = &readfd, tostderr = &__tostderr__, tmp = &tostderr};

__use_namespace ("Struct");

private define field_exists (self, s, field)
{
  wherefirst (get_struct_field_names (s) == field);
}

public variable Struct = struct {field_exists = &field_exists};

__use_namespace ("Array");

private define map ()
{
  if (_NARGS < 3)
    throw __Error, "NumArgsError::" + _function_name +
      "::_NARGS should be at least 2 and are " + string (_NARGS), NULL;

  variable arglen = _NARGS - 2;
  variable args = __pop_list (arglen);
  variable ref = ();
  variable dtp = ();

  if (NULL == ref || 0 == __is_callable (ref) || typeof (dtp) != DataType_Type)
    throw __Error, "TypeMismatchError::" +  _function_name +
      "::" + string (ref) + " should be of Ref_Type and it is " + string (typeof (ref)) , NULL;

  variable i;
  variable llen;
  variable len = 0;
  variable dtps = DataType_Type[arglen];

  _for i (0, arglen - 1)
    {
    dtps[i] = typeof (args[i]);
    if (Array_Type == dtps[i] || List_Type == dtps[i])
      {
      llen = length (args[i]);
      ifnot (len)
        len = llen;
      else
        ifnot (llen == len)
          throw __Error, "ArrayMapInvalidParmError::" + _function_name +
            "::arrays have different length", NULL;
      }
    }

  ifnot (len)
    throw __Error, "ArrayMapTypeMismatchError::" +  _function_name +
      "::at least one argumrnt should be Array or List Type", NULL;

  variable l;
  variable ii;
  variable r;

  ifnot (Void_Type == dtp)
    variable at = dtp[len];

  _for i (0, len - 1)
    {
    l = {};

    _for ii (0, arglen - 1)
      if (Array_Type == dtps[ii] || List_Type == dtps[ii])
        list_append (l, args[ii][i]);
      else
        list_append (l, args[ii]);

    try
      {
      (@ref) (__push_list (l);;__qualifiers ());
      }
    catch AnyError:
      throw __Error, "ArrayMapRunTimeError::" + _function_name + ":: error while executing "
        + string (ref), __get_exception_info;

    ifnot (Void_Type == dtp)
      {
      r = ();

      ifnot (typeof (r) == dtp)
        throw __Error, "ArrayMapTypeMismatchError::" + _function_name + "::" + string (ref) +
          " returned " + string (typeof (r)) + "instead of " + string (dtp), NULL;

      at[i] = r;
      }
   }

  ifnot (Void_Type == dtp)
    ifnot (qualifier_exists ("discard"))
      at;
}

private define  __map__ ()
{
  variable args = __pop_list (_NARGS - 1);
  pop ();
  map (__push_list (args));
}

public variable Array = struct {map = &__map__, tmp = &map};

__use_namespace ("__");

static define __call__ ();

private variable NSS  = Assoc_Type[Any_Type];
private variable __R__ = {};
private variable VARARGS = 0x1bc;
private variable DIRNS = path_dirname (__FILE__);

private define func_init ();

private define add_self (ns)
{
  variable self = qualifier ("methods");
  variable methods = "err_handler";

  ifnot (NULL == self)
    if (String_Type == typeof (self))
      methods += "," + self;

  variable i;
  methods = strchop (methods, ',', 0);
  _for i (0, length (methods) - 1)
    methods[i] = strtrim (methods[i]);

  methods = [methods, "__name"];

  NSS[ns]["__SELF__"] = @Struct_Type (methods);
  NSS[ns]["__SELF__"].__name = ns;
  NSS[ns]["__SELF__"].err_handler = qualifier ("err_handler");
}

private define declare_var (ns)
{
  eval (`
    public variable ` + ns + ` =
    __->__call__ (NULL, "` + ns + `", "__self__::__get__");
    `);
}

private define ns_get (ns)
{
  ifnot (assoc_key_exists (NSS, ns))
    {
    NSS[ns] = Assoc_Type[Any_Type];
    variable v = qualifier ("addVar", 1);
    variable f = qualifier ("addFun", 1);
    variable self = qualifier ("addSelf", 1);

    if (v)
      NSS[ns]["__V__"] = Assoc_Type[Struct_Type];

    if (f)
      NSS[ns]["__FUNC__"] = Assoc_Type[Struct_Type];

    if (self)
      {
      add_self (ns;;__qualifiers);
      if (qualifier_exists ("declare_ns_var"))
        declare_var (ns);
      }
    }

  NSS[ns];
}

private define isnot_an_exception (e)
{
  NULL == e || Struct_Type != typeof (e) ||
  NULL == Struct.field_exists (e, "object") ||
  8 != length (get_struct_field_names (e));
}

private define err_format_exc (e)
{
  if (NULL == e)
    e = __get_exception_info;

  if (isnot_an_exception (e))
    e = struct {error = 0, description = "", file = "", line = 0, function = "", object, message = "",
    Exception = "No exception in the stack"};

  strchop (sprintf ("Exception: %s\n\
Message:     %s\n\
Object:      %S\n\
Function:    %s\n\
Line:        %d\n\
File:        %s\n\
Description: %s\n\
Error:       %d",
    _push_struct_field_values (e)), '\n', 0);
}

private define __check_ns__ (ns, func)
{
  ifnot (assoc_key_exists (NSS, ns))
    throw __Error, "UndefinedNsError::" + func + "::" + ns +
      " is not defined", NULL;

  ns_get (ns);
}

private define __check_V__ (ns, func, declare)
{
  ifnot (assoc_key_exists (ns, "__V__"))
    ifnot (declare)
      throw __Error, "Undefined__V__Error::" + func + "::" + ns.__name +
        ", __V__ is not defined", NULL;
    else
      ns["__V__"] = Assoc_Type[Struct_Type];

  ns["__V__"];
}

private define var_init (__v__, vname, vval)
{
  vname = strtrim (vname, "__");

  variable dtp = qualifier ("VarType");
  variable const = qualifier ("ConstVar", strup (vname) == vname);

  ifnot (NULL == dtp)
    ifnot (typeof (vval) == dtp)
      throw __Error, sprintf (
        "VariableTypeMismatchError::%s::variable %s datatype %S is not of type %S",
          _function_name, vname, typeof (vval), dtp), NULL;

  __v__[vname] = struct {val = vval, const = const, dtype = dtp};
}

private define var_put (ns, vname, vval)
{
  variable __ns__ = ns_get (ns;;__qualifiers);
  variable __v__ = __check_V__ (__ns__, NULL, 1);

  ifnot (assoc_key_exists (__v__, vname))
    var_init (__v__, vname, vval;;__qualifiers);
  else
    {
    if (__v__[vname].const)
      throw __Error, "VariableIsConstantTypeError::" + _function_name + "::" +  vname +
       ": variable is declared as Constant", NULL;

    ifnot (NULL == __v__[vname].dtype)
      ifnot (typeof (vval) == __v__[vname].dtype)
        throw __Error, sprintf (
          "VariableTypeMismatchError::%s::variable %s datatype %S is not of type %S",
            _function_name, vname, typeof (vval), __v__[vname].dtype), NULL;

    __v__[vname].val = vval;
    }
}

private define del_method (ns, method)
{
  variable m = get_struct_field_names (ns["__SELF__"]);
  variable i = where (m == method);
  if (NULL == i)
    return;

  m[i] = NULL;
  m = m[wherenot (_isnull (m))];

  variable n = @Struct_Type (m);
  _for i (0, length (m) - 1)
    set_struct_field (n, m[i], get_struct_field (ns["__SELF__"], m[i]));

  NSS[ns["__SELF__"].__name]["__SELF__"] = n;
}

private define var_del (ns, vname)
{
  try
    {
    variable __ns__ = __check_ns__ (ns, _function_name);
    variable __v__ = __ns__["__V__"];
    }
  catch __Error:
    return;

  ifnot (assoc_key_exists (__v__, vname))
    return;

  assoc_delete_key (__v__, vname);

  if (assoc_key_exists (__ns__, "__SELF__"))
    if (Struct.field_exists (__ns__["__SELF__"], "__" + vname))
      del_method (__ns__, "__" + vname);

}

private define var_get (ns, vname)
{
  variable __ns__ = __check_ns__ (ns, _function_name);
  variable __v__ = __check_V__ (__ns__, _function_name, 0);
  ifnot (assoc_key_exists (__v__, vname))
    throw __Error,  "VariableIsNotDefinedError::" + _function_name + ":: " +
      vname + " in " + ns + " namespace, is not defined", NULL;

  __v__[vname].val;
}

private define add_method (ns, method)
{
  variable m = get_struct_field_names (ns["__SELF__"]);

  if (any (m == method))
    return;

  variable n = @Struct_Type ([m, method]);
  variable i;
  _for i (0, length (m) - 1)
    set_struct_field (n, m[i], get_struct_field (ns["__SELF__"], m[i]));

  NSS[ns["__SELF__"].__name]["__SELF__"] = n;
  declare_var (ns["__SELF__"].__name);
}

private define func_init (ns, func, ref, method)
{
  variable __ns__ = ns_get (ns;;struct {@__qualifiers, addFun = 1});

  try
    {
    variable __f__ = __ns__["__FUNC__"];
    }
  catch __Error:
    {
    __ns__["__FUNC__"] = Assoc_Type[Struct_Type];
    __f__ = __ns__["__FUNC__"];
    }

  variable varargs = qualifier ("varargs", func[-1] == '?'
    ? (func = strtrim_end (func, "?"), 1) : 0);
  variable fb = strtrim_beg (func, "_");
  variable fe = strtrim_end (fb, "_");
  variable trace = (0 == method || NULL == method) ? 0 : qualifier ("trace", 1);
  variable f = "__" + fe + "__";
  variable funcstr = qualifier ("FuncStr");
  variable funcrefname = qualifier ("FuncRefName", ref == NULL == funcstr
    ? fe : NULL);
  variable funcfname = qualifier ("FuncFname", NULL != funcstr ? NULL : funcrefname);

  if (NULL == ref || typeof (ref) != Ref_Type || 0 == __is_callable (ref))
    if (NULL == funcstr || typeof (funcstr) != String_Type &&
        (NULL == funcrefname || typeof (funcrefname) != String_Type))
      if (NULL == funcfname || typeof (funcfname) != String_Type)
        throw __Error, sprintf (
         "%S: is not a RefType not callable, and declaration qualifiers are missing", func),
           NULL;

  ifnot (NULL == ref)
    __f__[f] = struct {func = ref, self = strlen (func) != strlen (fb),
      nargs = varargs ? VARARGS : strlen (fb) - strlen (fe)};
  else
    {
    if (NULL == funcstr)
      {
      variable orig = funcfname, basedir = qualifier ("DIRNS", DIRNS);

      ifnot (path_is_absolute (funcfname))
        if (-1 == access ((funcfname = path_concat (basedir, ns) + "/" + orig, funcfname), F_OK|R_OK))
          if (-1 == access ((funcfname = funcfname + ".sl", funcfname), F_OK|R_OK))
            funcfname = NULL;

      if (NULL != funcfname && path_is_absolute (funcfname))
        if (-1 == access (funcfname, F_OK|R_OK))
          if (-1 == access ((funcfname = funcfname + ".sl", funcfname), F_OK|R_OK))
            funcfname = NULL;

      ifnot (NULL == funcfname)
        funcstr = IO.readfd (open (funcfname, O_RDONLY));
      else
        throw __Error, "FuncReadError::" + _function_name + "::" + orig +
          ":FuncFname qualifier error: " + errno_string (errno), NULL;
      }

    funcstr += "\n" + `__->__call__ (NULL, "` + ns + `", "` + func + `", &` +
      funcrefname + `, "__::__fput__";` + `ismethod=` + string (method) +
        `, debug = ` + string (qualifier ("debug")) +
        `, trace = ` + string (trace) + `);`;
     try
       eval (funcstr, ns);
     catch AnyError:
       throw __Error, "FuncFromQualifierEvalError::" + _function_name +
         "::EVALSTRING: \n" + funcstr, __get_exception_info;
     }

  ifnot (method)
    return;

  ifnot (assoc_key_exists (__ns__, "__SELF__"))
    add_self (ns;;__qualifiers);

  if (NULL == Struct.field_exists (__ns__["__SELF__"], fe))
    add_method (__ns__, fe);

  ifnot (trace)
    {
    set_struct_field (__ns__["__SELF__"], fe, __f__[f].func);
    return;
    }

  variable def_body, def_args;
  if (varargs)
    {
    def_body = "\n" + `  variable args = __pop_list (_NARGS);` + "\n" +
    ` list_append (args, "` + ns + `::` + f + `::` + f + `");` + "\n" +
    `  __->__call__ (__push_list (args);;__qualifiers);`;
    def_args = "";
    }
  else
    {
    variable i;
    def_args = "self";
    _for i (1, __f__[f].nargs)
      def_args += ", arg" + string (i);

    def_body = "\n" + `  __->__call__ (` + def_args + `, "` + ns + `::` +
      f + `::@method@";;__qualifiers);`;
    }

  variable str = "\n" + `private define  ` + f + ` (` + def_args + `)` + "\n" +
    `{` + def_body + "\n}\n" +
    `set_struct_field (__->__call__ (NULL, "` + ns + `", "__self__::__get__"), "` +
    fe + `", &` + f + `);` + "\n";

  try
    eval (str, ns);
  catch AnyError:
    throw __Error, "FuncMethodEvalError::" + _function_name + "::EVALSTRING: " + str,
      __get_exception_info;
}

private define func_get (ns, func)
{
  variable __func__ = __check_ns__ (ns, _function_name)["__FUNC__"];
  ifnot (assoc_key_exists (__func__, func))
    throw __Error,  "FunctionIsNotDefinedError::" + _function_name + "::" + func +
      ", is not defined, in " + ns, NULL;

  __func__[func];
}

private define func_put (ns, func, ref)
{
  func_init (ns, func, ref, qualifier ("ismethod", 1);;__qualifiers);
}

private define self_get (ns)
{
  ns = __check_ns__ (ns, _function_name);
  ifnot (assoc_key_exists (ns, "__SELF__"))
    throw __Error, "SelfIsUndefinedError::" + _function_name + "::" + ns.name +
      ", __SELF__ is not defined", NULL;

  ns["__SELF__"];
}

private define RunTime_Type (ns, func, caller, args, handler)
{
  struct {
    ns = ns,
    func = func,
    caller = caller,
    args = args,
    handler = handler,
    err = String_Type[0],
    };
}

private define __print_exc__ (e, __r__)
{
  try
    {
    variable header = sprintf (
      "ERROR HEADER\nnamespace: %S\ncaller: %S\nFailed func: %S\nargs: %S\n",
       __r__.ns, __r__.caller, __r__.func, __r__.args);
    IO.tostderr (header);
    __r__.err = [__r__.err, header];
    }
  finally {}

  if (0 == isnot_an_exception (e) ||
     (0 == (e = __get_exception_info, isnot_an_exception (e))))
    {
    IO.tostderr (err_format_exc (e));
    __r__.err = [__r__.err, err_format_exc (e)];
    }

  while (isnot_an_exception (e) == 0 == isnot_an_exception (e.object))
    {
    IO.tostderr (err_format_exc (e.object));
    __r__.err = [__r__.err, err_format_exc (e.object)];
    e = e.object;
    }
}

private define err_handler (e, __r__)
{
  ifnot (NULL == __r__)
    __print_exc__ (e, __r__);

  if (NULL != __r__ &&
      Struct_Type == typeof (__r__) &&
      Struct.field_exists (__r__, "handler") &&
      NULL != __r__.handler &&
      Ref_Type == typeof (__r__.handler) &&
      __is_callable (__r__.handler))
    {
    (@__r__.handler) (__r__;;__qualifiers);
    return;
    }

  variable handler = NULL;

  if (NULL != __r__ &&
      Struct_Type == typeof (__r__) &&
      Struct.field_exists (__r__, "ns") &&
      NULL != __r__.ns)
    handler = self_get (__r__.ns).err_handler;

  if (NULL != handler &&
      Ref_Type == typeof (handler) &&
      __is_callable (handler))
    (@handler) (__r__;;__qualifiers);
}

private define __runTime__ ()
{
  loop (_NARGS) pop ();
}

private define __call_at_exit__ ()
{
  pop ();
}

static define __call__ ()
{
  variable inited = NULL;
  try
    {
    variable func = ();
    variable args = __pop_list (_NARGS - 1);
    variable self = args[0];
    variable from, nargs, needsobj, caller = NULL;
    variable n = sscanf (func, "%[a-zA-Z_]::%[a-zA-Z_]::%s", &from, &func, &caller);

    ifnot (1 < n)
      throw __Error, "FuncDefinitionParseError::__call__::" + func, NULL;

    variable f = func_get (from, func;;__qualifiers);
    (func, nargs, needsobj) = f.func, f.nargs, f.self;

    ifnot (VARARGS == nargs)
      if (_NARGS - 1 < nargs)
        throw __Error, "FuncCallNumArgsError::__call__::" + func + " is declared with " +
          string (nargs) + " but _NARGS returns " + string (_NARGS), NULL;

    ifnot (needsobj)
      list_delete (args, 0);

    __runTime__ (from, func, caller, &inited, args;;__qualifiers);

    (@func) (__push_list (args);;__qualifiers);
    }
  catch __Error:
    err_handler (NULL, inited ? __R__[-1] : NULL;;__qualifiers);
  catch AnyError:
    err_handler (NULL, inited ? __R__[-1] : NULL;;__qualifiers);
  finally
    __call_at_exit__ (inited);
}

private define new (ns)
{
  variable init = ns_get (ns;;__qualifiers);
  variable funcs = qualifier ("funcs");
  variable refs = qualifier ("refs");
  variable vars = qualifier ("vars");
  variable vals = qualifier ("values");
  variable isself = qualifier ("addSelf", 1);
  variable trace = qualifier ("trace", 1);

  if (any (typeof (funcs) == [List_Type, Array_Type]))
    if (any (typeof (refs) == [List_Type, Array_Type]))
      if (length (funcs) == length (refs))
        Array.map (Void_Type, &func_init, ns, funcs, refs,
          qualifier ("ismethod", 1);;__qualifiers);

  if (any (typeof (vars) == [List_Type, Array_Type]))
    if (any (typeof (vals) == [List_Type, Array_Type]))
      if (length (vars) == length (vals))
        Array.map (Void_Type, &var_init, __check_V__ (init, "NULL", 1), vars, vals;;__qualifiers);

  if (isself)
    declare_var (ns);
}

new ("__self__";funcs = ["get_"], refs = [&self_get], addVar = 0, addSelf = 0);
new ("__";addSelf = 0, addVar = 0);

func_init ("__", "new_", &new, 0);
func_init ("__", "fput___", &func_put, 0);
func_init ("__", "vget__", &var_get, 0);
func_init ("__", "vput___", &var_put, 0);
func_init ("__", "vdel__", &var_del, 0);
func_init ("__", "fget__", &func_get, 0);

private define __runTime__ (ns, func, caller, inited, args)
{
  list_append (__R__, RunTime_Type (ns, func, caller, args, qualifier ("err_handler")));
  @inited = 1;
}

private define __call_at_exit__ (inited)
{
  if (inited)
    list_delete (__R__, -1);
}

public define Use (ns)
{
  if (assoc_key_exists (NSS, ns))
    return;

  eval (`
static define New ()
{
  __->__call__ (NULL, "` + ns + `" , "__::__new__::New";;__qualifiers);
};

static define Var (vname, vval)
{
  __->__call__ (NULL, "` + ns + `" , vname, vval, "__::__vput__::Var";;__qualifiers);
};

static define Let (vname, vval)
{
  __->__call__ (NULL, "` + ns + `" , vname, vval, "__::__let__::Let";;__qualifiers);
};

static define Fun (func, ref)
{
  __->__call__ (NULL, "` + ns + `" , func, ref, "__::__fput__::Fun";;__qualifiers);
};

static define Vget (vname)
{
  __->__call__ (NULL, "` + ns + `" , vname, "__::__vget__::Vget";;__qualifiers);
};

static define Fget (func)
{
  __->__call__ (NULL, "` + ns + `" , func, "__::__fget__::Fget";;__qualifiers);
};

static define Vdel (vname)
{
  __->__call__ (NULL, "` + ns + `" , vname, "__::__vdel__::Vdel";;__qualifiers);
};
`, ns);
}

Use ("Err");
Use ("Struct");
Use ("Array");
Use ("IO");

Err->Fun ("efmt_", &err_format_exc);
Err->Fun ("eprint__", &__print_exc__);
Err->Fun ("rtime_type_____", &RunTime_Type);

Struct->Fun ("__field_exists__", &field_exists);

Array->Fun ("map?", Array.tmp);

IO->New (;methods = "readfd,tostderr",
  funcs = ["readfd_", "tostderr?"], refs = [IO.readfd, IO.tmp]);
