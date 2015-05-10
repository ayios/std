define sl_lexicalhl ();

loadfile ("sl_syntax", NULL, &on_eval_err);

define sl_settype (s, fname, rows, lines)
{
  s.lexicalhl = &sl_lexicalhl;
  
  s._autoindent = 1;
  s._maxlen = COLUMNS;
  s._fname = fname;

  s.st_ = stat_file (s._fname);
  if (NULL == s.st_)
    s.st_ = struct
      {
      st_atime,
      st_mtime,
      st_uid = getuid (),
      st_gid = getgid (),
      st_size = 0
      };

  s.rows = rows;
  s._indent = 0;
  s._shiftwidth = 2;
  s._linlen = s._maxlen - s._indent;
  s.lines = NULL == lines ? getlines (s._fname, s._indent, s.st_) : lines;
  s._flags = 0;
 
  s.ptr = Integer_Type[2];

  s._len = length (s.lines) - 1;
  s.cols = Integer_Type[length (s.rows)];
  s.cols[*] = 0;
  s.clrs = Integer_Type[length (s.rows)];
  s.clrs[*] = 0;
  s.clrs[-1] = INFOCLRFG;
  s._avlins = length (s.rows) - 2;
  s.ptr[0] = s.rows[0];
  s.ptr[1] = s._indent;
  s._findex = s._indent;
  s._index = s._indent;
  s.undo = String_Type[0];
  s._undolevel = 0;
  s.undoset = {};

  s._i = 0;
}
