private define shift (x, n) % code from upstream
{
  variable len = length(x);
  ifnot (len)
   return x;

  n = len + n mod len;
  x[[n:n+len-1] mod len];
}

__.sadd ("Array", "shift", "shift__", &shift);

private define __vedStorePos (v, pos)
{
  pos._i = qualifier ("_i", v._ii);
  pos.ptr = @v.ptr;
  pos._index = v._index;
  pos._findex = v._findex;
}

private define __vedRestorePos (v, pos)
{
  v._i = pos._i;
  v.ptr = pos.ptr;
  v._index = pos._index;
  v._findex = pos._findex;
}

private define __undoNew (u)
{
  variable i;
  _for i (0, 4)
    u.__rec[i] = struct {pos = @Pos_Type, data, inds, deleted};
}

private define __undoSet (u, v, data, inds)
{
  if (sum (array_map (Integer_Type, &strbytelen, data)) > 2048)
    return;

  u.__level += u.__level < length (u.__rec) - 1;

  ifnot (u.__level == length (u.__rec) - 1)
    {
    variable i;
    _for i (u.__level + 1, length (u.__rec) - 1)
      u.__rec[i].data = NULL;
    }

  IO.tostderr ("!bbb " , 0, u.__rec[0].data);
  IO.tostderr ("!bbb " , 1, u.__rec[1].data);
  IO.tostderr ("!bbb " , 2, u.__rec[2].data);
  IO.tostderr ("!bbb " , 3, u.__rec[3].data);
  IO.tostderr ("!bbb " , 4, u.__rec[4].data);
if (u.__level == length (u.__rec) - 1 && NULL != u.__rec[u.__level].data)
    u.__rec = Array.shift (u.__rec, 1);
  __vedStorePos (v, u.__rec[u.__level].pos;;__qualifiers);
  u.__rec[u.__level].data = data;
  u.__rec[u.__level].inds = inds;
  u.__rec[u.__level].deleted = qualifier_exists ("deleted");
  
  IO.tostderr ("bbb " , 0, u.__rec[0].data);
  IO.tostderr ("bbb " , 1, u.__rec[1].data);
  IO.tostderr ("bbb " , 2, u.__rec[2].data);
  IO.tostderr ("bbb " , 3, u.__rec[3].data);
  IO.tostderr ("bbb " , 4, u.__rec[4].data);
}

private define __undoBlockwise (u, v)
{
  if (-1 == u.__level || NULL == u.__rec[u.__level].data)
    return;

  if (Integer_Type == typeof (u.__rec[u.__level].inds))
    v.lines = [u.__rec[u.__level].inds
      ? v.lines[[:u.__rec[u.__level].inds - 1]] : String_Type[0],
      u.__rec[u.__level].data, v.lines[[u.__rec[u.__level].inds:]]];
  else
    v.lines[u.__rec[u.__level].inds] = u.__rec[u.__level].data;

  v._flags |= VED_MODIFIED;

  __vedRestorePos (v, u.__rec[u.__level].pos);

  u.__level--;

  v.draw ();
}

private define __redo (u, v)
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

  v.st_.st_size = getsizear (v.lines);

  v._flags |= VED_MODIFIED;

  __vedRestorePos (v, u.__redo.pos);

  u.__redo = NULL;

  u.__level++;

  v.draw ();
}

private define __undoLinewise (u, v)
{
IO.tostderr ("@u " , u.__level, u.__rec);
  if (-1 == u.__level || NULL == u.__rec[u.__level].data)
    return;

IO.tostderr ("undo " , 0, u.__rec[0].data, u.__rec[0].inds);
IO.tostderr ("undo " , 1, u.__rec[1].data, u.__rec[1].inds);
IO.tostderr ("undo " , 2, u.__rec[2].data, u.__rec[2].inds);
IO.tostderr ("undo " , 3, u.__rec[3].data, u.__rec[3].inds);
IO.tostderr ("undo " , 4, u.__rec[4].data, u.__rec[4].inds);
  u.__redo = @u.__rec[u.__level];

  if (u.__rec[u.__level].deleted)
    {
    v.lines = [u.__rec[u.__level].inds[0]
      ? v.lines[[:u.__rec[u.__level].inds[0] - 1]] : String_Type[0],
      u.__rec[u.__level].data, v.lines[[u.__rec[u.__level].inds[-1]:]]];
    u.__redo.data = Null_Type[length (u.__rec[u.__level].inds)];
    }
  else
    {
    u.__redo.data = v.lines[u.__rec[u.__level].inds];
    v.lines[u.__rec[u.__level].inds] = u.__rec[u.__level].data;
    }

  u.__redo.deleted = u.__rec[u.__level].deleted;

  __vedRestorePos (v, u.__rec[u.__level].pos);

  u.__level--;

  v._flags |= VED_MODIFIED;

IO.tostderr ("!undo " , 0, u.__rec[0].data, u.__rec[0].inds);
IO.tostderr ("!undo " , 1, u.__rec[1].data, u.__rec[1].inds);
IO.tostderr ("!undo " , 2, u.__rec[2].data, u.__rec[2].inds);
IO.tostderr ("!undo " , 3, u.__rec[3].data, u.__rec[3].inds);
IO.tostderr ("!undo " , 4, u.__rec[4].data, u.__rec[4].inds);
  v.draw ();
}

__.new ("vundo";methods = "new,undo,redo,set,undolw",
  funcs = ["__redo_", "__new", "__set___", "__undolw_"],
  refs = [&__redo, &__undoNew, &__undoSet, &__undoLinewise],
  vars = ["rec", "level", "redo"], values = {Struct_Type[5], 0, NULL},
  varself = "rec,level,redo");
