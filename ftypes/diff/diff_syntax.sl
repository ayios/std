private variable colors = [
%header
  14,
%lines
  13,
%-
  COLOR.diffmn,
%+
  COLOR.diffpl,
];

private variable regexps = [
%header
  pcre_compile ("\
(^(diff.*$)\
|^(---.*$)\
|^(\+\+\+.*$))+"R, 0),
% lines
  pcre_compile ("\
(^(@@.*@@))+"R, 0),
% -
  pcre_compile ("\
(^(-(?!-).*))+"R, 0),
% +
  pcre_compile ("\
(^(\+(?!\+).*))+"R, 0),
];

define diff_lexicalhl (s, lines, vlines)
{
  __hl_groups (lines, vlines, colors, regexps);
}
