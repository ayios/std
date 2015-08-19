private variable LOADED = Assoc_Type[Integer_Type, 0];

public variable ROOTDIR = path_concat (getcwd (), path_dirname (__FILE__));
 
if (ROOTDIR[[-2:]] == "/.")
  ROOTDIR = substr (ROOTDIR, 1, strlen (ROOTDIR) - 2);
 
ROOTDIR+= "/..";

public variable MACHINE = uname ().machine;
public variable OS = uname ().sysname;

try
  import (ROOTDIR + "/modules/" + MACHINE + "/std/ayios");
catch ImportError:
  {
  () = fprintf (stderr, "%s\n", __get_exception_info.message);
  exit (1);
  }

ROOTDIR = realpath (ROOTDIR);

public variable PID = getpid ();
public variable UID = getuid ();
public variable GID = getgid ();
public variable ISSUPROC = UID ? 0 : 1;

public variable ADIR = ROOTDIR;
public variable STDDIR = ROOTDIR + "/std";
public variable USRDIR = ROOTDIR + "/usr";
public variable LCLDIR = ROOTDIR + "/local";
public variable MDLDIR = ROOTDIR + "/modules/" + MACHINE;

public variable STDDATADIR = STDDIR + "/share/data";
public variable USRDATADIR = USRDIR + "/share/data";
public variable LCLDATADIR = LCLDIR + "/share/data";
public variable HISTDIR    = LCLDIR + "/share/history";

public variable FILE_FLAGS = Assoc_Type[Integer_Type];

FILE_FLAGS[">"]    = O_WRONLY|O_CREAT;
FILE_FLAGS[">|"]   = O_WRONLY|O_TRUNC|O_CREAT;
FILE_FLAGS[">>"]   = O_WRONLY|O_APPEND;
FILE_FLAGS[">>|"]  = O_WRONLY|O_APPEND|O_CREAT;
FILE_FLAGS["<"]    = O_RDONLY;
FILE_FLAGS["<>"]   = O_RDWR|O_CREAT;
FILE_FLAGS["<>|"]  = O_RDWR|O_TRUNC|O_CREAT;
FILE_FLAGS["<>>"]  = O_RDWR|O_APPEND;
FILE_FLAGS["<>>|"] = O_RDWR|O_APPEND|O_CREAT;

public variable PERM = Assoc_Type[Integer_Type];

PERM["PRIVATE"]  = S_IRWXU;                          %0700
PERM["_PRIVATE"] = S_IRUSR|S_IWUSR;                  %0600
PERM["STATIC"]   = PERM["PRIVATE"]|S_IRWXG;          %0770
PERM["_STATIC"]  = PERM["PRIVATE"]|S_IRGRP|S_IXGRP;  %0750
PERM["__STATIC"] = PERM["_PRIVATE"]|S_IRGRP;         %0640
PERM["PUBLIC"]   = PERM["STATIC"]|S_IRWXO;           %0777
PERM["_PUBLIC"]  = PERM["_STATIC"]|S_IROTH|S_IXOTH;  %0755
PERM["__PUBLIC"] = PERM["__STATIC"]|S_IROTH;         %0644
PERM["___PUBLIC"]= PERM["_PRIVATE"]|S_IWGRP|S_IWOTH; %0622

public variable PATH = getenv ("PATH");
public variable TERM = getenv ("TERM");
public variable LANG = getenv ("LANG");
public variable HOME = getenv ("HOME");
public variable DISPLAY    = getenv ("DISPLAY");
public variable XAUTHORITY = getenv ("XAUTHORITY");
public variable LINES;
public variable COLUMNS;
public variable SLSH_LIB_DIR;
public variable SLANG_MODULE_PATH;
public variable SLSH_BIN;
public variable SUDO_BIN;
public variable GROUP;
public variable USER;

% for now
public variable SOURCEDIR = ROOTDIR;
public variable TEMPDIR = ROOTDIR + "/tmp";

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
    throw OpenError, __get_exception_info.message, 2;
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

private define _findns_ (ns, lns, lib)
{
  variable foundlib = NULL;
  variable foundns = NULL;
  variable i;
  variable nss = [ADIR, LCLDIR, STDDIR, USRDIR];
 
  _for i (0, length (nss) - 1)
    {
    @lns =  nss[i]+ "/" + ns;
 
    ifnot (access (@lns, F_OK))
      foundns = 1;

    ifnot (access (@lns, F_OK))
      if (0 == access (@lns + "/" + lib + ".sl", F_OK)
        ||0 == access (@lns + "/" + lib + ".slc", F_OK))
        {
        foundlib = 1;
        break;
        }
    }
 
  if (NULL == foundns)
    throw OpenError,  "(load error) " + ns + ": no such namespace", 2;

  if (NULL == foundlib)
    throw OpenError,  "(load error) " + lib + ": no such library", 2;

}

private define _loadfrom_ (ns, lib, dons)
{
  variable lns;

  _findns_ (ns, &lns, lib);
 
  ns = NULL == dons
    ? NULL
    : Integer_Type == typeof (dons)
      ? 1 == dons
        ? ns
        : NULL
      : String_Type == typeof (dons) || BString_Type == typeof (dons)
        ? dons
        : NULL;

  try
    {
    () = _load_ (lns + "/" + lib, ns;;struct {fun = "", @__qualifiers ()});
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
 
  _findns_ (ns, &lns, lib);

  ns = NULL == dons
    ? NULL
    : Integer_Type == typeof (dons)
      ? 1 == dons
        ? ns
        : NULL
      : String_Type == typeof (dons) || BString_Type == typeof (dons)
        ? dons
        : NULL;
  try
    {
    return _load_ (lns + "/" + lib, ns;;struct {fun = fun, @__qualifiers ()});
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
    () = _load_ (file, ns;;struct {fun = "", @__qualifiers ()});
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

define which (executable)
{
  variable
    ar,
    st,
    path = PATH;

  if (NULL == path)
    return NULL;

  path = strchop (path, path_get_delimiter (), 0);
  path = array_map (String_Type, &path_concat, path, executable);
  path = path [wherenot (array_map (Integer_Type, &_isdirectory, path))];

  ar = wherenot (array_map (Integer_Type, &access, path, X_OK));

  if (length (ar))
    return path[ar][0];
  else
    return NULL;
}

define readfile (file)
{
  variable
    end = qualifier ("end", NULL),
    fp = fopen (file, "r");

  if (NULL == fp)
    return NULL;

  ifnot (NULL == end)
    return array_map (String_Type, &strtrim_end, fgetslines (fp, end), "\n");

  return array_map (String_Type, &strtrim_end, fgetslines (fp), "\n");
}

define clear_stack ()
{
  variable d = _stkdepth () + 1;
  while (d--, d > 1)
    pop ();
}
