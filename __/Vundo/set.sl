private define set (u, v, data, inds)
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

  Ved.storePos (v, u.__rec[u.__level].pos;;__qualifiers);
  u.__rec[u.__level].data = data;
  u.__rec[u.__level].inds = inds;
  u.__rec[u.__level].deleted = qualifier_exists ("deleted");
  u.__rec[u.__level].blwise = qualifier_exists ("blwise");
}

