ifnot (is_defined ("vedloop"))
  {
  variable vedloop;
  variable getchar_lang;

  loadfile ("screenmangmnt", NULL, &exit_on_eval_err);
  loadfile ("vedfuncs", NULL, &exit_on_eval_err);
  loadfile ("viewer", NULL, &exit_on_eval_err);

  ifnot (DRAWONLY)
    {
    importfrom ("std", "fork", NULL, &exit_on_eval_err);
    importfrom ("std", "pcre", NULL, &exit_on_eval_err);

    loadfrom ("input", "inputInit", 1, &exit_on_eval_err);

    loadfrom ("proc", "procInit", 1, &exit_on_eval_err);
    loadfile ("writetofile", NULL, &exit_on_eval_err);
    loadfile ("diff", NULL, &exit_on_eval_err);
    loadfile ("undo", NULL, &exit_on_eval_err);
    loadfile ("search", NULL, &exit_on_eval_err);
    loadfile ("rline", NULL, &exit_on_eval_err);
    loadfile ("visual_mode", NULL, &exit_on_eval_err);
    loadfile ("ed", NULL, &exit_on_eval_err);

    ifnot (NULL == DISPLAY)
      ifnot (NULL == which ("xclip"))
        loadfile ("seltoX", NULL, &exit_on_eval_err);
    }

  pagerc = array_map (Integer_Type, &integer, assoc_get_keys (pagerf));
  }

