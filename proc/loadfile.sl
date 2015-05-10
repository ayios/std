private variable file = __argv[1];

__set_argc_argv (__argv[[1:]]);

() = evalfile (path_dirname (__FILE__) + "/../load");

define on_eval_err ()
{
  exit (1);
}

try
  loadfrom ("stdio", "ar_to_fp", NULL, NULL);
catch ParseError:
  on_eval_err ();

define on_eval_err (msg, err)
{
  () = ar_to_fp (msg, "%s\n", stderr);
  exit (err);
}
 
% for now NULL
loadfile (file, NULL, &on_eval_err);

%define _usage ()
%{
%  variable
%    if_opt_err = _NARGS ? () : " ",
%    infodir = path_dirname (__argv[0]) + "/../info/" + path_basename (__argv[0]),
%    helpfile = qualifier ("helpfile", sprintf ("%s/help.txt", infodir)),
%    ar = _NARGS ? [if_opt_err] : String_Type[0];
%
%  if (NULL == helpfile)
%    {
%    () = fprintf (stderr, "No Help file available for %s\n", path_basename (__argv[0]));
%    exit (1);
%    }
%
%  ifnot (access (helpfile, F_OK))
%    ar = [ar, readfile (helpfile)];
%
%  ifnot (length (ar))
%    {
%    () = fprintf (stderr, "No Help file available for %s\n", path_basename (__argv[0]));
%    exit (1);
%    }
%
%  () = ar_to_fp ([sprintf ("Help for %s", path_basename (__argv[0])), ar], "%s\n", stdout);
%
%  exit (_NARGS);
%}
%
%define info ()
%{
%  variable
%    infodir = path_dirname (__argv[0]) + "/../info/" + path_basename (__argv[0]),
%    infofile = qualifier ("helpfile", sprintf ("%s/desc.txt", infodir)),
%    ar;
%
%  if (NULL == infofile || -1 == access (infofile, F_OK))
%    {
%    () = fprintf (stderr, "No Info file available for %s\n", path_basename (__argv[0]));
%    exit (1);
%    }
%
%  ifnot (access (infofile, F_OK))
%    ar = readfile (infofile);
%
%  if (0 == length (ar) || NULL == ar)
%    {
%    () = fprintf (stderr, "No Info file available for %s\n", path_basename (__argv[0]));
%    exit (1);
%    }
%
%  () = ar_to_fp ([sprintf ("Info for %s", path_basename (__argv[0])), ar], "%s\n", stdout);
%
%  exit (0);
%}
%
%try
%  {
%  () = evalfile (func);
%  }
%catch AnyError:
%  {
%  () = ar_to_fp (exception_to_array (), "%s\n", stdout);
%  exit (1);
%  }

