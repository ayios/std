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
  regstd,
  args,
  } Action_Type;

private variable _L_ = Assoc_Type[Lib_Type];

static define __init__ (pgnam)
{
  variable s = @Lib_Type;
%  s.keys = Assoc_Type[Action_Type];
%  s.keys["key"].func = &_null_;
%  s = struct {std[fields]};
%  f = qualifier ("features");
%  _for i (0, length (f) - 1)
%  s = {@s, f}; % growstruct ()
}

% is under resuming => var
% get lines -> return an array

% list type for the stack
% l = __pop_list( 
%            __push_list ({11,12,13,14,10}),
%            v = _stkdepth () ,
%            _stk_roll (v),
%            v));

