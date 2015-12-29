private define undo (u, v)
{
  if (-1 == u.__level || NULL == u.__rec[u.__level].data)
    return;

  u.__redo = @u.__rec[u.__level];

  if (0 == u.__rec[u.__level].blwise && u.__rec[u.__level].deleted)
    {
    v.lines = [u.__rec[u.__level].inds[0]
      ? v.lines[[:u.__rec[u.__level].inds[0] - 1]] : String_Type[0],
      u.__rec[u.__level].data, v.lines[[u.__rec[u.__level].inds[0]:]]];
    u.__redo.data = Null_Type[length (u.__rec[u.__level].inds)];
    }
  else
    {
%    IO.tostderr ("sec", u.__rec[u.__level].inds[0],
%                 u.__rec[u.__level].inds[-1]);
    u.__redo.data = v.lines[u.__rec[u.__level].inds];
    v.lines[u.__rec[u.__level].inds] = u.__rec[u.__level].data;
    }

  Ved.restorePos (v, u.__rec[u.__level].pos);

  v._len = length (v.lines) - 1;
  v.st_.st_size = Array.getsize (v.lines);

  u.__level--;

  v._flags |= VED_MODIFIED;

  v.draw ();
}
