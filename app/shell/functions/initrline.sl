define _shell_ (argv)
{
  shell_pre_header ("shell");
  runapp ([argv], NULL;;__qualifiers ());
  shell_post_header ();
  draw (get_cur_buf ());
}

private define _echo_ (argv)
{
  _builtinpre_ (argv);

  argv = argv[[1:]];

  variable hasnewline = wherefirst ("-n" == argv);
 
  ifnot (NULL == hasnewline)
    {
    argv[hasnewline] = NULL;
    argv = argv[wherenot (_isnull (argv))];
    hasnewline = "";
    }
  else
    hasnewline = "\n";

  variable len = length (argv);

  ifnot (len)
    return;

  if (1 == len)
    {
    if ('>' == argv[0][0])
      return;

    if ('$' == argv[0][0])
      if ('?' == argv[0][1])
        tostdout (string (SHELLLASTEXITSTATUS) + hasnewline);
      else
        tostdout (_$ (argv[0]) + hasnewline);
    else
      tostdout (argv[0] + hasnewline);
    }
  else
    {
    variable file, flags, retval;
    (file, flags, retval) = parse_argv (argv, 0);

    if (-1 == retval)
      {
      _builtinpost_ ();
      SHELLLASTEXITSTATUS = 1;
      return;
      }
 
    ifnot (retval)
      {
      tostdout (strjoin (argv, " ") + hasnewline);
      _builtinpost_ ();
      return;
      }

    argv[-1] = NULL;
    argv = argv[wherenot (_isnull (argv))];

    if (">>" == flags || 0 == access (file, F_OK))
      {
      if (-1 == appendstr (file, strjoin (argv, " ") + hasnewline))
       return;
      }
    else
      {
      variable fd = open (file, O_CREAT|O_WRONLY, PERM["__PUBLIC"]);
      if (NULL == fd)
        tostderr (file + ":" + errno_string (errno));
      else
        if (-1 == write (fd, strjoin (argv, " ") + hasnewline))
          tostderr (file + ":" + errno_string (errno));
        else
          if (-1 == close (fd))
            tostderr (file + ":" + errno_string (errno));
      }
    }
 
  _builtinpost_ ();
}

private define _intro_ (argv)
{
  intro (get_cur_rline (), get_cur_buf ());
}

private define _rehash_ ();

private define my_commands ()
{
  variable a = init_commands ();
 
  a["echo"] = @Argvlist_Type;
  a["echo"].func = &_echo_;

  a["rehash"] = @Argvlist_Type;
  a["rehash"].func = &_rehash_;
 
  a["intro"] = @Argvlist_Type;
  a["intro"].func = &_intro_;

  a["shell"] = @Argvlist_Type;
  a["shell"].func = &_shell_;

  return a;
}

private define filtercommands (s, ar)
{
  ar = ar[where (1 < strlen (ar))];
  return ar;
}

private define filterargs (s, args, type, desc)
{
  return [args, "--sudo", "--pager"], [type, "void", "void"],
    [desc, "execute command as superuser", "viewoutput in a scratch buffer"];
}

private define tabhook (s)
{
  ifnot (s._ind)
    return -1;
 
  ifnot (s.argv[0] == "killbgjob")
    return -1;

  variable pids = assoc_get_keys (BGPIDS);

  ifnot (length (pids))
    return -1;
 
  variable i;
  _for i (0, length (pids) - 1)
    pids[i] = pids[i] + " void " + strjoin (BGPIDS[pids[i]].argv, " ");

  return rline->argroutine (s;args = pids, accept_ws);
}

define rlineinit ()
{
  variable rl = rline->init (&my_commands;;struct
    {
    @__qualifiers (),
    histfile = HISTDIR + "/" + string (getuid ()) + "shellhistory",
    filtercommands = &filtercommands,
    filterargs = &filterargs,
    tabhook = &tabhook,
    onnolength = &toplinedr,
    onnolengthargs = {""},
    on_lang = &toplinedr,
    on_lang_args = {" -- shell --"}
    });
 
  iarg = length (rl.history);

  return rl;
}

private define _rehash_ (argv)
{
  get_cur_rline ().argvlist = my_commands ();
}

define runcom (argv, issudo)
{
  variable rl = rlineinit ();

  ifnot (any (assoc_get_keys (rl.argvlist) == argv[0]))
    {
    tostderr (argv[0] + ": no such command");
    return;
    }

  rl.argv = argv;

  (@rl.argvlist[argv[0]].func) (rl.argv;;struct {issudo = issudo, @__qualifiers ()});
}
