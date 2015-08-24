private variable colors = [
%functions
  14,
%conditional
  13,
%type
  12,
%errors
  17,
%comments
  3,
];

private variable regexps = [
%functions
  pcre_compile ("\
((evalfile(?=\s))\
|(?<!\w)(sigprocmask(?=\s))\
|(?<!\w)(\(\)(?=\s))\
|(?<!\w)(loadfile(?=\s))\
|(?<!\w)(loadfrom(?=\s))\
|(?<!\w)(importfrom(?=\s))\
|(?<!\w)(loadfile(?=\s))\
|(?<!\w)(fork(?=\s))\
|(?<!\w)(pipe(?=\s))\
|(?<!\w)(execv(?=\s))\
|(?<!\w)(execve(?=\s))\
|(?<!\w)(socket(?=\s))\
|(?<!\w)(bind(?=\s))\
|(?<!\w)(listen(?=\s))\
|(?<!\w)(connect(?=\s))\
|(?<!\w)(lseek(?=\s))\
|(?<!\w)(write(?=\s))\
|(?<!\w)(string(?=\s))\
|(?<!\w)(where(?=\s))\
|(?<!\w)(wherenot(?=\s))\
|(?<!\w)(wherefirst(?=\s))\
|(?<!\w)(_isnull(?=\s))\
|(?<!\w)(length(?=\s))\
|(?<!\w)(array_map(?=\s))\
|(?<!\w)(getlinestr(?=\s))\
|(?<!\w)(waddlineat(?=\s))\
|(?<!\w)(waddlineat_dr(?=\s))\
|(?<!\w)(waddlinear_dr(?=\s))\
|(?<!\w)(waddlinear(?=\s))\
|(?<!\w)(waddline(?=\s))\
|(?<!\w)(waddline_dr(?=\s)))+"R, 0),
%conditional
  pcre_compile ("\
(((?<!\w)if(?=\s))\
|((?<!\w)ifnot(?=\s))\
|((?<!\w)else if(?=\s))\
|((?<!\w)else$)\
|((?<!\w)\{$)\
|((?<!\{)(?<!\w)\}(?=;))\
|((?<!\w)\}$)\
|((?<!\w)while(?=\s))\
|((?<!\w)loop$)\
|((?<!\w)switch(?=\s))\
|((?<!\w)case(?=\s))\
|((?<!\w)_for(?=\s))\
|((?<!\w)for(?=\s))\
|((?<!\w)foreach(?=\s))\
|((?<!\w)forever$)\
|((?<!\w)do$)\
|((?<!\w)then$)\
|((?<=\w)--(?=;))\
|((?<=\w)\+\+(?=;))\
|((?<=\s)\?(?=\s))\
|((?<=\s):(?=\s))\
|((?<=\s)\+(?=\s))\
|((?<=\s)-(?=\s))\
|((?<=\s)\*(?=\s))\
|((?<=\s)/(?=\s))\
|((?<=\s)mod(?=\s))\
|((?<=\s)\+=(?=\s))\
|((?<=\s)!=(?=\s))\
|((?<=\s)>=(?=\s))\
|((?<=\s)<=(?=\s))\
|((?<=\s)<(?=\s))\
|((?<=\s)>(?=\s))\
|((?<=\s)==(?=\s)))+"R, 0),
%type
  pcre_compile ("\
(((?<!\w)define(?=\s))\
|(^\{$)\
|(^\}$)\
|((?<!\w)variable(?=[\s]*))\
|((?<!\w)private(?=\s))\
|((?<!\w)public(?=\s))\
|((?<!\w)static(?=\s))\
|((?<!\w)typedef struct$)\
|((?<!\w)struct(?=[\s]*))\
|((?<!\w)try(?=[\s]*))\
|((?<!\w)catch(?=\s))\
|((?<!\w)throw(?=\s))\
|((?<!\w)finally(?=\s))\
|((?<!\w)return(?=[\s;]))\
|((?<!\w)break(?=;))\
|((?<!\w)continue(?=;))\
|(NULL)\
|(__argv)\
|(__argc)\
|(SEEK_SET)\
|(SEEK_CUR)\
|(SEEK_END)\
|(_NARGS)\
|((?<!\w)stderr(?=[,\)\.]))\
|((?<!\w)stdin(?=[,\)\.]))\
|((?<!\w)stdout(?=[,\)\.]))\
|((?<!\w)stdout(?=[,\)\.]))\
|((?<=\s|\||\()S_IRGRP(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IROTH(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IRUSR(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IRWXG(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IRWXO(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IRWXU(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IWGRP(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IWOTH(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IWUSR(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IXGRP(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IXOTH(?=[,\|;\)]+))\
|((?<=\s|\||\()S_IXUSR(?=[,\|;\)]+))\
|((?<=\s|\||\()S_ISUID(?=[,\|;\)]+))\
|((?<=\s|\||\()S_ISGID(?=[,\|;\)]+))\
|((?<=\s|\||\()S_ISVTX(?=[,\|;\)]+))\
|((?<=\s|\|)O_APPEND(?=[,\|;\)]+))\
|((?<=\s|\|)O_BINARY(?=[,\|;\)]+))\
|((?<=\s|\|)O_NOCTTY(?=[,\|;\)]+))\
|((?<=\s|\|)O_RDONLY(?=[,\|;\)]+))\
|((?<=\s|\|)O_WRONLY(?=[,\|;\)]+))\
|((?<=\s|\|)O_CREAT(?=[,\|;\)]+))\
|((?<=\s|\|)O_EXCL(?=[,\|;\)]+))\
|((?<=\s|\|)O_RDWR(?=[,\|;\)]+))\
|((?<=\s|\|)O_TEXT(?=[,\|;\)]+))\
|((?<=\s|\|)O_TRUNC(?=[,\|;\)]+))\
|((?<=\s|\|)O_NONBLOCK(?=[,\|;\)]+))\
|((?<=[\s|@])[\w]+_Type(?=[\[;\]]))\
|((?<=\()[\w]+_Type(?=,))\
|((?<!\w)[\w]+Error(?=:)))+"R, 0),
%errors
  pcre_compile ("\
((?<=\w)(\s{1,}$))+"R, 0),
%commwnts
  pcre_compile ("(^\s*%.*)"R, 0),
];

private define sl_hl_groups (lines, vlines)
{
  variable
    i,
    ii,
    col,
    subs,
    match,
    color,
    regexp,
    context;
 
  _for i (0, length (lines) - 1)
    {
    _for ii (0, length (regexps) - 1)
      {
      color = colors[ii];
      regexp = regexps[ii];
      col = 0;

      while (subs = pcre_exec (regexp, lines[i], col), subs > 1)
        {
        match = pcre_nth_match (regexp, 1);
        col = match[0];
        context = match[1] - col;
        smg->hlregion (color, vlines[i], col, 1, context);
        col += context;
        }
      }
    }
}

define sl_lexicalhl (s, lines, vlines)
{
  sl_hl_groups (lines, vlines);
}
