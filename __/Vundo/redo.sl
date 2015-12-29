private define redo (u, v)
{
  if (NULL == u.__redo)
    return;

  if (u.__redo.deleted)
    {
    v.lines[u.__redo.inds] = u.__redo.data;
    v.lines = v.lines[wherenot (_isnull (v.lines))];
    v._len = length (v.lines) - 1;
    }
  else
    v.lines[u.__redo.inds] = u.__redo.data;

  v.st_.st_size = Array.getsize (v.lines);

  v._flags |= VED_MODIFIED;

  Ved.restorePos (v, u.__redo.pos);

  u.__redo = NULL;

  u.__level++;

  v.draw ();
}
