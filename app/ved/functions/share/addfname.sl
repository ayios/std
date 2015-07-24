define addfname (fname)
{
  variable absfname;
  variable s;

  ifnot (path_is_absolute (fname))
    absfname = getcwd + fname;
  else
    absfname = fname;

  if (_isdirectory (fname))
    return;

  ifnot (any (VED_BUFNAMES == absfname))
    {
    s = init_ftype (get_ftype (fname));

    s.ved (fname);
    }
  else
    {
    s = VED_BUFFERS[absfname];
 
    setbuf (s._absfname);

    write_prompt (" ", 0);

    s.draw ();
    s.vedloop ();
    }
}

private define _edit_other ()
{
  ifnot (_NARGS)
    return;

  variable fname = ();

  addfname (fname);
}

private define _bdelete ()
{
  variable bufname;
  variable s = qualifier ("ved");

  ifnot (_NARGS)
    bufname = s._absfname;
  else
    bufname = ();

  bufdelete (s, bufname, 0);
}

VED_CLINE["e"] = &_edit_other;
VED_CLINE["b"] = &_edit_other;
VED_CLINE["bd"] = &_bdelete;
