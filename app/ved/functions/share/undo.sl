define set_modified (s)
{
  variable
    retval,
    d = diff (strjoin (s.lines, "\n") + "\n", s._absfname, &retval);

  if (NULL == retval)
    {
    send_msg_dr (d, 1, s.ptr[0], s.ptr[1]);
    return;
    }
 
  if (-1 == retval)
    {
    % change
    send_msg_dr (d, 1, s.ptr[0], s.ptr[1]);
    return;
    }

  ifnot (retval)
    {
    send_msg_dr ("found no changes", 0, s.ptr[0], s.ptr[1]);
    return;
    }

  s._flags |= VED_MODIFIED;
 
  s.undo = [s.undo, d];
  list_append (s.undoset, [qualifier ("_i", s._ii), s.ptr[0], s.ptr[1]]);

  s._undolevel++;
}

private define undo (s)
{
  ifnot (length (s.undo))
    return;

  variable
    retval,
    in,
    d;
 
  if (0 == s._undolevel)
    {
    s.lines = getlines (s._absfname, s._indent, s.st_);
    s._len = length (s.lines) - 1;
    s._i = s._ii;
    s.draw ();
    return;
    }

  in = s.undo[s._undolevel - 1];

  d = patch (in, s._dir, &retval);
 
  if (NULL == retval)
    {
    send_msg_dr (d, 1, s.ptr[0], s.ptr[1]);
    return;
    }
 
  if (-1 == retval || 1 == retval)
    {
    % change
    send_msg_dr (d, 1, s.ptr[0], s.ptr[1]);
    return;
    }

  s.lines = strchop (d, '\n', 0);
  s._len = length (s.lines) - 1;
 
  s._i = s.undoset[s._undolevel - 1][0];
  s.ptr[0] = s.undoset[s._undolevel - 1][1];
  s.ptr[1] = s.undoset[s._undolevel - 1][2];

  s._undolevel--;
 
  s._flags |= VED_MODIFIED;

  s.draw ();
}

private define redo (s)
{
  if (s._undolevel == length (s.undo))
    return;

  variable
    retval,
    in = s.undo[s._undolevel],
    d;

  d = patch (in, path_dirname (s._fname), &retval);
 
  if (NULL == retval)
    {
    send_msg_dr (d, 1, s.ptr[0], s.ptr[1]);
    return;
    }
 
  if (-1 == retval || 1 == retval)
    {
    % change
    send_msg_dr (d, 1, s.ptr[0], s.ptr[1]);
    return;
    }
 
  s.lines = strchop (d, '\n', 0);
  s._len = length (s.lines) - 1;

  s._i = s.undoset[s._undolevel][0];
  s.ptr[0] = s.undoset[s._undolevel][1];
  s.ptr[1] = s.undoset[s._undolevel][2];

  s._undolevel++;

  s._flags |= VED_MODIFIED;

  s.draw ();
}

VED_PAGER[string ('u')] = &undo;
VED_PAGER[string (keys->CTRL_r)] = &redo;
