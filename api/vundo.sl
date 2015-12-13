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
    u.__rec[i] = struct {pos = @Pos_Type, data, inds};
}

private define __undoSet (u, v, data, inds)
{
  IO.tostderr ("set ", u.__level);
  u.__level += u.__level < length (u.__rec) - 1;

  IO.tostderr ("b " , u.__level);
  if (u.__level == length (u.__rec) - 1)
    u.__rec = Array.shift (u.__rec, 1);
  else
    {
    variable i;
    _for i (u.__level + 1, length (u.__rec) - 1)
      u.__rec[i].data = NULL;
    }

  __vedStorePos (v, u.__rec[u.__level].pos;;__qualifiers);

  u.__rec[u.__level].data = data;
  u.__rec[u.__level].inds = inds;
}

private define __undo (u, v)
{
  if (NULL == u.__rec[u.__level].data)
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
  if (length (u.__rec) - 1 == u.__level || NULL == u.__rec[u.__level + 1].data)
    return;

  u.__level++;

  if (Integer_Type == typeof (u.__rec[u.__level].inds))
    v.lines = [u.__rec[u.__level].inds
      ? v.lines[[:u.__rec[u.__level].inds - 1]] : String_Type[0],
      u.__rec[u.__level].data, v.lines[[u.__rec[u.__level].inds:]]];
  else
    v.lines[u.__rec[u.__level].inds] = u.__rec[u.__level].data;

  v._flags |= VED_MODIFIED;

  __vedRestorePos (v, u.__rec[u.__level].pos);

  v.draw ();
}

__.new ("vundo";methods = "new,undo,redo,set",
  funcs = ["__redo_", "__undo_", "__new", "__set___"],
  refs = [&__redo, &__undo, &__undoNew, &__undoSet],
  vars = ["rec", "level"], values = {Struct_Type[5], 0},
  varself = "rec,level");
