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

public define __call__ ();
public variable __;

private variable NSS  = Assoc_Type[Any_Type];
private variable __R__ = {};
private variable VARARGS = 0x1bc;

private define add_self (ns)
{
  variable self = qualifier ("methods");
  variable methods = "err_handler" + (ns == "__" ? "" : ",vget");
  ifnot (NULL == self)
    if (String_Type == typeof (self))
      methods += "," + self;

  variable i;
  methods = strchop (methods, ',', 0);
  _for i (0, length (methods) - 1)
    methods[i] = strtrim (strtrim (methods[i]), "_");

  self = qualifier ("varself");
  variable varmethods = "name";
  ifnot (NULL == self)
    if (String_Type == typeof (self))
      varmethods += "," + self;

  varmethods = strchop (varmethods, ',', 0);
  _for i (0, length (varmethods) - 1)
    varmethods[i] = "__" + strtrim (strtrim (varmethods[i]), "_");

  methods = [methods, varmethods];

  NSS[ns]["__SELF__"] = @Struct_Type (methods);
  NSS[ns]["__SELF__"].__name = ns;
  NSS[ns]["__SELF__"].err_handler = qualifier ("err_handler");
}

private define ns_get (ns)
{
  ifnot (assoc_key_exists (NSS, ns))
    {
    eval (`public variable ` + ns + `;`);
    NSS[ns] = Assoc_Type[Any_Type];
    variable v = qualifier ("addVar", 1);
    variable f = qualifier ("addFun", 1);
    variable self = qualifier ("addSelf", 1);

    if (v)
      NSS[ns]["__V__"] = Assoc_Type[Struct_Type];

    if (f)
      NSS[ns]["__FUNC__"] = Assoc_Type[Struct_Type];

    if (self)
      add_self (ns;;__qualifiers);
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
  if (isnot_an_exception (e))
    e = struct {Exception = "No exception in the stack", message, object,
    function, line = 0, file, description, error = 0};

  strchop (sprintf ("Exception %S\
Message:     %s\n\
Object:      %S\n\
Function:    %S\n\
Line:        %d\n\
File:        %S\n\
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

private define __check___V__ (o, func)
{
  ifnot (assoc_key_exists (o, "__V__"))
    throw __Error, "Undefined__V__Error::" + func + "::" + o.__name +
      ", __V__ is not defined", NULL;

  o["__V__"];
}

private define var_init (ns, vname, vval)
{
  ns = ns_get (ns;;struct {@__qualifiers, addVar = 1});
  variable __v__ = ns["__V__"];

  vname = strtrim (vname, "__");

  if (assoc_key_exists (__v__, vname))
    if (NULL == qualifier ("ReInitVar"))
      throw __Error,  "VariableIsDefinedError::" + _function_name + "::" + vname +
        ", is defined", NULL;

  variable dtp = qualifier ("VarType");
  variable const = qualifier ("ConstVar", strup (vname) == vname);

  ifnot (NULL == dtp)
    ifnot (typeof (vval) == dtp)
      ifnot (qualifier_exists ("justinit"))
        throw __Error, sprintf (
          "VariableTypeMismatchError::%s::variable %s datatype %S is not of type %S",
            _function_name, vname, typeof (vval), dtp), NULL;

  __v__[vname] = struct {val = vval, const = const, dtype = dtp};

  variable isself = qualifier ("varself");
  if (NULL == isself || String_Type != typeof (isself) || const)
    return;

  isself = strchop (isself, ',', 0);

  if (any (isself == vname))
    if (assoc_key_exists (ns, "__SELF__"))
      if (Struct.field_exists (ns["__SELF__"], "__" + vname))
        set_struct_field (ns["__SELF__"], "__" + vname, __v__[vname].val);
}

private define var_put (ns, vname, vval)
{
  variable __ns__ = ns_get (ns;;struct {@__qualifiers, addVar = 1});
  variable __v__ = __ns__["__V__"];

  if (0 == assoc_key_exists (__v__, vname) || qualifier ("ReInitVar", 0))
    var_init (ns, vname, vval;;__qualifiers);
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

private define var_get (ns, vname)
{
  variable __ns__ = __check_ns__ (ns, _function_name);
  variable __v__ = __check___V__ (__ns__, _function_name);
  ifnot (assoc_key_exists (__v__, vname))
    throw __Error,  "VariableIsNotDefinedError::" + _function_name + ":: " +
      vname + " in " + ns + " namespace, is not defined", NULL;

  __v__[vname].val;
}

private define add_method (ns, method)
{
  variable m = get_struct_field_names (ns["__SELF__"]);

  if (any (m == method))
    return m;

  variable n = @Struct_Type ([m, method]);
  variable i;
  _for i (0, length (m) - 1)
    set_struct_field (n, m[i], get_struct_field (ns["__SELF__"], m[i]));

  NSS[ns["__SELF__"].__name]["__SELF__"] = n;
  m;
}

private define func_init (ns, func, ref, method)
{
  variable __ns__ = ns_get (ns;;struct {@__qualifiers, addFun = 1});
  variable __f__ = __ns__["__FUNC__"];
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
      variable orig = funcfname, basedir = qualifier ("DIRNS", var_get ("__", "DIRNS"));

      ifnot (path_is_absolute (funcfname))
        if (-1 == access (funcfname, F_OK|R_OK))
          if (-1 == access ((funcfname = orig + ".sl", funcfname), F_OK|R_OK))
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

    funcstr += "\n" + `__.fput ("` + ns + `", "` + func + `", &` +
      funcrefname + `;` + `ismethod=` + string (method) +
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

  ifnot (Struct.field_exists (__ns__["__SELF__"], fe))
    () = add_method (__ns__, fe);

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
    `  __call__ (__push_list (args);;__qualifiers);`;
    def_args = "";
    }
  else
    {
    variable i;
    def_args = "self";
    _for i (1, __f__[f].nargs)
      def_args += ", arg" + string (i);

    def_body = "\n" + `  __call__ (` + def_args + `, "` + ns + `::` +
      f + `::@method@";;__qualifiers);`;
    }

  variable str = "\n" + `private define  ` + f + ` (` + def_args + `)` + "\n" +
    `{` + def_body + "\n}\n" +
    `set_struct_field (__call__ (NULL, "` + ns + `", "__self__::__get__"), "` +
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

private define self_add_method (ns, method, func, ref)
{
  variable __ns__ = ns_get (ns;;struct {@__qualifiers, addFun = 1, addSelf = 1});
  variable m = add_method (__ns__, method);

  ifnot (NULL == func)
    func_init (ns, func, ref, 1;;__qualifiers);

  ifnot (any (m == method))
    eval (`
      public variable ` + ns + ` =
      __call__ (NULL, "` + ns + `", "__self__::__get__");
      `);
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

  variable err;
  while (NULL != e && Struct.field_exists (e, "message") && NULL != (err = e.message, err))
    {
    variable err_tok = strtok (err, "::");
    if (2 > length (err_tok))
      break;

    if ("UndefinedNsError" == err_tok[0])
      if (NULL != __r__ && NULL != __r__.args &&
        var_get ("__", "autodeclare") &&
          any (["&func_init", "&var_init"] == string (__r__.func)))
        {
        __.new (__r__.args[0];;__qualifiers);

        try
          {
          if ("&func_init" == string (__r__.func))
            func_init (__push_list (__r__.args);;__qualifiers);
          else
            var_init (__push_list (__r__.args);;__qualifiers);
          }
        catch __Error:
          __print_exc__ (__get_exception_info, __r__);
        }

     break;
     }

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

private define RunTime_Type ()
{
  loop (_NARGS) pop ();
}

private define __call_at_exit__ ()
{
  pop ();
}

public define __call__ ()
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

    RunTime_Type (from, func, caller, &inited, args;;__qualifiers);

    (@func) (__push_list (args);;__qualifiers);
    }
  catch __Error:
    err_handler (NULL, inited ? __R__[-1] : NULL;;__qualifiers);
  catch AnyError:
    err_handler (NULL, inited ? __R__[-1] : NULL;;__qualifiers);
  finally
    __call_at_exit__ (inited);
}

private define vget__ (self, vname)
{
  __call__ (self, self.__name, vname, "__::__vget__::vget__";;__qualifiers);
}

private define vget_ (self, vname)
{
  var_get (self.__name, vname;;__qualifiers);
}

private define new (self, ns)
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
        Array.map (Void_Type, &var_init, ns, vars, vals;;__qualifiers);

  if (isself)
    {
    eval (`
      public variable ` + ns + ` =
      __call__ (NULL, "` + ns + `", "__self__::__get__");
      `);

    ifnot (ns == "__")
      func_init (ns, "__vget_", trace ? &vget__ : &vget_, 1;;__qualifiers);
    }
}

new (NULL, "__self__";funcs = ["get_"], refs = [&self_get], addVar = 0, addSelf = 0);

new (NULL, "__"; methods = "new,vput,vget,vinit,fget,finit,fput,sget,sadd,efmt",
  funcs = ["__new_", "vput___", "vget__", "vinit___", "fget__", "finit____", "fput___",
    "sget_", "sadd____", "efmt_"],
  refs = [&new, &var_put, &var_get, &var_init, &func_get, &func_init, &func_put, &self_get,
    &self_add_method, &err_format_exc],
  vars = ["debug", "profile", "autodeclare"],
  values = {1, 0, 1});

private define RunTime_Type (ns, func, caller, inited, args)
{
  list_append (__R__, struct
    {
    ns = ns,
    func = func,
    caller = caller,
    args = args,
    handler = qualifier ("err_handler"),
    err = String_Type[0],
    });

  @inited = 1;
}

private define __call_at_exit__ (inited)
{
  if (inited)
    list_delete (__R__, -1);
}

var_init ("__", "DIRNS", path_dirname (__FILE__));

__.new ("Struct";methods = "field_exists",
  funcs = ["__field_exists__"], refs = [&field_exists]);

__.new ("Array";methods = "map", funcs = ["map?"], refs = [Array.tmp]);

__.new ("IO";methods = "readfd,readfile,tostderr,tostdout",
  funcs = ["readfd_", "tostderr?"],
  refs = [IO.readfd, IO.tmp]);
