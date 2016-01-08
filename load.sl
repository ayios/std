() = evalfile (path_dirname (__FILE__) + "/__/__");

Use ("Env");
Use ("Dir");
Use ("File");
Use ("Sys");
Use ("load");

$1 = path_concat (getcwd (), path_dirname (__FILE__));

if ($1[[-2:]] == "/.")
  $1 = substr ($1, 1, strlen ($1) - 2);

$1 += "/..";

try
  import ($1 + "/modules/" + uname.machine + "/std/ayios");
catch ImportError:
  {
  IO.tostderr (__get_exception_info.message);
  exit (1);
  }

$1 = realpath ($1);

set_slang_load_path ("");
set_import_module_path ("");


Env->New (;
  vars = ["HOME", "MACHINE", "OS", "PID", "gid", "uid", "PATH",
    "TERM", "LANG", "display", "xauthority", "group",
    "user", "SLSH_LIB_DIR", "SLANG_MODULE_PATH", "ISSUPROC"],
  values = {getenv ("HOME"), uname.machine, uname.sysname, getpid, getgid, getuid,
    getenv ("PATH"), getenv ("TERM"), getenv ("LANG"),
    getenv ("DISPLAY"), getenv ("XAUTHORITY"), NULL, NULL, get_slang_load_path (),
    get_import_module_path (), getuid ? 0 : 1});

Dir->New (;
  vars = ["ROOTDIR", "ADIR", "STDDIR", "USRDIR", "LCLDIR", "MDLDIR", "STDDATADIR",
    "USRDATADIR", "LCLDATADIR", "HISTDIR", "SOURCEDIR", "TEMPDIR"],
  values = {$1, $1, $1 + "/std", $1 + "/usr", $1 + "/local",
    $1 + "/modules/" + Env->Vget ("MACHINE"), $1 + "/std/share/data",
    $1 + "/usr/share/data", $1 + "/local/share/data",
    $1 + "/local/share/history", $1, $1 + "/tmp"});

$1 = Assoc_Type[Integer_Type];
$1["<"]    =                   O_RDONLY;
$1[">>"]   =          O_WRONLY|O_APPEND;
$1[">"]    =           O_WRONLY|O_CREAT;
$1[">|"]   =   O_WRONLY|O_CREAT|O_TRUNC;
$1[">>|"]  =  O_WRONLY|O_CREAT|O_APPEND;
$1["<>>"]  =            O_RDWR|O_APPEND;
$1["<>"]   =             O_RDWR|O_CREAT;
$1["<>>|"] =    O_RDWR|O_CREAT|O_APPEND;
$1["<>|"]  =     O_RDWR|O_CREAT|O_TRUNC;

$2 = Assoc_Type[Integer_Type];
$2["PRIVATE"]  =                        S_IRWXU; % 0700
$2["_PRIVATE"] =                S_IRUSR|S_IWUSR; % 0600
$2["STATIC"]   = $2["PRIVATE"] |        S_IRWXG; % 0770
$2["_STATIC"]  = $2["PRIVATE"] |S_IRGRP|S_IXGRP; % 0750
$2["__STATIC"] = $2["_PRIVATE"]|        S_IRGRP; % 0640
$2["PUBLIC"]   = $2["STATIC"]  |        S_IRWXO; % 0777
$2["_PUBLIC"]  = $2["_STATIC"] |S_IROTH|S_IXOTH; % 0755
$2["__PUBLIC"] = $2["__STATIC"]|        S_IROTH; % 0644
$2["___PUBLIC"]= $2["_PRIVATE"]|S_IWGRP|S_IWOTH; % 0622

File->New (;vars = ["FLAGS", "PERM"], values = [$1, $2], ConstVar = 1);

array_map (&__uninitialize, [&$1, &$2]);

public variable LINES;
public variable COLUMNS;
public variable SLSH_BIN;
public variable SUDO_BIN;

__use_namespace ("load");

private variable __LOADED__ = Assoc_Type[Integer_Type, 0];

