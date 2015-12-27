__.sadd ("Array", "shift", "shift__", NULL);

define __vedRestorePos ();
define __vedStorePos ();

private define __undoSet (u, v, data, inds)
{
  if (sum (array_map (Integer_Type, &strbytelen, data)) > 2048)
    return;

  u.__level += u.__level < length (u.__rec) - 1;

  variable i;
  ifnot (u.__level == length (u.__rec) - 1)
    _for i (u.__level + 1, length (u.__rec) - 1)
      u.__rec[i].data = NULL;

  if (u.__level == length (u.__rec) - 1 && NULL != u.__rec[u.__level].data)
    u.__rec = Array.shift (u.__rec, 1);

  __vedStorePos (v, u.__rec[u.__level].pos;;__qualifiers);
  u.__rec[u.__level].data = data;
  u.__rec[u.__level].inds = inds;
  u.__rec[u.__level].deleted = qualifier_exists ("deleted");
  u.__rec[u.__level].blwise = qualifier_exists ("blwise");
}

private define __undo (u, v)
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

  __vedRestorePos (v, u.__rec[u.__level].pos);

  v._len = length (v.lines) - 1;
  v.st_.st_size = getsizear (v.lines);

  u.__level--;

  v._flags |= VED_MODIFIED;

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

__.new ("vundo";methods = "undo,redo,set",
  funcs = ["__undo_", "__redo_", "__set___"],
  refs = [&__undo, &__redo, &__undoSet],
  vars = ["rec", "level", "redo"], values = {Struct_Type[5], 0, NULL},
  varself = "rec,level,redo");

vundo.__rec = Struct_Type[3];
vundo.__rec[0] = struct {pos = @Pos_Type, data, inds, deleted, blwise};
vundo.__rec[1] = struct {pos = @Pos_Type, data, inds, deleted, blwise};
vundo.__rec[2] = struct {pos = @Pos_Type, data, inds, deleted, blwise};
