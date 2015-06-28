define _exit_me_ (argv)
{
  variable rl = qualifier ("rl");

  ifnot (NULL == rl)
    rline->writehistory (rl.history, rl.histfile);

  exit_me (0);
}

define init_commands ()
{
  variable
    i,
    a = Assoc_Type[Argvlist_Type, @Argvlist_Type],
    apps = assoc_get_keys (APPS);

  _for i (0, length (apps) - 1)
    {
    variable app = apps[i];;

    a[app] = @Argvlist_Type;
    a[app].func = &os->runapp;
    a[app].type = "Func_Type";
    }

  a["quit"] = @Argvlist_Type;
  a["quit"].func = &_exit_me_;

  a["eval"] = @Argvlist_Type;
  a["eval"].func = &_eval_;
  
  a["messages"] = @Argvlist_Type;
  a["messages"].func = &_messages_;

  return a;
}

define initrline ()
{
  variable rl = rline->init (&init_commands;
    histfile = HISTDIR + "/." + string (OSUID) + "oshistory",
    on_lang = &toplinedr,
    on_lang_args = " -- OS CONSOLE --");
 
  return rl;
}