private define __load__ ()
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

  if (__LOADED__[lib] && 0 == qualifier_exists ("force"))
    return __get_reference (ns + "->" + fun);

  try
    {
    () = evalfile (file, ns);
    }
  catch OpenError:
    throw __Error, "LoadOpenError::" + _function_name, __get_exception_info;
  catch ParseError:
    throw __Error, "LoadParseError::" + _function_name, __get_exception_info;
  catch RunTimeError:
    throw __Error, "LoadRunTimeError::" + _function_name, __get_exception_info;

  __LOADED__[lib] = 1;

  __get_reference (ns + "->" + fun);
}

private define __findns__ (ns, lns, lib)
{
  variable foundlib = NULL;
  variable foundns = NULL;
  variable i;
  variable nss = [Dir->Vget ("ADIR"), Dir->Vget ("LCLDIR"),
    Dir->Vget ("STDDIR"), Dir->Vget ("USRDIR")];

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
    throw __Error, "LoadOpenError::" + _function_name + ":: (load error) " +
       ns + ", no such namespace", NULL;

  if (NULL == foundlib)
    throw __Error, "LoadOpenError::" + _function_name + ":: (load error) " +
      lib + ", no such library", NULL;
}

private define __loadfrom__ (ns, lib, dons)
{
  variable lns;

  __findns__ (ns, &lns, lib);

  ns = NULL == dons
    ? NULL
    : Integer_Type == typeof (dons)
      ? 1 == dons
        ? ns
        : NULL
      : any ([String_Type, BString_Type] == typeof (dons))
        ? dons
        : NULL;

  () = __load__ (lns + "/" + lib, ns;;struct {fun = "", @__qualifiers});
}

private define __importfrom__ (ns, module, dons)
{
  variable lns = Dir->Vget ("MDLDIR") + "/" + ns;

  if (-1 == access (lns, F_OK))
    throw __Error, "LoadImportOpenError::" + _function_name + ":: (import) " + ns +
      " :no such namespace", NULL;

  ifnot (NULL == dons)
    import (lns + "/" + module, dons);
  else
    import (lns + "/" + module, "Global");
}

private define __getref__ (ns, lib, dons)
{
  variable fun = qualifier ("fun", "main");
  variable lns;

  __findns__ (ns, &lns, lib);

  ns = NULL == dons
    ? NULL
    : Integer_Type == typeof (dons)
      ? 1 == dons
        ? ns
        : NULL
      : any ([String_Type, BString_Type] == typeof (dons))
        ? dons
        : NULL;

  __load__ (lns + "/" + lib, ns;;struct {fun = fun, @__qualifiers});
}

private define __loadfile__ (file, ns)
{
  () = __load__ (file, ns;;struct {fun = "", @__qualifiers});
}

load->New (;
  funcs = ["from___", "module___", "file__", "getref___"],
  refs =  [&__loadfrom__, &__importfrom__, &__loadfile__, &__getref__],
  methods = "from,module,file,getref");

private define which (executable)
{
  variable
    ar,
    st,
    path = Env->Vget ("PATH");

  if (NULL == path)
    return NULL;

  path = strchop (path, path_get_delimiter (), 0);
  path = array_map (String_Type, &path_concat, path, executable);
  path = path [wherenot (array_map (Integer_Type, &_isdirectory, path))];

  ar = wherenot (array_map (Integer_Type, &access, path, X_OK));

  if (length (ar))
    path[ar][0];
  else
    NULL;
}

Sys->New (;funcs = ["which_"], refs = [&which]);

private define readfile (file)
{
  variable
    end = qualifier ("end", NULL),
    fp = fopen (file, "r");

  if (NULL == fp)
    return NULL;

  ifnot (NULL == end)
    array_map (String_Type, &strtrim_end, fgetslines (fp, end), "\n");
  else
    array_map (String_Type, &strtrim_end, fgetslines (fp), "\n");
}

IO->Fun ("readfile_", &readfile);

__use_namespace ("Global");

define clear_stack ()
{
  variable d = _stkdepth + 1;
  while (d--, d > 1)
    pop ();
}

define istype (mode, type)
{
  NULL == mode ? 0 : stat_is (type, mode);
}
