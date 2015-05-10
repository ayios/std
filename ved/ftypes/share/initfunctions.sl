ifnot (is_defined ("vedloop"))
  {
  variable vedloop;
  variable getchar_lang;

  loadfile ("screenmangmnt", NULL, &on_eval_err);
  loadfile ("vedfuncs", NULL, &on_eval_err);
  loadfile ("viewer", NULL, &on_eval_err);

  ifnot (DRAWONLY)
    {
    importfrom ("std", "fork", NULL, &on_eval_err);
    importfrom ("std", "pcre", NULL, &on_eval_err);

    loadfrom ("input", "inputInit", 1, &on_eval_err);

    loadfrom ("proc", "procInit", 1, &on_eval_err);
    loadfile ("writetofile", NULL, &on_eval_err);
    loadfile ("diff", NULL, &on_eval_err);
    loadfile ("undo", NULL, &on_eval_err);
    loadfile ("search", NULL, &on_eval_err);
    loadfile ("rline", NULL, &on_eval_err);
    loadfile ("visual_mode", NULL, &on_eval_err);
    loadfile ("ed", NULL, &on_eval_err);

    ifnot (NULL == DISPLAY)
      ifnot (NULL == which ("xclip"))
        loadfile ("seltoX", NULL, &on_eval_err);
    }

  pagerc = array_map (Integer_Type, &integer, assoc_get_keys (pagerf));
  }

