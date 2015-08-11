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

  variable w = get_cur_wind ();

  ifnot (any (w.bufnames == absfname))
    {
    variable ft = get_ftype (fname);
    s = init_ftype (ft);
    variable func = __get_reference (sprintf ("%s_settype", ft));
    (@func) (s, fname, w.frame_rows[get_cur_frame ()], NULL);
    setbuf (s._absfname);

    write_prompt (" ", 0);

    s.draw ();

    w.frame_names[get_cur_frame ()] = s._absfname;
    }
  else
    {
    s = w.buffers[absfname];
 
    w.frame_names[get_cur_frame ()] = s._absfname;
    setbuf (s._absfname);

    write_prompt (" ", 0);
    s._i = s._ii;
    s.draw ();
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
  variable s = get_cur_buf ();

  ifnot (_NARGS)
    bufname = s._absfname;
  else
    bufname = ();

  bufdelete (s, bufname, 0);
}

VED_CLINE["e"] = &_edit_other;
VED_CLINE["b"] = &_edit_other;
VED_CLINE["bd"] = &_bdelete;
