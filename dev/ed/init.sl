typedef struct
  {
  resume,
  _resume,
  main,
  keys,
  } Lib_Type;

private define _null_ ()
{
%CLEAR
}

typedef struct
  {
  func,
  args,
  } Action_Type;

private variable _L_ = Assoc_Type[Lib_Type];

static define __init__ (pgnam)
{
  variable s = @Lib_Type;
  s.keys = Assoc_Type[Action_Type];
  s.keys.func = &_null_;
}

% is under resuming => var
% get lines -> return an array
