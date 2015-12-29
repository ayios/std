private define storePos (v, pos)
{
  pos._i = qualifier ("_i", v._ii);
  pos.ptr = @v.ptr;
  pos._index = v._index;
  pos._findex = v._findex;
}

