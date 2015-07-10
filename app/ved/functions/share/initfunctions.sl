ifnot (VED_INITDONE)
  {
  loadfrom ("smg", "widg", "widg", &on_eval_err);
  loadfile ("screenmngmnt", NULL, &on_eval_err);
  loadfile ("vedfuncs", NULL, &on_eval_err);
  loadfile ("deftype", NULL, &on_eval_err);
  loadfile ("viewer", NULL, &on_eval_err);
  loadfile ("bufmngmnt", NULL, &on_eval_err);

  ifnot (VED_DRAWONLY)
    {
    importfrom ("std", "fork", NULL, &on_eval_err);
    importfrom ("std", "pcre", NULL, &on_eval_err);

    loadfrom ("input", "inputInit", NULL, &on_eval_err);

    ifnot (is_defined ("topline"))
      loadfrom ("wind", "vedTopline", NULL, &on_eval_err);
 
    loadfrom ("proc", "procInit", 1, &on_eval_err);

    loadfile ("writetofile", NULL, &on_eval_err);
    loadfile ("diff", NULL, &on_eval_err);
    loadfile ("undo", NULL, &on_eval_err);
    loadfile ("search", NULL, &on_eval_err);
 
    if (VED_RLINE)
      {
      if (VED_EDITOTHER)
        loadfile ("addfname", NULL, &on_eval_err);
 
      loadfrom ("rline", "rlineInit", 1, &on_eval_err);
      loadfile ("initrline", NULL, &on_eval_err);
      loadfile ("vedrline", NULL, &on_eval_err);
      }

    loadfile ("visual_mode", NULL, &on_eval_err);
    loadfile ("ed", NULL, &on_eval_err);
    loadfile ("preloop", NULL, &on_eval_err);

    ifnot (NULL == DISPLAY)
      ifnot (NULL == XAUTHORITY)
        ifnot (NULL == XCLIP_BIN)
          loadfrom ("X", "seltoX", NULL, &on_eval_err);
    }

  VED_INITDONE = 1;
  }

