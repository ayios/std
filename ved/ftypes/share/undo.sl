define set_modified ()
{
  variable
    retval,
    d = diff (strjoin (cf_.lines, "\n") + "\n", cf_._fname, &retval);

  if (NULL == retval)
    {
    send_msg_dr (d, 1, cf_.ptr[0], cf_.ptr[1]);
    return;
    }
 
  if (-1 == retval)
    {
    % change
    send_msg_dr (d, 1, cf_.ptr[0], cf_.ptr[1]);
    return;
    }

  ifnot (retval)
    {
    send_msg_dr ("found no changes", 0, cf_.ptr[0], cf_.ptr[1]);
    return;
    }

  cf_._flags = cf_._flags | MODIFIED;
 
  cf_.undo = [cf_.undo, d];
  list_append (cf_.undoset, [qualifier ("_i", cf_._ii), cf_.ptr[0], cf_.ptr[1]]);

  cf_._undolevel++;
}

private define undo ()
{
  ifnot (length (cf_.undo))
    return;

  variable
    retval,
    in,
    d;
 
  if (0 == cf_._undolevel)
    {
    cf_.lines = getlines (cf_._fname, cf_._indent, cf_.st_);
    cf_._len = length (cf_.lines) - 1;
    cf_._i = cf_._ii;
    cf_.draw ();
    return;
    }

  in = cf_.undo[cf_._undolevel - 1];

  d = patch (in, path_dirname (cf_._fname), &retval);
 
  if (NULL == retval)
    {
    send_msg_dr (d, 1, cf_.ptr[0], cf_.ptr[1]);
    return;
    }
 
  if (-1 == retval || 1 == retval)
    {
    % change
    send_msg_dr (d, 1, cf_.ptr[0], cf_.ptr[1]);
    return;
    }

  cf_.lines = strchop (d, '\n', 0);
  cf_._len = length (cf_.lines) - 1;
 
  cf_._i = cf_.undoset[cf_._undolevel - 1][0];
  cf_.ptr[0] = cf_.undoset[cf_._undolevel - 1][1];
  cf_.ptr[1] = cf_.undoset[cf_._undolevel - 1][2];

  cf_._undolevel--;
 
  cf_._flags = cf_._flags | MODIFIED;

  cf_.draw ();
}

private define redo ()
{
  if (cf_._undolevel == length (cf_.undo))
    return;

  variable
    retval,
    in = cf_.undo[cf_._undolevel],
    d;

  d = patch (in, path_dirname (cf_._fname), &retval);
 
  if (NULL == retval)
    {
    send_msg_dr (d, 1, cf_.ptr[0], cf_.ptr[1]);
    return;
    }
 
  if (-1 == retval || 1 == retval)
    {
    % change
    send_msg_dr (d, 1, cf_.ptr[0], cf_.ptr[1]);
    return;
    }
 
  cf_.lines = strchop (d, '\n', 0);
  cf_._len = length (cf_.lines) - 1;

  cf_._i = cf_.undoset[cf_._undolevel][0];
  cf_.ptr[0] = cf_.undoset[cf_._undolevel][1];
  cf_.ptr[1] = cf_.undoset[cf_._undolevel][2];

  cf_._undolevel++;

  cf_._flags = cf_._flags | MODIFIED;

  cf_.draw ();
}

pagerf[string ('u')] = &undo;
pagerf[string (keys->CTRL_r)] = &redo;
