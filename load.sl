private variable LOADED = Assoc_Type[Integer_Type, 0];

public variable ROOTDIR = path_dirname (__FILE__) + "/..";

public variable ADIR = ROOTDIR;
public variable STDDIR = ROOTDIR + "/std";
public variable USRDIR = ROOTDIR + "/usr";
public variable LCLDIR = ROOTDIR + "/local";
public variable MDLDIR = ROOTDIR + "/modules";

public variable STDDATADIR = STDDIR + "/share/data";
public variable USRDATADIR = USRDIR + "/share/data";
public variable LCLDATADIR = LCLDIR + "/share/data";

set_slang_load_path ("");
set_import_module_path ("");

public define exception_to_array ()
{
  return strchop (sprintf ("Caught an exception:%s\n\
Message:     %s\n\
Object:      %S\n\
Function:    %s\n\
Line:        %d\n\
File:        %s\n\
Description: %s\n\
Error:       %d\n",
    _push_struct_field_values (qualifier ("exc", __get_exception_info ()))), '\n', 0);
}

private define _load_ ()
{
  variable
    file,
    ns = NULL,
    fun = qualifier ("fun");

  if (1 == _NARGS)
    file = ();

  if (2 == _NARGS)
    (file, ns) = ();

  if (NULL == ns || "" == ns)
    ns = "Global";

  variable lib = ns + "->" + file;
 
  if (LOADED[lib] && 0 == qualifier_exists ("force"))
    return __get_reference (ns + "->" + fun);

  try
    {
    () = evalfile (file, ns);
    }
  catch OpenError:
    throw OpenError, sprintf ("%s: couldn't be found", file), 2;
  catch ParseError:
    throw ParseError, sprintf ("file %s: %s func: %s lnr: %d", path_basename (file),
      __get_exception_info ().message, __get_exception_info ().function,
      __get_exception_info ().line), __get_exception_info.error;
  catch RunTimeError:
    throw RunTimeError, sprintf ("file %s: %s func: %s lnr: %d", path_basename (file),
      __get_exception_info ().message, __get_exception_info ().function,
      __get_exception_info ().line), __get_exception_info.error;
 
  LOADED[lib] = 1;

  return __get_reference (ns + "->" + fun);
}

private define _findns_ (ns, lns)
{
  variable found = NULL;
  variable i;
  variable nss = [ADIR, LCLDIR, STDDIR, USRDIR];
 
  _for i (0, length (nss) - 1)
    {
    @lns =  nss[i]+ "/" + ns;
    ifnot (access (@lns, F_OK))
      {
      found = 1;
      break;
      }
    }
 
  if (NULL == found)
    throw OpenError,  "(load) " + ns + " :no such namespace", 2;
}

private define _loadfrom_ (ns, lib, dons)
{
  variable lns;
 
  _findns_ (ns, &lns);
 
  ns = NULL == dons
    ? NULL
    : Integer_Type == typeof (dons)
      ? 1 == dons
        ? ns
        : NULL
      : String_Type == typeof (dons)
        ? dons
        : NULL;

  try
    {
    () = _load_ (lns + "/" + lib, ns;fun = "");
    }
  catch AnyError:
    throw AnyError, " ", __get_exception_info ();
}

public define loadfrom (ns, lib, dons, errfunc)
{
  variable exception;
  variable excar;
  variable err;

  try
    _loadfrom_ (ns, lib, dons);
  catch AnyError:
    {
    exception = __get_exception_info ().object;

    if (typeof (exception) == Struct_Type)
      {
      excar = exception_to_array (;exc = exception);
      err = exception.error;
      }
    else
      {
      excar = [__get_exception_info.message];
      err = exception;
      }

    ifnot (NULL == errfunc)
      (@errfunc) (excar, err);
    else
      () = array_map (Integer_Type, &fprintf, stderr, "%s\n", excar ());
    }
}

public define importfrom (ns, module, dons, errfunc)
{
  variable exception;
  variable excar;
  variable lns = MDLDIR + "/" + ns;

  if (-1 == access (lns, F_OK))
    throw OpenError, "(import) " + ns + " :no such namespace", 2;

  try
    {
    ifnot (NULL == dons)
      import (lns + "/" + module, dons);
    else
      import (lns + "/" + module);
    }
  catch ImportError:
    {
    exception = __get_exception_info ();
    excar = exception_to_array (;exc = exception);

    ifnot (NULL == errfunc)
      (@errfunc) (excar, exception.error);
    else
      () = array_map (Integer_Type, &fprintf, stderr, "%s\n", excar ());
    }
}
 
public define getreffrom (ns, lib, dons, errfunc)
{
  variable fun = qualifier ("fun", "main");
  variable lns;
  variable exception;
  variable excar;
  variable err;
 
  ns = NULL == dons
    ? NULL
    : Integer_Type == typeof (dons)
      ? 1 == dons
        ? ns
        : NULL
      : String_Type == typeof (dons)
        ? dons
        : NULL;
  try
    {
    _findns_ (ns, &lns);
    return _load_ (lns + "/" + lib, ns;fun = fun);
    }
  catch AnyError:
    {
    exception = __get_exception_info ().object;
    if (typeof (exception) == Struct_Type)
      {
      excar = exception_to_array (;exc = exception);
      err = exception.error;
      }
    else
      {
      excar = [__get_exception_info.message];
      err = exception;
      }

    ifnot (NULL == errfunc)
      (@errfunc) (excar, err);
    else
      () = array_map (Integer_Type, &fprintf, stderr, "%s\n", excar ());
 
    throw AnyError, "", exception.error;
    }
}

public define loadfile (file, ns, errfunc)
{
  variable exception;
  variable excar;
 
  try
    {
    () = _load_ (file, ns;fun = "");
    }
  catch AnyError:
    {
    exception = __get_exception_info ();
    excar = exception_to_array (;exc = exception);

    ifnot (NULL == errfunc)
      (@errfunc) (excar, exception.error);
    else
      () = array_map (Integer_Type, &fprintf, stderr, "%s\n", excar ());
    }
}
